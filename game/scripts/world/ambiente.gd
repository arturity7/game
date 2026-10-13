class_name Ambiente
extends Node2D
## Vida no cenário ao ar livre (só desenho, não interfere no jogo): borboletas de dia, folhas caindo
## das árvores e vaga-lumes à noite. Tudo acontece perto da câmera; nada vai para o save.
## Os vaga-lumes ficam numa camada própria para brilhar mesmo com a noite escurecendo o mapa.

const CORES_BORBOLETA := [Color("#f6dd6a"), Color("#f29bb0"), Color("#e6e6ee"), Color("#b8a6ef"), Color("#f9b064")]
const N_BORBOLETAS := 4
const N_VAGALUMES := 14

var arvores: PackedVector2Array = []   # copas (mundo) de onde caem folhas
var hora := 12.0
var _rng := RandomNumberGenerator.new()
var _borboletas: Array = []   # {p, alvo, cor, fase, vel}
var _folhas: Array = []       # {p, vy, fase, vida, cor}
var _vagalumes: Array = []    # {p, v, fase}
var _t := 0.0
var _prox_folha := 1.0
var _camada_noite: CanvasLayer
var _noite: Node2D


func _ready() -> void:
	_rng.randomize()
	z_index = 30
	_camada_noite = CanvasLayer.new()
	_camada_noite.layer = 1
	_camada_noite.follow_viewport_enabled = true
	add_child(_camada_noite)
	_noite = Node2D.new()
	_noite.draw.connect(_desenhar_vagalumes)
	_camada_noite.add_child(_noite)


func _centro() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	return cam.get_screen_center_position() if cam != null else Vector2(240, 135)


func _ponto_na_tela(margem := 0.0) -> Vector2:
	var c := _centro()
	return c + Vector2(_rng.randf_range(-240 - margem, 240 + margem), _rng.randf_range(-135 - margem, 135 + margem))


## 0 = noite, 1 = dia (com transição no amanhecer e no fim da tarde).
func _dia() -> float:
	if hora >= 7.0 and hora < 17.0:
		return 1.0
	if hora >= 5.0 and hora < 7.0:
		return (hora - 5.0) / 2.0
	if hora >= 17.0 and hora < 19.0:
		return (19.0 - hora) / 2.0
	return 0.0


func _process(delta: float) -> void:
	_t += delta
	var dia := _dia()
	var c := _centro()
	# borboletas: aparecem de dia, vagam devagar entre pontos perto da câmera
	var quer := int(round(N_BORBOLETAS * dia))
	while _borboletas.size() < quer:
		var p := _ponto_na_tela(20)
		_borboletas.append({"p": p, "alvo": p, "cor": CORES_BORBOLETA[_rng.randi() % CORES_BORBOLETA.size()],
			"fase": _rng.randf() * TAU, "vel": _rng.randf_range(14.0, 22.0)})
	if _borboletas.size() > quer and _rng.randf() < delta * 0.5:
		_borboletas.pop_back()
	for b in _borboletas:
		var p: Vector2 = b["p"]
		var alvo: Vector2 = b["alvo"]
		if p.distance_to(alvo) < 4.0:
			b["alvo"] = p + Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-40, 40))
		b["p"] = p.move_toward(alvo, float(b["vel"]) * delta) + Vector2(0, sin(_t * 5.0 + float(b["fase"])) * 0.25)
		if (b["p"] as Vector2).distance_to(c) > 340.0:
			b["p"] = _ponto_na_tela(10)
			b["alvo"] = b["p"]
	# folhas: de vez em quando uma folha cai de uma árvore que está na tela
	_prox_folha -= delta
	if _prox_folha <= 0.0 and dia > 0.0:
		_prox_folha = _rng.randf_range(0.8, 2.2)
		var vistas: Array = []
		for a in arvores:
			if absf(a.x - c.x) < 250.0 and absf(a.y - c.y) < 150.0:
				vistas.append(a)
		if not vistas.is_empty():
			var a: Vector2 = vistas[_rng.randi() % vistas.size()]
			_folhas.append({"p": a + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-6, 6)),
				"vy": _rng.randf_range(9.0, 14.0), "fase": _rng.randf() * TAU, "vida": 0.0,
				"cor": Color("#8fc45e") if _rng.randf() < 0.6 else Color("#e2c86e")})
	for f in _folhas:
		f["vida"] = float(f["vida"]) + delta
		f["p"] = (f["p"] as Vector2) + Vector2(sin(_t * 2.6 + float(f["fase"])) * 10.0 * delta, float(f["vy"]) * delta)
	_folhas = _folhas.filter(func(f): return float(f["vida"]) < 3.2)
	# vaga-lumes: à noite, flutuando e piscando
	var quer_v := int(round(N_VAGALUMES * (1.0 - dia)))
	while _vagalumes.size() < quer_v:
		_vagalumes.append({"p": _ponto_na_tela(20), "v": Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(3.0, 7.0),
			"fase": _rng.randf() * TAU})
	if _vagalumes.size() > quer_v:
		_vagalumes.resize(quer_v)
	for v in _vagalumes:
		v["v"] = (v["v"] as Vector2).rotated(sin(_t + float(v["fase"])) * delta * 0.8)
		v["p"] = (v["p"] as Vector2) + (v["v"] as Vector2) * delta
		if (v["p"] as Vector2).distance_to(c) > 320.0:
			v["p"] = _ponto_na_tela(10)
	queue_redraw()
	_noite.queue_redraw()


func _draw() -> void:
	for b in _borboletas:
		var p := (b["p"] as Vector2).round()
		var cor: Color = b["cor"]
		var aberta := fmod(_t * 9.0 + float(b["fase"]), 2.0) < 1.0
		draw_rect(Rect2(p + Vector2(0, 5), Vector2(2, 1)), Color(0, 0, 0, 0.18))   # sombrinha no chão
		if aberta:
			draw_rect(Rect2(p + Vector2(-2, -1), Vector2(2, 2)), cor)
			draw_rect(Rect2(p + Vector2(1, -1), Vector2(2, 2)), cor)
			draw_rect(Rect2(p + Vector2(-1, 1), Vector2(1, 1)), cor.darkened(0.25))
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 1)), cor.darkened(0.25))
		else:
			draw_rect(Rect2(p + Vector2(-1, -2), Vector2(1, 2)), cor)
			draw_rect(Rect2(p + Vector2(1, -2), Vector2(1, 2)), cor)
		draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 3)), Color("#2a1a12"))
	for f in _folhas:
		var p := (f["p"] as Vector2).round()
		var a := clampf((3.2 - float(f["vida"])) / 0.6, 0.0, 1.0)
		var cor: Color = f["cor"]
		cor.a = a
		var deitada := sin(_t * 5.2 + float(f["fase"])) > 0.0
		draw_rect(Rect2(p, Vector2(2, 1) if deitada else Vector2(1, 2)), cor)
		draw_rect(Rect2(p + (Vector2(1, 1) if deitada else Vector2(1, 1)), Vector2(1, 1)), Color(cor.darkened(0.3), a))


func _desenhar_vagalumes() -> void:
	for v in _vagalumes:
		var p := (v["p"] as Vector2).round()
		var brilho := 0.5 + 0.5 * sin(_t * 2.3 + float(v["fase"]) * 3.0)
		if brilho < 0.15:
			continue
		_noite.draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color(0.85, 1.0, 0.45, 0.22 * brilho))
		_noite.draw_rect(Rect2(p - Vector2(2, 0), Vector2(5, 1)), Color(0.85, 1.0, 0.45, 0.10 * brilho))
		_noite.draw_rect(Rect2(p - Vector2(0, 2), Vector2(1, 5)), Color(0.85, 1.0, 0.45, 0.10 * brilho))
		_noite.draw_rect(Rect2(p, Vector2(1, 1)), Color(0.95, 1.0, 0.7, brilho))
