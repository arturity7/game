class_name MenuPausa
extends CanvasLayer
## Menu do Esc: o jogador salva a qualquer momento pelo menu (GDD §8) e abre as Opções.

signal pediu_salvar
signal pediu_carregar

var tela_opcoes: TelaOpcoes = null
var _caixa: PanelContainer
var ativo := true   # o Esc só abre o menu durante o jogo (não na tela de abertura)


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.03, 0.08, 0.55)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.theme = Visual.tema
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)
	_caixa = PanelContainer.new()
	centro.add_child(_caixa)
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 4)
	_caixa.add_child(lista)
	var titulo := Label.new()
	titulo.text = "Leaf & Lore"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", Visual.fonte_forte)
	titulo.add_theme_font_size_override("font_size", Visual.TAM_TITULO)
	lista.add_child(titulo)
	for item in [["Continuar", _fechar], ["Salvar", func(): pediu_salvar.emit()],
			["Carregar", func(): pediu_carregar.emit()], ["Opções", _opcoes], ["Sair", func(): get_tree().quit()]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(120, 22)
		b.pressed.connect(func(): Som.tocar("clique", 0.0, false))
		b.pressed.connect(item[1])
		lista.add_child(b)
	visible = false


func _opcoes() -> void:
	if tela_opcoes != null:
		return
	tela_opcoes = TelaOpcoes.new()
	tela_opcoes.fechou.connect(func(): tela_opcoes = null)
	get_parent().add_child(tela_opcoes)


func _unhandled_input(evento: InputEvent) -> void:
	if tela_opcoes != null:
		return
	if ativo and evento.is_action_pressed("menu"):
		if visible:
			_fechar()
		else:
			_abrir()
		get_viewport().set_input_as_handled()


func _abrir() -> void:
	visible = true
	get_tree().paused = true


func _fechar() -> void:
	visible = false
	get_tree().paused = false
