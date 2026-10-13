class_name Cursor
extends Node2D
## Contorno na célula onde a ferramenta vai agir.

var celula := Vector2i.ZERO
var ativo := false


func mostrar(c: Vector2i) -> void:
	if c != celula or not ativo:
		celula = c
		ativo = true
		queue_redraw()


func _draw() -> void:
	if ativo:
		draw_rect(Rect2(Vector2(celula) * 16.0, Vector2(16, 16)), Color(1, 1, 1, 0.8), false, 1.0)
