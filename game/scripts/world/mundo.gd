class_name Mundo
extends Node2D
## Monta o mapa a partir dos dados (content/mapas), desenha a plantação e cuida da luz do dia.

const TAM := 16
const TEXTURA_TILES := preload("res://assets/sprites/placeholder/tiles.png")
const TEXTURA_PLANTACAO := preload("res://assets/sprites/placeholder/plantacao.png")
const FONTE_CHAO := 0
const FONTE_PLANTACAO := 1

var mapa: MapData
var chao: TileMapLayer
var solo: TileMapLayer
var plantas: TileMapLayer
var jogador: Jogador
var luz: CanvasModulate
var cursor: Cursor
var irrigadas := {}   # "x,y" -> true: células regadas pelo lago


func montar(id_mapa: String) -> void:
	mapa = Config.mapa(id_mapa)
	var ts := _criar_tileset(Config.tiles)
	chao = _camada("Chao", ts)
	solo = _camada("Solo", ts)
	plantas = _camada("Plantas", ts)
	for y in mapa.altura:
		for x in mapa.largura:
			var tipo := mapa.tipo_em(Vector2i(x, y))
			var def: Dictionary = Config.tiles.get(tipo, Config.tiles.get("grama", {"atlas": 0}))
			chao.set_cell(Vector2i(x, y), FONTE_CHAO, Vector2i(int(def.get("atlas", 0)), 0))
	irrigadas = mapa.celulas_irrigadas(int(Config.balanceamento.get("distancia_irrigacao_lago", 4)), Config.tiles)
	cursor = Cursor.new()
	add_child(cursor)
	jogador = Jogador.new()
	jogador.name = "Jogador"
	jogador.mundo = self
	add_child(jogador)
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = mapa.largura * TAM
	cam.limit_bottom = mapa.altura * TAM
	jogador.add_child(cam)
	luz = CanvasModulate.new()
	add_child(luz)


func _camada(nome: String, ts: TileSet) -> TileMapLayer:
	var c := TileMapLayer.new()
	c.name = nome
	c.tile_set = ts
	add_child(c)
	return c


func celula_de(ponto: Vector2) -> Vector2i:
	return Vector2i(floor(ponto.x / TAM), floor(ponto.y / TAM))


## Tipo de chão sob um ponto do mundo (em pixels).
func tipo_em(ponto: Vector2) -> String:
	return mapa.tipo_em(celula_de(ponto))


func eh_agua(ponto: Vector2) -> bool:
	return eh_agua_celula(celula_de(ponto))


func eh_agua_celula(c: Vector2i) -> bool:
	return bool(Config.tiles.get(mapa.tipo_em(c), {}).get("agua", false))


func atualizar_luz(hora: float) -> void:
	luz.color = Survival.cor_do_ceu(hora)


## Redesenha solo arado (seco ou molhado) e plantas a partir do estado do jogo.
func desenhar_plantacao(dados: GameData) -> void:
	solo.clear()
	plantas.clear()
	var t := Fazenda.agora(dados)
	var cs := Fazenda.canteiros(dados, mapa.id)
	for k in cs:
		var c := Fazenda.celula_da_chave(k)
		var cant: Dictionary = cs[k]
		var molhado := Fazenda.molhado(cant, t, irrigadas.has(k))
		solo.set_cell(c, FONTE_PLANTACAO, Vector2i(1 if molhado else 0, 0))
		var est := Fazenda.estagio(cant, Config.culturas)
		if est >= 0:
			var linha := int(Config.culturas[str(cant["cultura"])].get("linha", 1))
			plantas.set_cell(c, FONTE_PLANTACAO, Vector2i(est, linha))


static func _criar_tileset(defs: Dictionary) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TAM, TAM)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = TEXTURA_TILES
	src.texture_region_size = Vector2i(TAM, TAM)
	for i in TEXTURA_TILES.get_width() / TAM:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, FONTE_CHAO)
	var meio := TAM / 2.0
	var quadrado := PackedVector2Array([
		Vector2(-meio, -meio), Vector2(meio, -meio), Vector2(meio, meio), Vector2(-meio, meio)])
	for tipo in defs:
		if typeof(defs[tipo]) != TYPE_DICTIONARY or not defs[tipo].get("solido", false):
			continue
		var td := src.get_tile_data(Vector2i(int(defs[tipo]["atlas"]), 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, quadrado)
	var plant := TileSetAtlasSource.new()
	plant.texture = TEXTURA_PLANTACAO
	plant.texture_region_size = Vector2i(TAM, TAM)
	for y in TEXTURA_PLANTACAO.get_height() / TAM:
		for x in TEXTURA_PLANTACAO.get_width() / TAM:
			plant.create_tile(Vector2i(x, y))
	ts.add_source(plant, FONTE_PLANTACAO)
	return ts
