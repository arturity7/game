class_name Hud
extends CanvasLayer
## Painéis de madeira: vida e fome (em cima, à esquerda), hora e dinheiro (em cima, à direita),
## barra de itens (embaixo) e avisos curtos. O dia não aparece (GDD §6).

const ITENS := preload("res://assets/sprites/itens/itens.png")
const SLOT := preload("res://assets/sprites/ui/slot.png")
const SLOT_SEL := preload("res://assets/sprites/ui/slot_sel.png")

var _painel: Control
var dormindo := false
var _aviso := ""
var _aviso_tempo := 0.0


func _ready() -> void:
	layer = 3   # acima da camada dos vaga-lumes (Ambiente)
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
	var tela := _painel.size
	if dormindo:
		_painel.draw_rect(Rect2(Vector2.ZERO, tela), Color(0.02, 0.02, 0.1, 0.6))
		var z := "Z" + "z".repeat(1 + int(Time.get_ticks_msec() / 500) % 3)
		Visual.texto(_painel, Vector2(0, tela.y / 2.0), z, Visual.COR_CLARA, Visual.TAM_TITULO, HORIZONTAL_ALIGNMENT_CENTER, tela.x, true)
	# vida e fome
	var p1 := Rect2(4, 4, 100, 36)
	_painel.draw_style_box(Visual.painel, p1)
	Visual.icone(_painel, p1.position + Vector2(7, 6), "vida")
	_barra(p1.position + Vector2(22, 9), 70, float(d.jogador["vida"]) / float(cfg.get("vida_max", 100.0)),
		Color("#d6383f"), Color("#f07a74"))
	Visual.icone(_painel, p1.position + Vector2(7, 18), "fome")
	_barra(p1.position + Vector2(22, 21), 70, float(d.jogador["fome"]) / float(cfg.get("fome_max", 100.0)),
		Color("#e8902c"), Color("#f6c56a"))
	# hora e dinheiro
	var p2 := Rect2(tela.x - 84, 4, 80, 36)
	_painel.draw_style_box(Visual.painel, p2)
	var hora := float(d.mundo["hora"])
	Visual.icone(_painel, p2.position + Vector2(7, 6), "sol" if hora >= 6.0 and hora < 18.0 else "lua")
	_painel.draw_string(Visual.fonte, p2.position + Vector2(22, 16), Survival.texto_hora(hora),
		HORIZONTAL_ALIGNMENT_LEFT, -1, Visual.TAM_TEXTO, Visual.COR_TEXTO)
	Visual.icone(_painel, p2.position + Vector2(7, 18), "moeda")
	_painel.draw_string(Visual.fonte, p2.position + Vector2(22, 28), str(int(d.jogador["dinheiro"])),
		HORIZONTAL_ALIGNMENT_LEFT, -1, Visual.TAM_TEXTO, Visual.COR_TEXTO)
	_barra_itens(d)
	if _aviso_tempo > 0.0 and _aviso != "":
		var alfa := clampf(_aviso_tempo * 2.0, 0.0, 1.0)
		var larg := Visual.fonte.get_string_size(_aviso, HORIZONTAL_ALIGNMENT_LEFT, -1, Visual.TAM_TEXTO).x + 20
		var r := Rect2(roundf((tela.x - larg) / 2.0), tela.y - 62, roundf(larg), 22)
		_painel.draw_style_box(Visual.painel, r)
		_painel.draw_string(Visual.fonte, r.position + Vector2(10, 15), _aviso, HORIZONTAL_ALIGNMENT_LEFT, -1,
			Visual.TAM_TEXTO, Color(Visual.COR_TEXTO, alfa))


func _barra_itens(d: GameData) -> void:
	var n := int(Config.balanceamento.get("slots_barra", 10))
	var inv: Array = d.jogador["inventario"]
	var sel := int(d.jogador["barra_selecionada"])
	var larg := n * 22 - 2 + 12
	var x0 := roundf((_painel.size.x - larg) / 2.0)
	var y0 := _painel.size.y - 34
	_painel.draw_style_box(Visual.painel, Rect2(x0, y0, larg, 32))
	for i in n:
		var r := Rect2(x0 + 6 + i * 22, y0 + 6, 20, 20)
		_painel.draw_texture(SLOT_SEL if i == sel else SLOT, r.position)
		var s = inv[i] if i < inv.size() else null
		if s == null:
			continue
		var def: Dictionary = Config.itens.get(s["id"], {})
		var ic := int(def.get("icone", 0))
		_painel.draw_texture_rect_region(ITENS, Rect2(r.position + Vector2(2, 2), Vector2(16, 16)), Rect2(ic * 16, 0, 16, 16))
		if int(s["qtd"]) > 1:
			Visual.texto(_painel, r.position + Vector2(0, 21), str(s["qtd"]), Visual.COR_CLARA, Visual.TAM_TEXTO,
				HORIZONTAL_ALIGNMENT_RIGHT, 19)
		if def.has("capacidade"):
			var f := clampf(float(s.get("agua", 0)) / float(def["capacidade"]), 0.0, 1.0)
			_painel.draw_rect(Rect2(r.position + Vector2(3, 16), Vector2(14, 2)), Color("#1e1420"))
			_painel.draw_rect(Rect2(r.position + Vector2(3, 16), Vector2(roundf(14 * f), 2)), Color("#5aa7d6"))


## Barra com moldura escura, fundo marrom e brilho em cima.
func _barra(pos: Vector2, largura: float, fracao: float, cor: Color, brilho: Color) -> void:
	_painel.draw_rect(Rect2(pos, Vector2(largura, 7)), Color("#1e1420"))
	_painel.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(largura - 2, 5)), Color("#6e4022"))
	var w := roundf((largura - 2) * clampf(fracao, 0.0, 1.0))
	if w > 0:
		_painel.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(w, 5)), cor)
		_painel.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(w, 1)), brilho)
