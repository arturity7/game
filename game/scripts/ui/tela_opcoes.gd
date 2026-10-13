class_name TelaOpcoes
extends CanvasLayer
## Tela de Opções (no menu do Esc e na abertura): volume geral, da música e dos efeitos,
## mudo, tela cheia e "Restaurar padrão". Tudo é guardado na hora (autoload Opcoes).

signal fechou

const LARG_BARRA := 100

var _linhas := {}       # chave -> [Control da barra, Label do valor]
var _botoes := {}       # chave -> Button (sim/não)


func _ready() -> void:
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.03, 0.08, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.theme = Visual.tema
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)
	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(260, 0)
	centro.add_child(caixa)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	caixa.add_child(col)
	var titulo := Label.new()
	titulo.text = "Opções"
	titulo.add_theme_font_size_override("font_size", Visual.TAM_TITULO)
	col.add_child(titulo)
	for par in [["volume_geral", "Volume geral"], ["volume_musica", "Música"], ["volume_efeitos", "Efeitos"]]:
		col.add_child(_linha_volume(par[0], par[1]))
	for par in [["mudo", "Sem som"], ["tela_cheia", "Tela cheia"]]:
		col.add_child(_linha_sim_nao(par[0], par[1]))
	var baixo := HBoxContainer.new()
	baixo.add_theme_constant_override("separation", 6)
	col.add_child(baixo)
	var padrao := Button.new()
	padrao.text = "Restaurar padrão"
	padrao.custom_minimum_size = Vector2(130, 20)
	padrao.pressed.connect(func():
		Opcoes.restaurar_padrao()
		Som.tocar("clique", 0.0, false)
		_atualizar())
	baixo.add_child(padrao)
	var voltar := Button.new()
	voltar.text = "Voltar"
	voltar.custom_minimum_size = Vector2(70, 20)
	voltar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voltar.pressed.connect(fechar)
	baixo.add_child(voltar)
	_atualizar()
	voltar.grab_focus.call_deferred()


func _linha_volume(chave: String, nome: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	var l := Label.new()
	l.text = nome
	l.custom_minimum_size = Vector2(78, 0)
	h.add_child(l)
	var menos := Button.new()
	menos.text = "-"
	menos.custom_minimum_size = Vector2(18, 18)
	menos.pressed.connect(func(): _mudar(chave, -10))
	h.add_child(menos)
	var barra := Control.new()
	barra.custom_minimum_size = Vector2(LARG_BARRA, 18)
	barra.mouse_filter = Control.MOUSE_FILTER_STOP
	barra.draw.connect(func(): _desenhar_barra(barra, chave))
	barra.gui_input.connect(func(e): _clique_barra(e, barra, chave))
	h.add_child(barra)
	var mais := Button.new()
	mais.text = "+"
	mais.custom_minimum_size = Vector2(18, 18)
	mais.pressed.connect(func(): _mudar(chave, 10))
	h.add_child(mais)
	var v := Label.new()
	v.custom_minimum_size = Vector2(30, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	_linhas[chave] = [barra, v]
	return h


func _linha_sim_nao(chave: String, nome: String) -> Control:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = nome
	l.custom_minimum_size = Vector2(78, 0)
	h.add_child(l)
	var b := Button.new()
	b.custom_minimum_size = Vector2(60, 18)
	b.pressed.connect(func():
		Opcoes.definir(chave, not bool(Opcoes.valor(chave)))
		Som.tocar("clique", 0.0, false)
		_atualizar())
	h.add_child(b)
	_botoes[chave] = b
	return h


func _mudar(chave: String, passo: int) -> void:
	Opcoes.definir(chave, int(Opcoes.valor(chave)) + passo)
	Som.tocar("selecionar", 0.0, false)
	_atualizar()


func _clique_barra(e: InputEvent, barra: Control, chave: String) -> void:
	var arrastando: bool = e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	var clicou: bool = e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT
	if clicou or arrastando:
		var v := int(round(clampf(e.position.x / barra.size.x, 0.0, 1.0) * 20.0)) * 5
		if v != int(Opcoes.valor(chave)):
			Opcoes.definir(chave, v)
			_atualizar()


func _desenhar_barra(barra: Control, chave: String) -> void:
	var r := Rect2(Vector2(0, 5), Vector2(barra.size.x, 8))
	barra.draw_rect(r, Color("#4a2a16"))
	barra.draw_rect(r.grow(-1), Color("#f0dcae"))
	var f := clampf(int(Opcoes.valor(chave)) / 100.0, 0.0, 1.0)
	if f > 0.0:
		var cheia := Rect2(r.position + Vector2(1, 1), Vector2((r.size.x - 2) * f, r.size.y - 2))
		barra.draw_rect(cheia, Color("#4a8a50"))
		barra.draw_rect(Rect2(cheia.position, Vector2(cheia.size.x, 2)), Color("#68a866"))
	var x := 1 + (r.size.x - 2) * f
	barra.draw_rect(Rect2(Vector2(roundf(x) - 2, 2), Vector2(4, 14)), Color("#6e4022"))
	barra.draw_rect(Rect2(Vector2(roundf(x) - 1, 3), Vector2(2, 12)), Color("#d99a58"))


func _atualizar() -> void:
	for chave in _linhas:
		var barra: Control = _linhas[chave][0]
		var v: Label = _linhas[chave][1]
		v.text = "%d%%" % int(Opcoes.valor(chave))
		barra.queue_redraw()
	for chave in _botoes:
		_botoes[chave].text = "Sim" if bool(Opcoes.valor(chave)) else "Não"


func fechar() -> void:
	Som.tocar("clique", 0.0, false)
	fechou.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		fechar()
