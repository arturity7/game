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
var _acao := 0.0          # segundos restantes da pose de usar ferramenta
var _celula := Vector2i(-999, -999)


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
	_acao = maxf(0.0, _acao - delta)
	var dir := Vector2.ZERO if parado or _acao > 0.0 else Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")
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
	if mundo != null:
		var c := mundo.celula_de(global_position)
		if c != _celula:
			_celula = c
			if andando:
				mundo.balancar_enfeite(c, signf(velocity.x) if velocity.x != 0.0 else 1.0)


func _virar(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		_lado = "direita" if dir.x > 0 else "esquerda"
	else:
		_lado = "baixo" if dir.y > 0 else "cima"
	direcao = {"baixo": Vector2i(0, 1), "cima": Vector2i(0, -1), "esquerda": Vector2i(-1, 0), "direita": Vector2i(1, 0)}[_lado]


## Pose de usar ferramenta por um instante (o jogador para enquanto isso).
func acao(segundos := 0.22) -> void:
	_acao = segundos
	_atualizar_quadro()


## Vira o jogador para um lado: "baixo", "cima", "esquerda" ou "direita".
func virar_para(lado: String) -> void:
	var v := {"baixo": Vector2.DOWN, "cima": Vector2.UP, "esquerda": Vector2.LEFT, "direita": Vector2.RIGHT}
	if v.has(lado):
		_virar(v[lado])
		_atualizar_quadro()


## Vira o jogador para uma célula vizinha (ou para a direção dela).
func olhar_para(celula: Vector2i) -> void:
	var d := Vector2(celula) * 16.0 + Vector2(8, 8) - position
	if d.length() > 2.0:
		_virar(d)


## Quadro da animação: parado, passo, parado, passo; coluna 4 = usando ferramenta.
## Nadando, só o tronco aparece, com ondinhas.
func _atualizar_quadro() -> void:
	var q := 0
	if _acao > 0.0 and not nadando:
		q = 4
	elif andando:
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
