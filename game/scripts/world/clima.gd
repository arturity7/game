class_name Clima
extends CanvasLayer
## Chuva por cima do mapa (só desenho e som): "chuva" ou "tempestade" (com relâmpagos e trovões).
## Fica numa camada da tela, abaixo do HUD. Mapas com "clima" no JSON (ex.: a noite da tempestade).

var tipo := "chuva"
var _gotas: Array = []      # [Vector2 posição na tela, velocidade]
var _respingos: Array = []  # [Vector2, vida]
var _rng := RandomNumberGenerator.new()
var _proximo_raio := 4.0
var _flash: ColorRect
var _desenho: Node2D
var _som: AudioStreamPlayer
var _t := 0.0


func _ready() -> void:
	layer = 1
	_rng.randomize()
	_desenho = Node2D.new()
	_desenho.draw.connect(_desenhar)
	add_child(_desenho)
	_flash = ColorRect.new()
	_flash.color = Color(0.85, 0.9, 1.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	var n := 150 if tipo == "tempestade" else 90
	for i in n:
		_gotas.append([Vector2(_rng.randf_range(-40, 500), _rng.randf_range(-20, 280)), _rng.randf_range(260, 360)])
	var s = load("res://assets/sons/chuva.wav")
	if s != null:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2
		_som = AudioStreamPlayer.new()
		_som.bus = "Efeitos"
		_som.stream = s
		_som.volume_db = -14.0 if tipo == "tempestade" else -18.0
		add_child(_som)
		_som.play()
	_proximo_raio = _rng.randf_range(2.0, 5.0)


func _process(delta: float) -> void:
	_t += delta
	for g in _gotas:
		var p: Vector2 = g[0]
		p += Vector2(-0.35, 1.0) * float(g[1]) * delta
		if p.y > 275.0:
			if _rng.randf() < 0.5:
				_respingos.append([Vector2(p.x, _rng.randf_range(10, 268)), 0.18])
			p = Vector2(_rng.randf_range(-20, 520), _rng.randf_range(-30, -4))
		g[0] = p
	for r in _respingos:
		r[1] = float(r[1]) - delta
	_respingos = _respingos.filter(func(r): return float(r[1]) > 0.0)
	if tipo == "tempestade":
		_proximo_raio -= delta
		if _proximo_raio <= 0.0:
			_proximo_raio = _rng.randf_range(5.0, 12.0)
			_relampago()
	_desenho.queue_redraw()


func _relampago() -> void:
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.55, 0.04)
	tw.tween_property(_flash, "color:a", 0.0, 0.12)
	tw.tween_property(_flash, "color:a", 0.35, 0.05)
	tw.tween_property(_flash, "color:a", 0.0, 0.3)
	tw.tween_interval(_rng.randf_range(0.3, 1.0))
	tw.tween_callback(func(): Som.tocar("trovao", -4.0))


func _desenhar() -> void:
	var cor := Color(0.78, 0.85, 0.98, 0.5)
	var cor2 := Color(0.78, 0.85, 0.98, 0.28)
	for g in _gotas:
		var p: Vector2 = (g[0] as Vector2).round()
		_desenho.draw_rect(Rect2(p, Vector2(1, 3)), cor)
		_desenho.draw_rect(Rect2(p + Vector2(-1, 3), Vector2(1, 3)), cor2)
	for r in _respingos:
		var p: Vector2 = (r[0] as Vector2).round()
		var a := float(r[1]) / 0.18
		_desenho.draw_rect(Rect2(p + Vector2(-2, 0), Vector2(1, 1)), Color(0.8, 0.88, 1.0, 0.5 * a))
		_desenho.draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 1)), Color(0.8, 0.88, 1.0, 0.5 * a))
		_desenho.draw_rect(Rect2(p + Vector2(-1, -1), Vector2(2, 1)), Color(0.8, 0.88, 1.0, 0.35 * a))
