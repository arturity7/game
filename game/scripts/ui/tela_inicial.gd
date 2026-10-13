class_name TelaInicial
extends CanvasLayer
## Tela de abertura: logo sobre a fazenda (a câmera passeia devagar) e as opções
## Continuar (se houver save), Novo jogo, Opções e Sair.

signal escolheu(opcao: String)   # "continuar", "novo", "opcoes" ou "sair"

const LOGO := preload("res://assets/sprites/ui/logo.png")

var _raiz: Control


func _ready() -> void:
	layer = 20
	var tela := get_viewport().get_visible_rect().size
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = Visual.tema
	add_child(_raiz)
	var veu := ColorRect.new()
	veu.color = Color(0.05, 0.04, 0.1, 0.25)
	veu.set_anchors_preset(Control.PRESET_FULL_RECT)
	veu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(veu)
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.stretch_mode = TextureRect.STRETCH_KEEP
	logo.position = Vector2(roundf((tela.x - LOGO.get_width()) / 2.0), 30)
	_raiz.add_child(logo)
	var caixa := PanelContainer.new()
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 4)
	caixa.add_child(lista)
	var opcoes: Array = []
	if SaveSystem.existe():
		opcoes.append(["Continuar", "continuar"])
	opcoes.append(["Novo jogo", "novo"])
	opcoes.append(["Opções", "opcoes"])
	opcoes.append(["Sair", "sair"])
	var primeiro: Button = null
	for o in opcoes:
		var b := Button.new()
		b.text = o[0]
		b.custom_minimum_size = Vector2(120, 22)
		var id: String = o[1]
		b.pressed.connect(func():
			Som.tocar("clique", 0.0, false)
			escolheu.emit(id))
		lista.add_child(b)
		if primeiro == null:
			primeiro = b
	_raiz.add_child(caixa)
	var tam := caixa.get_combined_minimum_size()
	caixa.position = Vector2(roundf((tela.x - tam.x) / 2.0), roundf(tela.y - tam.y - 30))
	var versao := Label.new()
	versao.text = "protótipo 1"
	versao.add_theme_color_override("font_color", Visual.COR_CLARA)
	versao.add_theme_color_override("font_outline_color", Visual.COR_SOMBRA)
	versao.add_theme_constant_override("outline_size", 2)
	versao.position = Vector2(tela.x - 74, tela.y - 18)
	_raiz.add_child(versao)
	if primeiro:
		primeiro.grab_focus.call_deferred()
