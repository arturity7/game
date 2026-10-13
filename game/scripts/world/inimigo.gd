class_name Inimigo
extends CharacterBody2D
## Inimigo em tempo real, direto no mapa (D-027). Regras em "inimigos.json" (dos livros):
##   nome, folha (assets/sprites/inimigos/), quadro [l, a], vida, dano, velocidade, raio (contato, px),
##   cor_po (os monstros viram pó quando vencidos), comportamento:
##   - "perseguir": anda à toa; se vê o jogador (raio_visao), vai atrás dele e fere no contato.
##   - "investida": fareja, prepara (bate o pé) e corre em linha reta para onde o jogador estava.
##     Se bater num obstáculo, fica tonto ("tonto_s"); depois de "tontos_para_vencer" vezes, o
##     jogador pode chegar perto e terminar com o botão direito/E (o golpe final, sem luta de espada).
##   - "parado": boneco de treino.
## Folha: linhas = baixo, cima, esquerda, direita; colunas = parado, passo 1, passo 2, preparo/ataque.
## Não vai para o save: quem guarda que um chefe foi vencido é a flag "venceu:<id>" (Mundo/main).

signal vencido(inimigo: Inimigo)

const LINHAS := {"baixo": 0, "cima": 1, "esquerda": 2, "direita": 3}

var id := ""
var def: Dictionary = {}
var mundo: Mundo
var vida := 1.0
var sprite: Sprite2D
var estado := "andando"     # andando, perseguindo, farejando, preparando, correndo, tonto, parando, vencido
var tontos := 0
var pode_finalizar := false
var _tempo := 0.0
var _lado := "baixo"
var _dir := Vector2.ZERO
var _passo := 0.0
var _empurrao := Vector2.ZERO
var _piscar := 0.0
var _corrido := 0.0
var _rng := RandomNumberGenerator.new()
var _tam := Vector2i(16, 32)
var _estrelas: Node2D


func _ready() -> void:
	_rng.randomize()
	collision_layer = 0
	collision_mask = 1
	vida = float(def.get("vida", 3))
	var q: Array = def.get("quadro", [16, 32])
	_tam = Vector2i(int(q[0]), int(q[1]))
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.region_enabled = true
	sprite.offset = Vector2(-_tam.x / 2.0, -_tam.y + 2)
	sprite.texture = load("res://assets/sprites/inimigos/" + str(def.get("folha", "")))
	add_child(sprite)
	var forma := CollisionShape2D.new()
	var ret := RectangleShape2D.new()
	var larg := float(def.get("largura_pes", 10))
	ret.size = Vector2(larg, 6)
	forma.shape = ret
	forma.position = Vector2(0, -2)
	add_child(forma)
	_estrelas = Node2D.new()
	_estrelas.draw.connect(_desenhar_estrelas)
	_estrelas.position = Vector2(0, -_tam.y + 4)
	add_child(_estrelas)
	estado = "farejando" if str(def.get("comportamento", "")) == "investida" else "andando"
	_tempo = _rng.randf_range(0.8, 1.6)
	_quadro()


func _jogador() -> Jogador:
	return mundo.jogador if mundo != null else null


func _physics_process(delta: float) -> void:
	if mundo == null or estado == "vencido":
		return
	var j := _jogador()
	_tempo -= delta
	_piscar = maxf(0.0, _piscar - delta)
	sprite.modulate = Color(1, 0.55, 0.55) if _piscar > 0.0 and int(_piscar * 20.0) % 2 == 0 else Color.WHITE
	var v := Vector2.ZERO
	match str(def.get("comportamento", "perseguir")):
		"perseguir":
			v = _perseguir(j)
		"investida":
			v = _investida(j, delta)
		_:
			v = Vector2.ZERO
	velocity = v + _empurrao
	_empurrao = _empurrao.move_toward(Vector2.ZERO, 600.0 * delta)
	var antes := global_position
	move_and_slide()
	if estado == "correndo":
		_corrido += global_position.distance_to(antes)
		if get_slide_collision_count() > 0:
			_bateu()
		elif _corrido > float(def.get("distancia_investida", 220)):
			estado = "parando"
			_tempo = 0.6
	if v.length() > 1.0:
		_passo += delta * (2.0 if estado == "correndo" else 1.0)
		_virar(v)
	# contato com o jogador
	if j != null and estado in ["andando", "perseguindo", "correndo", "farejando"] and str(def.get("comportamento", "")) != "parado":
		if global_position.distance_to(j.global_position) < float(def.get("raio", 12)):
			var dano := float(def.get("dano_investida", def.get("dano", 10))) if estado == "correndo" else float(def.get("dano", 10))
			j.receber_dano(dano, global_position, 260.0 if estado == "correndo" else 150.0)
			if estado == "correndo":
				estado = "parando"
				_tempo = 0.8
	_quadro()
	_estrelas.queue_redraw()


func _perseguir(j: Jogador) -> Vector2:
	var vel := float(def.get("velocidade", 40))
	if j != null and global_position.distance_to(j.global_position) < float(def.get("raio_visao", 90)):
		estado = "perseguindo"
		return (j.global_position - global_position).normalized() * vel
	estado = "andando"
	if _tempo <= 0.0:
		_tempo = _rng.randf_range(1.0, 2.5)
		_dir = Vector2.ZERO if _rng.randf() < 0.4 else Vector2.from_angle(_rng.randi_range(0, 3) * PI / 2.0)
	return _dir * vel * 0.4


func _investida(j: Jogador, _delta: float) -> Vector2:
	var vel := float(def.get("velocidade", 30))
	match estado:
		"farejando":
			# anda devagar, virando o focinho para o cheiro do jogador
			if j != null:
				var para := j.global_position - global_position
				_virar(para)
				if _tempo <= 0.0:
					estado = "preparando"
					_tempo = float(def.get("preparo_s", 0.9))
					_dir = _cardinal(para)
					_virar(_dir)
					Som.tocar("enxada", -6.0)
				return para.normalized() * vel * 0.25
		"preparando":
			if _tempo <= 0.0:
				estado = "correndo"
				_corrido = 0.0
			elif int(_tempo * 10.0) % 3 == 0:
				Efeitos.particulas(mundo, global_position + Vector2(0, -2), Color("#8a7a62"), 1, 18.0)
			return Vector2.ZERO
		"correndo":
			return _dir * vel * float(def.get("multiplicador_investida", 4.5))
		"tonto":
			if _tempo <= 0.0:
				pode_finalizar = false
				estado = "farejando"
				_tempo = _rng.randf_range(1.2, 2.0)
			return Vector2.ZERO
		"parando":
			if _tempo <= 0.0:
				estado = "farejando"
				_tempo = _rng.randf_range(0.8, 1.5)
			return Vector2.ZERO
	return Vector2.ZERO


## Bateu num obstáculo correndo: fica tonto (e, depois de várias vezes, pode ser vencido).
func _bateu() -> void:
	estado = "tonto"
	tontos += 1
	_tempo = float(def.get("tonto_s", 2.5))
	_empurrao = -_dir * 80.0
	Efeitos.particulas(mundo, global_position + _dir * 10.0 + Vector2(0, -10), Color("#c7a57f"), 12, 60.0)
	Som.tocar("tombar", -6.0)
	var precisa := int(def.get("tontos_para_vencer", 0))
	if precisa > 0 and tontos >= precisa:
		pode_finalizar = true
		_tempo = float(def.get("tonto_final_s", 4.0))


func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2(signf(v.x), 0)
	return Vector2(0, signf(v.y))


func _virar(v: Vector2) -> void:
	if v.length() < 0.01:
		return
	if absf(v.x) > absf(v.y):
		_lado = "direita" if v.x > 0 else "esquerda"
	else:
		_lado = "baixo" if v.y > 0 else "cima"


func _quadro() -> void:
	var col := 0
	if estado in ["preparando", "tonto"]:
		col = 3
	elif velocity.length() > 1.0:
		col = 1 + int(_passo * 7.0) % 2
	sprite.region_rect = Rect2(col * _tam.x, int(LINHAS[_lado]) * _tam.y, _tam.x, _tam.y)


func _desenhar_estrelas() -> void:
	if estado == "tonto":
		var t := Time.get_ticks_msec() / 1000.0
		for k in 3:
			var a := t * 4.0 + k * TAU / 3.0
			var p := Vector2(cos(a) * 7.0, sin(a) * 2.5 - 2.0).round()
			_estrelas.draw_rect(Rect2(p, Vector2(2, 2)), Color("#f6dd6a"))
		if pode_finalizar:
			var y := -9.0 - 2.0 * sin(t * 8.0)
			_estrelas.draw_rect(Rect2(Vector2(-2, y - 1), Vector2(4, 9)), Color("#1e1420"))
			_estrelas.draw_rect(Rect2(Vector2(-1, y), Vector2(2, 5)), Color("#f6dd6a"))
			_estrelas.draw_rect(Rect2(Vector2(-1, y + 6), Vector2(2, 2)), Color("#f6dd6a"))
	elif estado == "preparando":
		var y2 := -6.0
		_estrelas.draw_rect(Rect2(Vector2(-2, y2 - 1), Vector2(4, 9)), Color("#1e1420"))
		_estrelas.draw_rect(Rect2(Vector2(-1, y2), Vector2(2, 5)), Color("#ec5a5a"))
		_estrelas.draw_rect(Rect2(Vector2(-1, y2 + 6), Vector2(2, 2)), Color("#ec5a5a"))


## Golpe do jogador (espada). Bonecos de treino só balançam.
func receber_golpe(dano: float, origem: Vector2) -> void:
	if estado == "vencido":
		return
	_piscar = 0.3
	_empurrao = (global_position - origem).normalized() * float(def.get("recuo", 140.0))
	Efeitos.particulas(mundo, global_position + Vector2(0, -_tam.y / 2.0), Color("#f4f0e8"), 5, 40.0)
	Som.tocar("machado", -4.0)
	if bool(def.get("invencivel", false)):
		return
	vida -= dano
	if vida <= 0.0:
		vencer()


## Vira pó (ou areia) e some.
func vencer() -> void:
	if estado == "vencido":
		return
	estado = "vencido"
	pode_finalizar = false
	collision_mask = 0
	var cor := Color(str(def.get("cor_po", "#d8c38a")))
	for k in 3:
		Efeitos.particulas(mundo, global_position + Vector2(_rng.randf_range(-6, 6), -_tam.y * (0.3 + 0.25 * k)), cor, 10, 55.0, Vector2(30, -10))
	Som.tocar("colher", -2.0)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(cor, 0.0), 0.7)
	tw.tween_callback(queue_free)
	vencido.emit(self)
