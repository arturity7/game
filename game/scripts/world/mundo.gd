class_name Mundo
extends Node2D
## Monta o mapa a partir dos dados (content/mapas) e cuida da câmera e da luz do dia.

const TAM := 16
const TEXTURA_TILES := preload("res://assets/sprites/placeholder/tiles.png")

var mapa: MapData
var chao: TileMapLayer
var jogador: Jogador
var luz: CanvasModulate


func montar(id_mapa: String) -> void:
	mapa = Config.mapa(id_mapa)
	chao = TileMapLayer.new()
	chao.name = "Chao"
	chao.tile_set = _criar_tileset(Config.tiles)
	add_child(chao)
	for y in mapa.altura:
		for x in mapa.largura:
			var tipo := mapa.tipo_em(Vector2i(x, y))
			var def: Dictionary = Config.tiles.get(tipo, Config.tiles.get("grama", {"atlas": 0}))
			chao.set_cell(Vector2i(x, y), 0, Vector2i(int(def.get("atlas", 0)), 0))
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


## Tipo de chão sob um ponto do mundo (em pixels).
func tipo_em(ponto: Vector2) -> String:
	return mapa.tipo_em(Vector2i(floor(ponto.x / TAM), floor(ponto.y / TAM)))


func eh_agua(ponto: Vector2) -> bool:
	return bool(Config.tiles.get(tipo_em(ponto), {}).get("agua", false))


func atualizar_luz(hora: float) -> void:
	luz.color = Survival.cor_do_ceu(hora)


static func _criar_tileset(defs: Dictionary) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TAM, TAM)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = TEXTURA_TILES
	src.texture_region_size = Vector2i(TAM, TAM)
	var colunas := TEXTURA_TILES.get_width() / TAM
	for i in colunas:
		src.create_tile(Vector2i(i, 0))
	ts.add_source(src, 0)
	var meio := TAM / 2.0
	var quadrado := PackedVector2Array([
		Vector2(-meio, -meio), Vector2(meio, -meio), Vector2(meio, meio), Vector2(-meio, meio)])
	for tipo in defs:
		if typeof(defs[tipo]) != TYPE_DICTIONARY or not defs[tipo].get("solido", false):
			continue
		var td := src.get_tile_data(Vector2i(int(defs[tipo]["atlas"]), 0), 0)
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, quadrado)
	return ts
