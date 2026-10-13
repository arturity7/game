class_name Diario
extends CanvasLayer
## Diário (tecla J ou Tab): missões ativas e concluídas (GDD: um diário reúne as missões) e
## conquistas em forma de medalhas, o único lugar onde aparece a contagem de dias (GDD §6).

signal fechou

const ICONES := preload("res://assets/sprites/ui/icones_hud.png")

var _aba := "missoes"
var _lista: VBoxContainer
var _botoes := {}


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fundo := ColorRect.new()
	fundo.color = Color(0.05, 0.03, 0.08, 0.5)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.theme = Visual.tema
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)
	var caixa := PanelContainer.new()
	caixa.custom_minimum_size = Vector2(320, 220)
	centro.add_child(caixa)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	caixa.add_child(col)
	var titulo := Label.new()
	titulo.text = "Diário"
	titulo.add_theme_font_size_override("font_size", Visual.TAM_TITULO)
	col.add_child(titulo)
	var abas := HBoxContainer.new()
	abas.add_theme_constant_override("separation", 4)
	col.add_child(abas)
	for a in [["missoes", "Missões"], ["conquistas", "Conquistas"]]:
		var b := Button.new()
		b.text = a[1]
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(80, 20)
		var chave: String = a[0]
		b.pressed.connect(func(): _mudar(chave))
		abas.add_child(b)
		_botoes[chave] = b
	var rolar := ScrollContainer.new()
	rolar.custom_minimum_size = Vector2(300, 120)
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(rolar)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 3)
	rolar.add_child(_lista)
	var fechar_b := Button.new()
	fechar_b.text = "Fechar"
	fechar_b.custom_minimum_size = Vector2(60, 20)
	fechar_b.size_flags_horizontal = Control.SIZE_SHRINK_END
	fechar_b.pressed.connect(fechar)
	col.add_child(fechar_b)
	get_tree().paused = true
	_mudar("missoes")


func fechar() -> void:
	Som.tocar("clique", 0.0, false)
	get_tree().paused = false
	fechou.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("menu") or e.is_action_pressed("diario"):
		get_viewport().set_input_as_handled()
		fechar()


func _mudar(aba: String) -> void:
	_aba = aba
	for k in _botoes:
		_botoes[k].button_pressed = (k == aba)
	for c in _lista.get_children():
		c.queue_free()
	if aba == "missoes":
		_missoes()
	else:
		_conquistas()


func _linha(texto: String, cor := Visual.COR_TEXTO, recuo := 0) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(290 - recuo, 0)
	l.add_theme_color_override("font_color", cor)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", recuo)
	m.add_child(l)
	_lista.add_child(m)
	return l


func _missoes() -> void:
	var d: GameData = GameState.dados
	var ativas: Array = []
	var feitas: Array = []
	for id in Config.missoes:
		var estado := Progresso.missao(d, id)
		if estado == "ativa":
			ativas.append(id)
		elif estado == "feita":
			feitas.append(id)
	if ativas.is_empty() and feitas.is_empty():
		_linha("Nenhuma missão ainda. Converse com as pessoas.")
		return
	for id in ativas:
		var m: Dictionary = Config.missoes[id]
		_linha("> " + str(m.get("nome", id)))
		_linha(str(m.get("descricao", "")), Color("#6e4022"), 10)
	if not feitas.is_empty():
		_linha("Concluídas:", Color("#4a8a50"))
		for id in feitas:
			_linha("- " + str(Config.missoes[id].get("nome", id)), Color("#6e4022"), 6)


func _conquistas() -> void:
	var d: GameData = GameState.dados
	_linha("Dias vividos: %d" % int(d.mundo["dia"]))
	var total := 0
	var ganhas := 0
	for id in Config.conquistas:
		total += 1
		var c: Dictionary = Config.conquistas[id]
		var tem := Progresso.tem_conquista(d, id)
		var livro := str(Config.livros.get(str(c.get("livro", "")), {}).get("titulo", ""))
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 4)
		var ic := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = ICONES
		at.region = Rect2(Visual.ICONE["medalha"] * 12, 0, 12, 12)
		ic.texture = at
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		ic.modulate = Color.WHITE if tem else Color(0.2, 0.15, 0.1, 0.4)
		linha.add_child(ic)
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(270, 0)
		if tem:
			ganhas += 1
			l.text = "%s — %s" % [str(c.get("nome", id)), str(c.get("descricao", ""))]
		else:
			l.text = "???" + (" (%s)" % livro if livro != "" else "")
			l.add_theme_color_override("font_color", Color("#94592f"))
		linha.add_child(l)
		_lista.add_child(linha)
	if total == 0:
		_linha("Nenhuma conquista ainda.")
	else:
		_linha("%d de %d medalhas." % [ganhas, total], Color("#4a8a50"))
