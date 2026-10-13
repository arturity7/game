class_name Mundo
extends Node2D
## Monta o mapa a partir dos dados (content/mapas): chão em grade dupla (bordas arredondadas),
## objetos com profundidade (quem está mais embaixo fica na frente), plantação e luz do dia.
##
## Grade dupla: cada camada de terreno fica deslocada meio tile; cada tile de exibição olha as
## 4 células do mundo nos seus cantos e escolhe o desenho pela máscara TL=1, TR=2, BL=4, BR=8
## (a mesma do gerador ferramentas/arte/pixel.py). Colunas 16+ do atlas = variações do tile cheio.

const TAM := 16
const MARGEM := 4           # células de mata desenhadas fora do mapa, só de enfeite
const SPRITES := "res://assets/sprites/"
const TEX_GRAMA := preload("res://assets/sprites/terreno/grama.png")
const TEX_ARADO := preload("res://assets/sprites/terreno/arado.png")
const TEX_MOLHADO := preload("res://assets/sprites/terreno/molhado.png")
const TEX_CULTURAS := preload("res://assets/sprites/plantacao/culturas.png")

var mapa: MapData
var grama: TileMapLayer
var terrenos := {}          # tipo de chão -> TileMapLayer em grade dupla
var arado: TileMapLayer
var molhado: TileMapLayer
var profundidade: Node2D    # nós ordenados pela altura na tela: objetos, plantas e jogador
var plantas := {}           # "x,y" -> Sprite2D
var jogador: Jogador
var luz: CanvasModulate
var cursor: Cursor
var irrigadas := {}         # "x,y" -> true: células regadas pelo lago
var _canteiros_desenhados := {}


func montar(id_mapa: String) -> void:
	mapa = Config.mapa(id_mapa)
	grama = _camada(TEX_GRAMA, 1, Vector2.ZERO, "Grama")
	var n_grama := TEX_GRAMA.get_width() / TAM
	for y in range(-MARGEM - 1, mapa.altura + MARGEM):
		for x in range(-MARGEM, mapa.largura + MARGEM):
			grama.set_cell(Vector2i(x, y), 0, Vector2i(_variante_grama(x, y, n_grama), 0))
	for tipo in _terrenos_em_ordem():
		var def: Dictionary = Config.tiles[tipo]
		var tex: Texture2D = load(SPRITES + "terreno/" + str(def["terreno"]))
		var camada := _camada(tex, int(def.get("quadros", 1)), Vector2(-TAM / 2.0, -TAM / 2.0), "Terreno_" + tipo)
		terrenos[tipo] = camada
		var pred := func(c: Vector2i) -> bool: return mapa.chao_em(c) == tipo
		for dy in mapa.altura + 1:
			for dx in mapa.largura + 1:
				_pintar_dupla(camada, Vector2i(dx, dy), pred)
	arado = _camada(TEX_ARADO, 1, Vector2(-TAM / 2.0, -TAM / 2.0), "Arado")
	molhado = _camada(TEX_MOLHADO, 1, Vector2(-TAM / 2.0, -TAM / 2.0), "Molhado")
	irrigadas = mapa.celulas_irrigadas(int(Config.balanceamento.get("distancia_irrigacao_lago", 4)), Config.tiles)
	cursor = Cursor.new()
	add_child(cursor)
	profundidade = Node2D.new()
	profundidade.name = "Profundidade"
	profundidade.y_sort_enabled = true
	add_child(profundidade)
	_criar_objetos()
	_criar_mata_em_volta()
	jogador = Jogador.new()
	jogador.name = "Jogador"
	jogador.mundo = self
	profundidade.add_child(jogador)
	var cam := Camera2D.new()
	cam.limit_left = -20
	cam.limit_top = -36
	cam.limit_right = mapa.largura * TAM + 20
	cam.limit_bottom = mapa.altura * TAM + 12
	jogador.add_child(cam)
	luz = CanvasModulate.new()
	add_child(luz)


## Número pseudoaleatório fixo por célula (0..1): a mesma célula sempre recebe a mesma variação.
static func ruido(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 982451653) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	h = h ^ (h >> 16)
	return float(h & 0xffff) / 65535.0


## Grama: quase sempre lisa; às vezes com tufos; raramente com flores (em manchas).
func _variante_grama(x: int, y: int, n: int) -> int:
	var r := ruido(x, y, 1)
	var mancha := ruido(x / 4, y / 4, 9)
	if n >= 8 and mancha > 0.8 and r > 0.55:
		return 6 + int(ruido(x, y, 2) * 2.0)
	if r < 0.6:
		return 0
	if r < 0.85:
		return 1 + int(ruido(x, y, 3) * 2.0)
	return 3 + int(ruido(x, y, 4) * 3.0)


func _terrenos_em_ordem() -> Array:
	var r: Array = []
	for tipo in Config.tiles:
		if typeof(Config.tiles[tipo]) == TYPE_DICTIONARY and Config.tiles[tipo].has("terreno"):
			r.append(tipo)
	r.sort_custom(func(a, b): return int(Config.tiles[a].get("ordem", 0)) < int(Config.tiles[b].get("ordem", 0)))
	return r


## Cria uma camada de tiles com um atlas de uma linha (mais linhas = quadros de animação).
func _camada(tex: Texture2D, quadros: int, deslocamento: Vector2, nome: String) -> TileMapLayer:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TAM, TAM)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TAM, TAM)
	for i in tex.get_width() / TAM:
		var c := Vector2i(i, 0)
		src.create_tile(c)
		if quadros > 1:
			src.set_tile_animation_columns(c, 1)
			src.set_tile_animation_frames_count(c, quadros)
			for q in quadros:
				src.set_tile_animation_frame_duration(c, q, 0.28)
	ts.add_source(src, 0)
	var camada := TileMapLayer.new()
	camada.name = nome
	camada.tile_set = ts
	camada.position = deslocamento
	add_child(camada)
	return camada


## Escolhe o tile de exibição (dx, dy) da camada em grade dupla a partir das 4 células vizinhas.
func _pintar_dupla(camada: TileMapLayer, d: Vector2i, pred: Callable) -> void:
	var m := 0
	if pred.call(d + Vector2i(-1, -1)):
		m |= 1
	if pred.call(d + Vector2i(0, -1)):
		m |= 2
	if pred.call(d + Vector2i(-1, 0)):
		m |= 4
	if pred.call(d):
		m |= 8
	if m == 0:
		camada.erase_cell(d)
		return
	var col := m
	var src := camada.tile_set.get_source(0) as TileSetAtlasSource
	var variantes: int = src.texture.get_width() / TAM - 16
	if m == 15 and variantes > 0 and ruido(d.x, d.y, 77) > 0.55:
		col = 16 + int(ruido(d.x, d.y, 78) * variantes) % variantes
	camada.set_cell(d, 0, Vector2i(col, 0))


# ---------- objetos ----------

func _criar_objetos() -> void:
	for o in mapa.objetos:
		var def: Dictionary = Config.objetos.get(o["tipo"], {})
		var x := int(o["x"])
		var y := int(o["y"])
		var peg: Array = def.get("pegada", [1, 1])
		var base := Vector2((x + float(peg[0]) / 2.0) * TAM, (y + int(peg[1])) * TAM)
		var corpo := StaticBody2D.new()
		corpo.name = "%s_%d_%d" % [o["tipo"], x, y]
		corpo.position = base
		var spr := Sprite2D.new()
		spr.centered = false
		if def.has("cerca"):
			spr.texture = load(SPRITES + "objetos/" + str(def["cerca"]))
			spr.region_enabled = true
			spr.region_rect = Rect2(_mascara_cerca(Vector2i(x, y)) * TAM, 0, TAM, TAM * 2)
			spr.offset = Vector2(-TAM / 2.0, -TAM * 2.0)
		else:
			var lista: Array = def.get("sprites", [])
			if lista.is_empty():
				continue
			var tex: Texture2D = load(SPRITES + "objetos/" + str(lista[int(ruido(x, y, 5) * lista.size()) % lista.size()]))
			var aj: Array = def.get("ajuste", [0, 0])
			spr.texture = tex
			spr.offset = Vector2(-tex.get_width() / 2.0 + float(aj[0]), -tex.get_height() + float(aj[1]))
		corpo.add_child(spr)
		var tam: Array = def.get("colisao", [int(peg[0]) * TAM, int(peg[1]) * TAM])
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = Vector2(float(tam[0]), float(tam[1]))
		forma.shape = ret
		forma.position = Vector2(0, -float(tam[1]) / 2.0)
		corpo.add_child(forma)
		profundidade.add_child(corpo)


## Mata fechada fora do mapa (só desenho): esconde a borda e deixa ver a copa das árvores da beira.
func _criar_mata_em_volta() -> void:
	var def: Dictionary = Config.objetos.get("arvore", {})
	var lista: Array = def.get("sprites", [])
	if lista.is_empty():
		return
	var texs: Array = []
	for s in lista:
		texs.append(load(SPRITES + "objetos/" + str(s)))
	var aj: Array = def.get("ajuste", [0, 0])
	for y in range(-MARGEM - 1, mapa.altura + MARGEM):
		for x in range(-MARGEM, mapa.largura + MARGEM):
			if x >= 0 and y >= 0 and x < mapa.largura and y < mapa.altura:
				continue
			var tex: Texture2D = texs[int(ruido(x, y, 5) * texs.size()) % texs.size()]
			var spr := Sprite2D.new()
			spr.texture = tex
			spr.centered = false
			spr.position = Vector2(x * TAM + TAM / 2.0 + (ruido(x, y, 6) - 0.5) * 6.0, (y + 1) * TAM)
			spr.offset = Vector2(-tex.get_width() / 2.0 + float(aj[0]), -tex.get_height() + float(aj[1]))
			profundidade.add_child(spr)


## Cerca liga com as vizinhas: N=1, L=2, S=4, O=8 (ordem das colunas em cerca.png).
func _mascara_cerca(c: Vector2i) -> int:
	var m := 0
	for par in [[Vector2i(0, -1), 1], [Vector2i(1, 0), 2], [Vector2i(0, 1), 4], [Vector2i(-1, 0), 8]]:
		if mapa.tipo_em(c + par[0]) == "cerca":
			m |= int(par[1])
	return m


func celula_de(ponto: Vector2) -> Vector2i:
	return Vector2i(floor(ponto.x / TAM), floor(ponto.y / TAM))


## O que há sob um ponto do mundo (em pixels): objeto ou tipo de chão.
func tipo_em(ponto: Vector2) -> String:
	return mapa.tipo_em(celula_de(ponto))


func eh_agua(ponto: Vector2) -> bool:
	return eh_agua_celula(celula_de(ponto))


func eh_agua_celula(c: Vector2i) -> bool:
	return bool(Config.tiles.get(mapa.chao_em(c), {}).get("agua", false))


## Célula onde o jogador não pode ficar (objeto sólido ou fora do mapa).
func bloqueada(c: Vector2i) -> bool:
	return mapa.ocupada(c) or mapa.chao_em(c) == ""


func atualizar_luz(hora: float) -> void:
	luz.color = Survival.cor_do_ceu(hora)


## Redesenha solo arado (seco ou molhado) e plantas a partir do estado do jogo.
func desenhar_plantacao(dados: GameData) -> void:
	var t := Fazenda.agora(dados)
	var cs := Fazenda.canteiros(dados, mapa.id)
	var estado := {}   # "x,y" -> molhado?
	for k in cs:
		estado[k] = Fazenda.molhado(cs[k], t, irrigadas.has(k))
	if estado != _canteiros_desenhados:
		var tocadas := {}
		for k in estado.keys() + _canteiros_desenhados.keys():
			var c := Fazenda.celula_da_chave(k)
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				tocadas[c + d] = true
		var e_arado := func(c: Vector2i) -> bool: return estado.has(Fazenda.chave(c))
		var e_molhado := func(c: Vector2i) -> bool: return bool(estado.get(Fazenda.chave(c), false))
		for d in tocadas:
			_pintar_dupla(arado, d, e_arado)
			_pintar_dupla(molhado, d, e_molhado)
		_canteiros_desenhados = estado
	var vistas := {}
	for k in cs:
		var cant: Dictionary = cs[k]
		var est := Fazenda.estagio(cant, Config.culturas)
		if est < 0:
			continue
		vistas[k] = true
		var spr: Sprite2D = plantas.get(k)
		if spr == null:
			var c := Fazenda.celula_da_chave(k)
			spr = Sprite2D.new()
			spr.texture = TEX_CULTURAS
			spr.centered = false
			spr.region_enabled = true
			spr.position = Vector2(c.x * TAM + TAM / 2.0, c.y * TAM + 11)
			spr.offset = Vector2(-TAM / 2.0, -27)
			profundidade.add_child(spr)
			plantas[k] = spr
		var linha := int(Config.culturas[str(cant["cultura"])].get("linha", 1))
		spr.region_rect = Rect2(est * TAM, linha * TAM * 2, TAM, TAM * 2)
	for k in plantas.keys():
		if not vistas.has(k):
			plantas[k].queue_free()
			plantas.erase(k)
