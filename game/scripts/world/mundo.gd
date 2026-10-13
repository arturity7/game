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
var enfeites := {}          # "x,y" -> Sprite2D (mato, flores...; não bloqueiam)
var jogador: Jogador
var luz: CanvasModulate
var cursor: Cursor
var irrigadas := {}         # "x,y" -> true: células regadas pelo lago
var _canteiros_desenhados := {}
var _npcs := {}             # id -> [StaticBody2D, dados do mapa]
var luzes: Array = []       # luzes (PointLight2D) e janelas acesas (Sprite2D) que aparecem à noite
var _textura_luz: Texture2D
var ambiente: Ambiente      # borboletas, folhas e vaga-lumes (só ao ar livre)
var paredoes := {}          # Vector2i -> linha do paredão (0 = de cima): células abaixo da beira de um morro
var _copas := PackedVector2Array()


func montar(id_mapa: String) -> void:
	mapa = Config.mapa(id_mapa)
	if mapa.fundo != "":
		var fundo := Sprite2D.new()
		fundo.name = "Fundo"
		fundo.texture = load(SPRITES + "interiores/" + mapa.fundo)
		fundo.centered = false
		add_child(fundo)
		if mapa.noite != "":
			var escuro := Sprite2D.new()
			escuro.name = "FundoNoite"
			escuro.texture = load(SPRITES + "interiores/" + mapa.noite)
			escuro.centered = false
			escuro.modulate.a = 0.0
			add_child(escuro)
			luzes.append(escuro)
		for p in mapa.luzes:
			var vela := PointLight2D.new()
			vela.texture = _luz()
			vela.color = Color(1.0, 0.72, 0.38)
			vela.texture_scale = 1.6
			vela.position = p
			vela.energy = 0.0
			add_child(vela)
			luzes.append(vela)
	else:
		_achar_paredoes()
		_montar_chao()
	arado = _camada(TEX_ARADO, 1, Vector2(-TAM / 2.0, -TAM / 2.0), "Arado")
	molhado = _camada(TEX_MOLHADO, 1, Vector2(-TAM / 2.0, -TAM / 2.0), "Molhado")
	irrigadas = mapa.celulas_irrigadas(int(Config.balanceamento.get("distancia_irrigacao_lago", 4)), Config.tiles)
	cursor = Cursor.new()
	add_child(cursor)
	profundidade = Node2D.new()
	profundidade.name = "Profundidade"
	profundidade.y_sort_enabled = true
	add_child(profundidade)
	_criar_paredes()
	_criar_objetos()
	_criar_npcs()
	atualizar_npcs()
	if not mapa.interior:
		_criar_enfeites()
		_criar_mata_em_volta()
		ambiente = Ambiente.new()
		ambiente.name = "Ambiente"
		ambiente.arvores = _copas
		add_child(ambiente)
	jogador = Jogador.new()
	jogador.name = "Jogador"
	jogador.mundo = self
	profundidade.add_child(jogador)
	var cam := Camera2D.new()
	var tela := Vector2(480, 270)
	var w := mapa.largura * TAM
	var h := mapa.altura * TAM
	if mapa.interior:
		# cômodo pequeno: câmera parada, cômodo no meio da tela
		cam.limit_left = int((w - tela.x) / 2.0)
		cam.limit_right = cam.limit_left + int(tela.x)
		cam.limit_top = int((h - tela.y) / 2.0)
		cam.limit_bottom = cam.limit_top + int(tela.y)
	else:
		cam.limit_left = -20
		cam.limit_top = -36
		cam.limit_right = w + 20
		cam.limit_bottom = h + 12
	jogador.add_child(cam)
	luz = CanvasModulate.new()
	add_child(luz)


## Chão ao ar livre: grama de base e os terrenos em grade dupla por cima.
func _montar_chao() -> void:
	grama = _camada(TEX_GRAMA, 1, Vector2.ZERO, "Grama")
	var n_grama := TEX_GRAMA.get_width() / TAM
	for y in range(-MARGEM - 1, mapa.altura + MARGEM):
		for x in range(-MARGEM, mapa.largura + MARGEM):
			grama.set_cell(Vector2i(x, y), 0, Vector2i(_variante_grama(x, y, n_grama), 0))
	# manchas de grama mais escura/clara (só desenho), em formas grandes e suaves
	for m in Config.tiles.get("grama", {}).get("manchas", []):
		var tex_m: Texture2D = load(SPRITES + "terreno/" + str(m["terreno"]))
		var camada_m := _camada(tex_m, 1, Vector2(-TAM / 2.0, -TAM / 2.0), "Mancha_" + str(m["terreno"]).get_basename())
		var esc := float(m.get("escala", 7.0))
		var sem := int(m.get("semente", 1))
		var lim := float(m.get("limiar", 0.65))
		var abaixo := bool(m.get("abaixo", false))
		var pred_m := func(c: Vector2i) -> bool: return (ruido_suave(c.x, c.y, esc, sem) < lim) if abaixo else (ruido_suave(c.x, c.y, esc, sem) > lim)
		for dy in range(-MARGEM - 1, mapa.altura + MARGEM + 1):
			for dx in range(-MARGEM, mapa.largura + MARGEM + 1):
				_pintar_dupla(camada_m, Vector2i(dx, dy), pred_m)
	# tipos com desenho simples de uma célula (trilhos etc.)
	for tipo in Config.tiles:
		if typeof(Config.tiles[tipo]) != TYPE_DICTIONARY or not Config.tiles[tipo].has("tile"):
			continue
		var tex_s: Texture2D = load(SPRITES + "terreno/" + str(Config.tiles[tipo]["tile"]))
		var simples := _camada(tex_s, 1, Vector2.ZERO, "Tile_" + tipo)
		for y in mapa.altura:
			for x in mapa.largura:
				if mapa.chao_em(Vector2i(x, y)) == tipo:
					simples.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	for tipo in _terrenos_em_ordem():
		var def: Dictionary = Config.tiles[tipo]
		var tex: Texture2D = load(SPRITES + "terreno/" + str(def["terreno"]))
		var camada := _camada(tex, int(def.get("quadros", 1)), Vector2(-TAM / 2.0, -TAM / 2.0), "Terreno_" + tipo)
		terrenos[tipo] = camada
		var pred := func(c: Vector2i) -> bool: return mapa.chao_em(c) == tipo
		for dy in mapa.altura + 1:
			for dx in mapa.largura + 1:
				_pintar_dupla(camada, Vector2i(dx, dy), pred)
	_desenhar_paredoes()


## Paredão de pedra abaixo da beira de baixo de cada morro (tiles.json: "paredao" e "altura_paredao").
func _achar_paredoes() -> void:
	for tipo in Config.tiles:
		var def = Config.tiles[tipo]
		if typeof(def) != TYPE_DICTIONARY or not def.has("paredao"):
			continue
		var alt := int(def.get("altura_paredao", 2))
		for y in mapa.altura:
			for x in mapa.largura:
				var c := Vector2i(x, y)
				if mapa.chao_em(c) != tipo or mapa.chao_em(c + Vector2i(0, 1)) == tipo:
					continue
				for k in alt:
					var b := c + Vector2i(0, k + 1)
					if b.y >= mapa.altura or mapa.chao_em(b) == tipo:
						break
					paredoes[b] = k


func _desenhar_paredoes() -> void:
	if paredoes.is_empty():
		return
	var tex: Texture2D = null
	for tipo in Config.tiles:
		var def = Config.tiles[tipo]
		if typeof(def) == TYPE_DICTIONARY and def.has("paredao"):
			tex = load(SPRITES + "terreno/" + str(def["paredao"]))
			break
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TAM, TAM)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TAM, TAM)
	for i in tex.get_width() / TAM:
		for j in tex.get_height() / TAM:
			src.create_tile(Vector2i(i, j))
	ts.add_source(src, 0)
	var camada := TileMapLayer.new()
	camada.name = "Paredao"
	camada.tile_set = ts
	add_child(camada)
	var linhas := tex.get_height() / TAM
	for c in paredoes:
		var k: int = paredoes[c]
		var esq: bool = paredoes.get(c + Vector2i(-1, 0), -1) == k
		var dir: bool = paredoes.get(c + Vector2i(1, 0), -1) == k
		var col := 2
		if not esq and not dir:
			col = 0
		elif not esq:
			col = 1
		elif not dir:
			col = 3
		else:
			col = [2, 4, 5][int(ruido(c.x, c.y - k, 91) * 3.0) % 3]
		camada.set_cell(c, 0, Vector2i(col, mini(k, linhas - 1)))


## Número pseudoaleatório fixo por célula (0..1): a mesma célula sempre recebe a mesma variação.
static func ruido(x: int, y: int, s: int) -> float:
	var h := (x * 374761393 + y * 668265263 + s * 982451653) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	h = h ^ (h >> 16)
	return float(h & 0xffff) / 65535.0


## Ruído suave (0..1) em duas oitavas: manchas grandes e arredondadas que mudam devagar no mapa.
static func ruido_suave(x: int, y: int, escala: float, s: int) -> float:
	return 0.65 * _valor(x / escala, y / escala, s) + 0.35 * _valor(x / (escala * 0.4), y / (escala * 0.4), s + 101)


static func _valor(gx: float, gy: float, s: int) -> float:
	var x0 := floori(gx)
	var y0 := floori(gy)
	var fx := gx - x0
	var fy := gy - y0
	var sx := fx * fx * (3.0 - 2.0 * fx)
	var sy := fy * fy * (3.0 - 2.0 * fy)
	var cima := lerpf(ruido(x0, y0, s), ruido(x0 + 1, y0, s), sx)
	var baixo := lerpf(ruido(x0, y0 + 1, s), ruido(x0 + 1, y0 + 1, s), sx)
	return lerpf(cima, baixo, sy)


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

## Moradores parados (lojistas etc.): sprite olhando para um lado, com colisão nos pés.
func _criar_npcs() -> void:
	var linhas := {"baixo": 0, "cima": 1, "esquerda": 2, "direita": 3}
	for n in mapa.npcs:
		var corpo := StaticBody2D.new()
		_npcs[str(n["id"])] = [corpo, n]
		corpo.name = "NPC_" + str(n["id"])
		corpo.position = Vector2(int(n["x"]) * TAM + TAM / 2.0, int(n["y"]) * TAM + TAM / 2.0 + 6)
		var spr := Sprite2D.new()
		spr.texture = load(SPRITES + "personagens/" + str(n["sprite"]))
		spr.centered = false
		spr.region_enabled = true
		spr.region_rect = Rect2(0, int(linhas.get(n["olhar"], 0)) * 32, 16, 32)
		spr.offset = Vector2(-8, -30)
		corpo.add_child(spr)
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = Vector2(12, 8)
		forma.shape = ret
		forma.position = Vector2(0, -3)
		corpo.add_child(forma)
		profundidade.add_child(corpo)


## O morador só aparece se a condição "se" dele valer (ex.: some depois do fim da história).
func npc_visivel(n: Dictionary) -> bool:
	return GameState.dados == null or Dialogo.condicao(GameState.dados, n.get("se", {}))


## Mostra ou esconde os moradores conforme o avanço (chamado ao montar e depois de cada conversa).
func atualizar_npcs() -> void:
	for id in _npcs:
		var corpo: StaticBody2D = _npcs[id][0]
		var vis := npc_visivel(_npcs[id][1])
		corpo.visible = vis
		corpo.collision_layer = 1 if vis else 0


## Chão sólido (paredes dos interiores): um bloqueio por trecho de células seguidas na linha.
func _criar_paredes() -> void:
	var corpo := StaticBody2D.new()
	corpo.name = "Paredes"
	for y in mapa.altura:
		var x := 0
		while x < mapa.largura:
			if not bool(Config.tiles.get(mapa.chao_em(Vector2i(x, y)), {}).get("solido", false)):
				x += 1
				continue
			var x0 := x
			while x < mapa.largura and bool(Config.tiles.get(mapa.chao_em(Vector2i(x, y)), {}).get("solido", false)):
				x += 1
			var forma := CollisionShape2D.new()
			var ret := RectangleShape2D.new()
			ret.size = Vector2((x - x0) * TAM, TAM)
			forma.shape = ret
			forma.position = Vector2((x0 + x) * TAM / 2.0, y * TAM + TAM / 2.0)
			corpo.add_child(forma)
	for c in paredoes:
		var forma := CollisionShape2D.new()
		var ret := RectangleShape2D.new()
		ret.size = Vector2(TAM, TAM)
		forma.shape = ret
		forma.position = Vector2(c) * TAM + Vector2(TAM / 2.0, TAM / 2.0)
		corpo.add_child(forma)
	add_child(corpo)


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
		elif def.has("quadros"):
			var quadros := SpriteFrames.new()
			quadros.set_animation_speed("default", 5.0)
			for q in def["quadros"]:
				quadros.add_frame("default", load(SPRITES + "objetos/" + str(q)))
			var anim := AnimatedSprite2D.new()
			anim.sprite_frames = quadros
			anim.centered = false
			var t0: Texture2D = quadros.get_frame_texture("default", 0)
			var aj0: Array = def.get("ajuste", [0, 0])
			anim.offset = Vector2(-t0.get_width() / 2.0 + float(aj0[0]), -t0.get_height() + float(aj0[1]))
			anim.play()
			spr.free()
			spr = null
			corpo.add_child(anim)
		else:
			var lista: Array = def.get("sprites", [])
			if lista.is_empty():
				continue
			var tex: Texture2D = load(SPRITES + "objetos/" + str(lista[int(ruido(x, y, 5) * lista.size()) % lista.size()]))
			var aj: Array = def.get("ajuste", [0, 0])
			spr.texture = tex
			spr.offset = Vector2(-tex.get_width() / 2.0 + float(aj[0]), -tex.get_height() + float(aj[1]))
			if bool(def.get("folhas", false)):
				_copas.append(base + Vector2(0, -tex.get_height() * 0.62))
		if spr != null:
			corpo.add_child(spr)
		if def.has("noite") and spr != null:
			var acesas := Sprite2D.new()
			acesas.texture = load(SPRITES + "objetos/" + str(def["noite"]))
			acesas.centered = false
			acesas.offset = spr.offset
			acesas.modulate.a = 0.0
			corpo.add_child(acesas)
			luzes.append(acesas)
		for l in def.get("luzes", []):
			if spr == null:
				break
			var luz_janela := PointLight2D.new()
			luz_janela.texture = _luz()
			luz_janela.color = Color(1.0, 0.78, 0.42)
			luz_janela.energy = 0.0
			luz_janela.texture_scale = 1.0
			luz_janela.position = spr.offset + Vector2(float(l[0]), float(l[1]))
			corpo.add_child(luz_janela)
			luzes.append(luz_janela)
		if def.has("porta"):
			_colisao_com_porta(corpo, peg, def["porta"])
		elif not bool(def.get("solido", true)):
			pass
		else:
			var tam: Array = def.get("colisao", [int(peg[0]) * TAM, int(peg[1]) * TAM])
			var forma := CollisionShape2D.new()
			var ret := RectangleShape2D.new()
			ret.size = Vector2(float(tam[0]), float(tam[1]))
			forma.shape = ret
			forma.position = Vector2(0, -float(tam[1]) / 2.0)
			corpo.add_child(forma)
		profundidade.add_child(corpo)


## Pegada inteira sólida, menos a célula da porta (a origem do corpo é o meio da base da pegada).
func _colisao_com_porta(corpo: Node2D, peg: Array, porta: Array) -> void:
	var w := int(peg[0])
	var h := int(peg[1])
	for y in h:
		var x := 0
		while x < w:
			if x == int(porta[0]) and y == int(porta[1]):
				x += 1
				continue
			var x0 := x
			while x < w and not (x == int(porta[0]) and y == int(porta[1])):
				x += 1
			var forma := CollisionShape2D.new()
			var ret := RectangleShape2D.new()
			ret.size = Vector2((x - x0) * TAM, TAM)
			forma.shape = ret
			forma.position = Vector2((x0 + x) * TAM / 2.0 - w * TAM / 2.0, (y - h) * TAM + TAM / 2.0)
			corpo.add_child(forma)


## Enfeites soltos na grama: só onde a célula e as 8 vizinhas são grama livre.
func _criar_enfeites() -> void:
	var def: Dictionary = Config.tiles.get("grama", {})
	var lista: Array = def.get("enfeites", [])
	var dens := float(def.get("densidade_enfeites", 0.0))
	if lista.is_empty() or dens <= 0.0:
		return
	var texs: Array = []
	for s in lista:
		texs.append(load(SPRITES + "objetos/" + str(s)))
	for y in mapa.altura:
		for x in mapa.largura:
			if ruido(x, y, 31) >= dens:
				continue
			var livre := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var c := Vector2i(x + dx, y + dy)
					if mapa.chao_em(c) != "grama" or mapa.ocupada(c) or paredoes.has(c):
						livre = false
			if not livre:
				continue
			var spr := Sprite2D.new()
			spr.texture = texs[int(ruido(x, y, 32) * texs.size()) % texs.size()]
			spr.centered = false
			spr.position = Vector2(x * TAM + 8 + roundf((ruido(x, y, 33) - 0.5) * 6.0), y * TAM + 13)
			spr.offset = Vector2(-8, -15)
			profundidade.add_child(spr)
			enfeites["%d,%d" % [x, y]] = spr


## Mato e flores balançam quando alguém passa por cima (só desenho).
func balancar_enfeite(c: Vector2i, lado: float) -> void:
	var spr: Sprite2D = enfeites.get("%d,%d" % [c.x, c.y])
	if spr == null or not spr.visible:
		return
	var nome := spr.texture.resource_path.get_file()
	if "pedrinhas" in nome or "cogumelo" in nome:
		return
	var tw := spr.create_tween()
	tw.tween_property(spr, "skew", 0.45 * lado, 0.07)
	tw.tween_property(spr, "skew", -0.25 * lado, 0.12)
	tw.tween_property(spr, "skew", 0.1 * lado, 0.12)
	tw.tween_property(spr, "skew", 0.0, 0.12)
	Som.tocar("mato", -14.0)


## Mata fechada fora do mapa (só desenho): esconde a borda e deixa ver a copa das árvores da beira.
func _criar_mata_em_volta() -> void:
	var def: Dictionary = Config.objetos.get(mapa.mata, Config.objetos.get("arvore", {}))
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
			if bool(def.get("folhas", false)) and ruido(x, y, 8) < 0.3:
				_copas.append(spr.position + Vector2(0, -tex.get_height() * 0.62))


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
	var chao := mapa.chao_em(c)
	return mapa.ocupada(c) or chao == "" or paredoes.has(c) or bool(Config.tiles.get(chao, {}).get("solido", false))


func atualizar_luz(hora: float) -> void:
	luz.color = Survival.cor_do_ceu(hora)
	if ambiente != null:
		ambiente.hora = hora
	if mapa.interior:
		# dentro de casa: claro de dia; à noite, luz quente de lampião
		var c := Survival.cor_do_ceu(hora)
		luz.color = c.lerp(Color(1.0, 0.86, 0.7), 0.6)
	# janelas: acendem entre 17h e 19h, apagam entre 5h e 7h
	var noite := 0.0
	if hora >= 19.0 or hora < 5.0:
		noite = 1.0
	elif hora >= 17.0:
		noite = (hora - 17.0) / 2.0
	elif hora < 7.0:
		noite = (7.0 - hora) / 2.0
	for l in luzes:
		if l is PointLight2D:
			l.energy = 1.1 * noite
			l.enabled = noite > 0.0
		else:
			l.modulate.a = noite


## Textura de luz redonda e suave (feita uma vez).
func _luz() -> Texture2D:
	if _textura_luz == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 72
		t.height = 72
		_textura_luz = t
	return _textura_luz


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
		for k in enfeites:
			enfeites[k].visible = not estado.has(k)
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
