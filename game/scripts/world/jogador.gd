class_name Jogador
extends CharacterBody2D
## O protagonista: anda com WASD; na água, nada mais devagar (D-070).
## A posição do nó fica nos pés (é por ela que o mundo decide quem fica na frente).

const TEXTURA := preload("res://assets/sprites/personagens/jogador.png")
const ONDAS := preload("res://assets/sprites/personagens/ondas.png")
const LINHAS := {"baixo": 0, "cima": 1, "esquerda": 2, "direita": 3}
const QUADROS_POR_SEGUNDO := 8.0

var mundo: Mundo
var sprite: Sprite2D
var ondas: Sprite2D
var nadando := false
var andando := false
var parado := false      # true enquanto dorme
var direcao := Vector2i(0, 1)
var _lado := "baixo"
var _tempo_passo := 0.0


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TEXTURA
	sprite.centered = false
	sprite.region_enabled = true
	add_child(sprite)
	ondas = Sprite2D.new()
	ondas.texture = ONDAS
	ondas.region_enabled = true
	ondas.position = Vector2(0, -4)
	ondas.visible = false
	add_child(ondas)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(10, 6)
	forma.shape = ret
	forma.position = Vector2(0, -2)
	add_child(forma)
	_atualizar_quadro()


func _physics_process(delta: float) -> void:
	var dir := Vector2.ZERO if parado else Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	nadando = mundo != null and mundo.eh_agua(global_position)
	var cfg: Dictionary = Config.balanceamento
	var vel := float(cfg.get("velocidade_nadar" if nadando else "velocidade_andar", 80.0))
	velocity = dir * vel
	andando = dir != Vector2.ZERO
	if andando:
		_virar(dir)
		var antes := int(_tempo_passo * QUADROS_POR_SEGUNDO)
		_tempo_passo += delta
		var agora := int(_tempo_passo * QUADROS_POR_SEGUNDO)
		if agora != antes and agora % 2 == 1 and not nadando:
			Som.tocar("passo_%d" % ((agora / 2) % 2), -8.0)
	else:
		_tempo_passo = 0.0
	move_and_slide()
	_atualizar_quadro()


func _virar(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		_lado = "direita" if dir.x > 0 else "esquerda"
	else:
		_lado = "baixo" if dir.y > 0 else "cima"
	direcao = {"baixo": Vector2i(0, 1), "cima": Vector2i(0, -1), "esquerda": Vector2i(-1, 0), "direita": Vector2i(1, 0)}[_lado]


## Quadro da animação: parado, passo, parado, passo. Nadando, só o tronco aparece, com ondinhas.
func _atualizar_quadro() -> void:
	var q := 0
	if andando:
		q = int(_tempo_passo * QUADROS_POR_SEGUNDO) % 4
	var y: int = int(LINHAS[_lado]) * 32
	if nadando:
		sprite.region_rect = Rect2(q * 16, y, 16, 23)
		sprite.offset = Vector2(-8, -26)
		ondas.visible = true
		ondas.region_rect = Rect2((int(Time.get_ticks_msec() / 400) % 2) * 20, 0, 20, 8)
	else:
		sprite.region_rect = Rect2(q * 16, y, 16, 32)
		sprite.offset = Vector2(-8, -30)
		ondas.visible = false
