class_name Animal
extends Node2D
## Um animal andando pela fazenda (desenho e passeio). As regras e o save ficam em Animais (core);
## aqui só o movimento: fica parado ou pastando um pouco, depois anda até 3 células em linha reta
## por onde animal pode passar (sem cerca, porteira, água, canteiro ou saída do mapa).
## A posição do nó fica nos pés (para a profundidade).

const LINHAS := {"baixo": 0, "cima": 1, "esquerda": 2, "direita": 3}

var registro: Dictionary      # o registro do save (Animais)
var mundo: Mundo
var def: Dictionary
var sprite: Sprite2D
var _estado := "parado"
var _tempo := 0.0
var _alvo := Vector2.ZERO
var _lado := "baixo"
var _passo := 0.0
var _comendo := false
var _rng := RandomNumberGenerator.new()
var _tam := Vector2i(16, 16)


func _ready() -> void:
	_rng.randomize()
	def = Config.animais.get(str(registro["especie"]), {})
	var q: Array = def.get("quadro", [16, 16])
	_tam = Vector2i(int(q[0]), int(q[1]))
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.region_enabled = true
	sprite.offset = Vector2(-_tam.x / 2.0, -_tam.y + 3)
	add_child(sprite)
	position = Vector2(int(registro["x"]) * 16 + 8, int(registro["y"]) * 16 + 13)
	_lado = ["baixo", "esquerda", "direita", "cima"][_rng.randi() % 4]
	_tempo = _rng.randf_range(0.2, 2.5)
	atualizar_visual()


func celula() -> Vector2i:
	return Vector2i(floori(position.x / 16.0), floori((position.y - 5) / 16.0))


## Troca a folha conforme a idade e o produto (ovelha tosquiada).
func atualizar_visual() -> void:
	var arquivo := str(def.get("folha", ""))
	if bool(registro.get("filhote", false)):
		arquivo = str(def.get("filhote", arquivo))
	else:
		var prod: Dictionary = def.get("produto", {})
		if prod.has("sem_produto") and GameState.dados != null and not Animais.produto_pronto(GameState.dados, registro, Config.animais):
			arquivo = str(prod["sem_produto"])
	sprite.texture = load("res://assets/sprites/animais/" + arquivo)
	_quadro()


func _quadro() -> void:
	var col := 0
	if _estado == "andando":
		col = int(_passo * 6.0) % 2
	elif _comendo:
		col = 2
	sprite.region_rect = Rect2(col * _tam.x, int(LINHAS[_lado]) * _tam.y, _tam.x, _tam.y)


func _process(delta: float) -> void:
	if mundo == null:
		return
	match _estado:
		"parado":
			_tempo -= delta
			if _tempo <= 0.0:
				_decidir()
		"andando":
			var vel := float(def.get("velocidade", 14.0)) * (1.3 if bool(registro.get("filhote", false)) else 1.0)
			position = position.move_toward(_alvo, vel * delta)
			_passo += delta
			if position.distance_to(_alvo) < 0.5:
				position = _alvo
				var c := celula()
				registro["x"] = c.x
				registro["y"] = c.y
				_estado = "parado"
				_comendo = _rng.randf() < 0.5
				_tempo = _rng.randf_range(1.5, 5.0)
	_quadro()


## Escolhe o próximo passo: às vezes continua parado (pastando), às vezes anda em linha reta.
func _decidir() -> void:
	if _rng.randf() < 0.3:
		_comendo = not _comendo
		_tempo = _rng.randf_range(1.0, 3.5)
		return
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var d: Vector2i = dirs[_rng.randi() % 4]
	var n := _rng.randi_range(1, 3)
	var c := celula()
	var fim := c
	for k in n:
		var p := fim + d
		if not mundo.livre_para_animal(p, self):
			break
		fim = p
	_lado = {Vector2i(1, 0): "direita", Vector2i(-1, 0): "esquerda", Vector2i(0, 1): "baixo", Vector2i(0, -1): "cima"}[d]
	_comendo = false
	if fim == c:
		_tempo = _rng.randf_range(0.8, 2.0)
		return
	_alvo = Vector2(fim.x * 16 + 8, fim.y * 16 + 13)
	registro["x"] = fim.x      # a célula de destino fica reservada
	registro["y"] = fim.y
	_estado = "andando"
	_passo = 0.0


## Para e olha para um ponto (quando o jogador mexe com ele).
func olhar(ponto: Vector2) -> void:
	var d := ponto - position
	if absf(d.x) > absf(d.y):
		_lado = "direita" if d.x > 0 else "esquerda"
	else:
		_lado = "baixo" if d.y > 0 else "cima"
	if _estado == "parado":
		_comendo = false
		_tempo = maxf(_tempo, 1.5)
	_quadro()
