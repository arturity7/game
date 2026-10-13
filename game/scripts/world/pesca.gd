class_name Pesca
extends Node2D
## Pesca simples, como no Minecraft (D-056): joga a linha na água, espera e puxa na hora certa.
## A boia afunda (com um "!") e o jogador tem um instante para puxar (clique ou E).
## O que se pesca vem de "peixes" no mapa: [{"item", "peso", "noite": true|false, "dia": true|false}].

signal acabou(resultado: String, item: String)   # "pegou", "cedo", "escapou" ou "cancelou"

const JANELA := 0.75          # segundos para puxar depois da mordida
var alvo := Vector2.ZERO      # ponto da boia (mundo)
var mao := Vector2.ZERO       # ponta da vara (mundo)
var cabo := Vector2.ZERO      # mão do jogador (mundo)
var tabela: Array = []
var hora := 12.0
var _espera := 0.0
var _mordida := -1.0
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func comecar(origem: Vector2, ponto: Vector2, peixes: Array, hora_do_dia: float, mao_jogador := Vector2.INF) -> void:
	mao = origem
	cabo = mao_jogador if mao_jogador != Vector2.INF else origem
	alvo = ponto
	tabela = peixes
	hora = hora_do_dia
	_rng.randomize()
	_espera = _rng.randf_range(1.8, 5.5)
	z_index = 6
	Efeitos.particulas(get_parent(), alvo, Color("#d4f0fb"), 6, 25.0)
	Som.tocar("encher", -10.0)


func _process(delta: float) -> void:
	_t += delta
	if _mordida < 0.0 and _t >= _espera:
		_mordida = _t
		Som.tocar("colher", -4.0)
		Efeitos.particulas(get_parent(), alvo, Color("#d4f0fb"), 8, 35.0)
	elif _mordida >= 0.0 and _t - _mordida > JANELA:
		_terminar("escapou", "")
		return
	queue_redraw()


## O jogador puxou a linha.
func puxar() -> void:
	if _mordida < 0.0:
		_terminar("cedo", "")
	else:
		_terminar("pegou", Peixes.sortear(tabela, hora, _rng))


func cancelar() -> void:
	_terminar("cancelou", "")


func _terminar(resultado: String, item: String) -> void:
	set_process(false)
	acabou.emit(resultado, item)
	queue_free()


func _draw() -> void:
	var afundou := _mordida >= 0.0
	var boia := alvo + Vector2(0, 2 if afundou else sin(_t * 3.0))
	# linha curva da ponta da vara até a boia
	var meio := (mao + boia) / 2.0 + Vector2(0, 6)
	var pontos := PackedVector2Array()
	for i in 9:
		var k := i / 8.0
		pontos.append(mao.lerp(meio, k).lerp(meio.lerp(boia, k), k) - global_position)
	draw_polyline(pontos, Color(0.95, 0.95, 0.9, 0.8), 1.0)
	draw_line(cabo - global_position, mao - global_position, Color("#552f1a"), 2.0)
	draw_line(cabo - global_position, mao - global_position, Color("#ad7044"), 1.0)
	var b := boia - global_position
	draw_rect(Rect2(b + Vector2(-2, -3 if not afundou else -1), Vector2(4, 2 if afundou else 3)), Color("#d6383f"))
	if not afundou:
		draw_rect(Rect2(b + Vector2(-2, 0), Vector2(4, 1)), Color("#f4f0e8"))
	draw_rect(Rect2(b + Vector2(-3, 1), Vector2(6, 1)), Color(0.85, 0.95, 1.0, 0.6))
	if afundou:
		var y := -14.0 - 2.0 * sin(_t * 18.0)
		draw_rect(Rect2(b + Vector2(-2, y - 1), Vector2(4, 9)), Color("#1e1420"))
		draw_rect(Rect2(b + Vector2(-1, y), Vector2(2, 5)), Color("#f6dd6a"))
		draw_rect(Rect2(b + Vector2(-1, y + 6), Vector2(2, 2)), Color("#f6dd6a"))
