extends Node
## Carrega os arquivos de configuração e de conteúdo (dados, não código; tecnico.md §2).

var balanceamento := {}
var tiles := {}
var itens := {}
var culturas := {}
var objetos := {}
var lojas := {}
var animais := {}
## Conteúdo dos livros (content/livros/<livro>/*.json), juntado de todos os livros:
var livros := {}       # id do livro -> livro.json
var dialogos := {}     # id -> conversa
var perguntas := {}    # id -> pergunta
var missoes := {}      # id -> missão (para o diário)
var conquistas := {}   # id -> conquista
var inimigos := {}     # id -> inimigo (ver scripts/world/inimigo.gd)


func _ready() -> void:
	balanceamento = ler_json("res://content/config/balanceamento.json")
	tiles = _sem_comentarios(ler_json("res://content/config/tiles.json"))
	itens = _sem_comentarios(ler_json("res://content/config/itens.json"))
	culturas = _sem_comentarios(ler_json("res://content/config/culturas.json"))
	objetos = _sem_comentarios(ler_json("res://content/config/objetos.json"))
	lojas = _sem_comentarios(ler_json("res://content/config/lojas.json"))
	animais = _sem_comentarios(ler_json("res://content/config/animais.json"))
	carregar_livros()


## Lê content/livros/<livro>/: livro, dialogos, perguntas, missoes, itens (somam aos itens básicos),
## conquistas e inimigos. Livro novo = pasta nova, sem mexer no código (conteudo-dos-livros.md §3).
func carregar_livros(pasta := "res://content/livros") -> void:
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	var nomes: Array = []
	for d in dir.get_directories():
		nomes.append(d)
	nomes.sort()
	for nome in nomes:
		var base: String = pasta.path_join(nome)
		var livro := _ler_opcional(base.path_join("livro.json"))
		if not livro.is_empty():
			livros[str(livro.get("id", nome))] = livro
		dialogos.merge(_sem_comentarios(_ler_opcional(base.path_join("dialogos.json"))))
		perguntas.merge(_sem_comentarios(_ler_opcional(base.path_join("perguntas.json"))))
		missoes.merge(_sem_comentarios(_ler_opcional(base.path_join("missoes.json"))))
		conquistas.merge(_sem_comentarios(_ler_opcional(base.path_join("conquistas.json"))))
		itens.merge(_sem_comentarios(_ler_opcional(base.path_join("itens.json"))))
		inimigos.merge(_sem_comentarios(_ler_opcional(base.path_join("inimigos.json"))))


static func _ler_opcional(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	return ler_json(caminho)


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
