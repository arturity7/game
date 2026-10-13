class_name Cursor
extends Node2D
## Marca a célula onde a ferramenta vai agir: quatro cantos que pulsam de leve.

var celula := Vector2i.ZERO
var ativo := false


func mostrar(c: Vector2i) -> void:
	celula = c
	ativo = true
	queue_redraw()


func _draw() -> void:
	if not ativo:
		return
	var p := Vector2(celula) * 16.0
	var a := 0.7 + 0.3 * sin(Time.get_ticks_msec() / 180.0)
	var sombra := Color(0.12, 0.07, 0.05, 0.45 * a)
	var claro := Color(1, 0.98, 0.85, a)
	var tracos := [
		Rect2(0, 0, 4, 1), Rect2(0, 0, 1, 4),
		Rect2(12, 0, 4, 1), Rect2(15, 0, 1, 4),
		Rect2(0, 15, 4, 1), Rect2(0, 12, 1, 4),
		Rect2(12, 15, 4, 1), Rect2(15, 12, 1, 4),
	]
	for r in tracos:
		draw_rect(Rect2(p + r.position + Vector2(1, 1), r.size), sombra)
	for r in tracos:
		draw_rect(Rect2(p + r.position, r.size), claro)
