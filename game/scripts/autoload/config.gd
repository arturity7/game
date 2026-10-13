extends Node
## Carrega os arquivos de configuração e de conteúdo (dados, não código; tecnico.md §2).

var balanceamento := {}
var tiles := {}
var itens := {}
var culturas := {}
var objetos := {}
var lojas := {}


func _ready() -> void:
	balanceamento = ler_json("res://content/config/balanceamento.json")
	tiles = _sem_comentarios(ler_json("res://content/config/tiles.json"))
	itens = _sem_comentarios(ler_json("res://content/config/itens.json"))
	culturas = _sem_comentarios(ler_json("res://content/config/culturas.json"))
	objetos = _sem_comentarios(ler_json("res://content/config/objetos.json"))
	lojas = _sem_comentarios(ler_json("res://content/config/lojas.json"))


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


## Tira as chaves que começam com "_" (comentários nos JSON).
static func _sem_comentarios(d: Dictionary) -> Dictionary:
	var r := {}
	for k in d:
		if not str(k).begins_with("_"):
			r[k] = d[k]
	return r


func mapa(id: String) -> MapData:
	return MapData.de_dict(ler_json("res://content/mapas/%s.json" % id), objetos)
