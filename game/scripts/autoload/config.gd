extends Node
## Carrega os arquivos de configuração e de conteúdo (dados, não código; tecnico.md §2).

var balanceamento := {}
var tiles := {}


func _ready() -> void:
	balanceamento = ler_json("res://content/config/balanceamento.json")
	tiles = ler_json("res://content/config/tiles.json")


static func ler_json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		push_error("arquivo não encontrado: " + caminho)
		return {}
	var texto := FileAccess.get_file_as_string(caminho)
	var data = JSON.parse_string(texto)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("JSON inválido: " + caminho)
		return {}
	return data


func mapa(id: String) -> MapData:
	return MapData.de_dict(ler_json("res://content/mapas/%s.json" % id))
