class_name Jogador
extends CharacterBody2D
## O protagonista: anda com WASD; na água, nada mais devagar (D-070).

const TEXTURA := preload("res://assets/sprites/placeholder/jogador.png")
const QUADROS := {"baixo": 0, "cima": 1, "esquerda": 2, "direita": 3}

var mundo: Mundo
var sprite: Sprite2D
var nadando := false
var andando := false


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TEXTURA
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 16, 32)
	sprite.offset = Vector2(0, -12)
	add_child(sprite)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	ret.size = Vector2(10, 6)
	forma.shape = ret
	forma.position = Vector2(0, 1)
	add_child(forma)


func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
	nadando = mundo != null and mundo.eh_agua(global_position)
	var cfg: Dictionary = Config.balanceamento
	var vel := float(cfg.get("velocidade_nadar" if nadando else "velocidade_andar", 80.0))
	velocity = dir * vel
	andando = dir != Vector2.ZERO
	if andando:
		_virar(dir)
	move_and_slide()
	sprite.modulate = Color(0.75, 0.85, 1.0) if nadando else Color.WHITE


func _virar(dir: Vector2) -> void:
	var lado := "baixo"
	if absf(dir.x) > absf(dir.y):
		lado = "direita" if dir.x > 0 else "esquerda"
	else:
		lado = "baixo" if dir.y > 0 else "cima"
	sprite.region_rect = Rect2(QUADROS[lado] * 16, 0, 16, 32)
