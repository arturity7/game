class_name Efeitos
extends RefCounted
## Efeitos visuais curtos: ferramenta balançando, terra e gotas voando, colheita subindo.
## Cada efeito é um nó que se apaga sozinho; nada disso vai para o save.

const ITENS := preload("res://assets/sprites/itens/itens.png")


## Ícone do item (16x16) girando sobre a célula: a enxada desce, o regador inclina.
static func ferramenta(pai: Node, celula: Vector2i, icone: int, tipo: String, esquerda: bool) -> void:
	var s := Sprite2D.new()
	s.texture = ITENS
	s.region_enabled = true
	s.region_rect = Rect2(icone * 16, 0, 16, 16)
	s.centered = false
	s.flip_h = esquerda
	s.z_index = 5
	var centro := Vector2(celula) * 16.0 + Vector2(8, 8)
	var sinal := -1.0 if esquerda else 1.0
	var tw := s.create_tween()
	if tipo == "enxada":
		# ponto de giro no fim do cabo (canto de baixo); a lâmina bate na célula
		s.offset = Vector2(-12, -13) if esquerda else Vector2(-4, -13)
		s.position = centro + Vector2(-6 * sinal, 4)
		s.rotation = deg_to_rad(-75.0 * sinal)
		tw.tween_property(s, "rotation", deg_to_rad(25.0 * sinal), 0.14).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): particulas(pai, centro + Vector2(0, 2), Color("#755034"), 7, 40.0))
		tw.tween_interval(0.08)
	else:
		s.offset = Vector2(-8, -8)
		s.position = centro + Vector2(-7 * sinal, -9)
		tw.tween_property(s, "rotation", deg_to_rad(40.0 * sinal), 0.12)
		tw.tween_callback(func(): gotas(pai, centro + Vector2(2 * sinal, -4)))
		tw.tween_interval(0.3)
	tw.tween_property(s, "modulate:a", 0.0, 0.1)
	tw.tween_callback(s.queue_free)
	pai.add_child(s)


static func gotas(pai: Node, origem: Vector2) -> void:
	particulas(pai, origem, Color("#8fcbea"), 9, 25.0, Vector2(0, 30))


## Pontinhos que saltam e caem (terra, água, folhas).
static func particulas(pai: Node, origem: Vector2, cor: Color, n: int, forca: float, impulso := Vector2.ZERO) -> void:
	var p := Particulas.new()
	p.position = origem
	p.z_index = 6
	for i in n:
		var ang := randf_range(-PI * 0.9, -PI * 0.1)
		p.pontos.append({
			"pos": Vector2(randf_range(-4, 4), randf_range(-2, 2)),
			"vel": Vector2(cos(ang), sin(ang)) * randf_range(0.4, 1.0) * forca + impulso,
			"cor": cor.lightened(randf_range(0.0, 0.25)),
		})
	pai.add_child(p)


## O produto colhido sobe e some.
static func colheita(pai: Node, celula: Vector2i, icone: int) -> void:
	var s := Sprite2D.new()
	s.texture = ITENS
	s.region_enabled = true
	s.region_rect = Rect2(icone * 16, 0, 16, 16)
	s.position = Vector2(celula) * 16.0 + Vector2(8, 0)
	s.z_index = 7
	var tw := s.create_tween()
	tw.set_parallel(true)
	tw.tween_property(s, "position:y", s.position.y - 14, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(s, "modulate:a", 0.0, 0.25).set_delay(0.35)
	tw.chain().tween_callback(s.queue_free)
	pai.add_child(s)
	particulas(pai, Vector2(celula) * 16.0 + Vector2(8, 10), Color("#63a63d"), 6, 35.0)


class Particulas:
	extends Node2D
	var pontos: Array = []
	var vida := 0.45

	func _process(delta: float) -> void:
		vida -= delta
		if vida <= 0.0:
			queue_free()
			return
		for p in pontos:
			var v: Vector2 = p["vel"]
			v.y += 160.0 * delta
			p["vel"] = v
			p["pos"] = p["pos"] + v * delta
		queue_redraw()

	func _draw() -> void:
		var a := clampf(vida / 0.2, 0.0, 1.0)
		for p in pontos:
			draw_rect(Rect2(p["pos"].round(), Vector2(1, 1)), Color(p["cor"], a))
