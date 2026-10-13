class_name Hud
extends CanvasLayer
## Barras de fome e vida, a hora e avisos curtos. O dia não aparece (GDD §6).

const ICONES := preload("res://assets/sprites/placeholder/itens.png")

var _painel: Control
var dormindo := false
var _aviso := ""
var _aviso_tempo := 0.0


func _ready() -> void:
	_painel = Control.new()
	_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.draw.connect(_desenhar)
	add_child(_painel)


func avisar(texto: String, segundos := 3.0) -> void:
	_aviso = texto
	_aviso_tempo = segundos


func _process(delta: float) -> void:
	if _aviso_tempo > 0.0:
		_aviso_tempo -= delta
	_painel.queue_redraw()


func _desenhar() -> void:
	var d: GameData = GameState.dados
	if d == null:
		return
	var cfg: Dictionary = Config.balanceamento
	var fonte := ThemeDB.fallback_font
	_barra(Vector2(6, 6), "Fome", float(d.jogador["fome"]) / float(cfg.get("fome_max", 100.0)), Color(0.93, 0.62, 0.2))
	_barra(Vector2(6, 18), "Vida", float(d.jogador["vida"]) / float(cfg.get("vida_max", 100.0)), Color(0.85, 0.25, 0.25))
	var largura := _painel.size.x
	_painel.draw_rect(Rect2(largura - 50, 4, 46, 14), Color(0, 0, 0, 0.55))
	_painel.draw_string(fonte, Vector2(largura - 46, 15), Survival.texto_hora(float(d.mundo["hora"])),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	_painel.draw_string(fonte, Vector2(largura - 80, 30), "$ %d" % int(d.jogador["dinheiro"]),
		HORIZONTAL_ALIGNMENT_RIGHT, 76, 10, Color(1, 0.9, 0.4))
	if dormindo:
		_painel.draw_rect(Rect2(Vector2.ZERO, _painel.size), Color(0, 0, 0.05, 0.55))
	_barra_itens(d)
	if _aviso_tempo > 0.0:
		var alfa := clampf(_aviso_tempo, 0.0, 1.0)
		_painel.draw_rect(Rect2(0, _painel.size.y - 44, largura, 16), Color(0, 0, 0, 0.6 * alfa))
		_painel.draw_string(fonte, Vector2(0, _painel.size.y - 32), _aviso, HORIZONTAL_ALIGNMENT_CENTER,
			largura, 10, Color(1, 1, 1, alfa))


func _barra_itens(d: GameData) -> void:
	var n := int(Config.balanceamento.get("slots_barra", 10))
	var inv: Array = d.jogador["inventario"]
	var sel := int(d.jogador["barra_selecionada"])
	var x0 := (_painel.size.x - n * 20) / 2.0
	var y0 := _painel.size.y - 24
	var fonte := ThemeDB.fallback_font
	for i in n:
		var r := Rect2(x0 + i * 20, y0, 18, 18)
		_painel.draw_rect(r, Color(0.2, 0.13, 0.08, 0.85))
		_painel.draw_rect(r, Color(1, 0.85, 0.4) if i == sel else Color(0.55, 0.38, 0.22), false, 1.0)
		var s = inv[i] if i < inv.size() else null
		if s == null:
			continue
		var def: Dictionary = Config.itens.get(s["id"], {})
		var ic := int(def.get("icone", 0))
		_painel.draw_texture_rect_region(ICONES, Rect2(r.position + Vector2(1, 1), Vector2(16, 16)), Rect2(ic * 16, 0, 16, 16))
		if int(s["qtd"]) > 1:
			_painel.draw_string(fonte, r.position + Vector2(9, 17), str(s["qtd"]), HORIZONTAL_ALIGNMENT_RIGHT, 9, 7, Color.WHITE)
		if def.has("capacidade"):
			var f := float(s.get("agua", 0)) / float(def["capacidade"])
			_painel.draw_rect(Rect2(r.position + Vector2(2, 15), Vector2(14 * f, 2)), Color(0.4, 0.7, 1.0))


func _barra(pos: Vector2, rotulo: String, fracao: float, cor: Color) -> void:
	var fonte := ThemeDB.fallback_font
	_painel.draw_string(fonte, pos + Vector2(0, 8), rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	var caixa := Rect2(pos + Vector2(28, 1), Vector2(60, 7))
	_painel.draw_rect(caixa, Color(0, 0, 0, 0.6))
	_painel.draw_rect(Rect2(caixa.position + Vector2(1, 1), Vector2(58 * clampf(fracao, 0, 1), 5)), cor)
