class_name MenuPausa
extends CanvasLayer
## Menu do Esc: o jogador salva a qualquer momento pelo menu (GDD §8).

signal pediu_salvar
signal pediu_carregar

var _caixa: PanelContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_caixa = PanelContainer.new()
	_caixa.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_caixa)
	var lista := VBoxContainer.new()
	_caixa.add_child(lista)
	var titulo := Label.new()
	titulo.text = "Leaf & Lore"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 12)
	lista.add_child(titulo)
	for item in [["Continuar", _fechar], ["Salvar", func(): pediu_salvar.emit()],
			["Carregar", func(): pediu_carregar.emit()], ["Sair", func(): get_tree().quit()]]:
		var b := Button.new()
		b.text = item[0]
		b.add_theme_font_size_override("font_size", 10)
		b.custom_minimum_size = Vector2(110, 18)
		b.pressed.connect(item[1])
		lista.add_child(b)
	_caixa.position = -_caixa.get_combined_minimum_size() / 2.0
	visible = false


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("menu"):
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
