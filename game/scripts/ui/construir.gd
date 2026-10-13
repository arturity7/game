class_name Construir
extends CanvasLayer
## Menu Construir (tecla C): receitas pré-definidas com custo de material, como no Minecraft (D-057).
## Clique numa receita gasta os materiais e põe o item no inventário; depois ele é posto na fazenda
## com o botão esquerdo, como uma ferramenta. O jogo fica pausado enquanto o menu está aberto.

signal fechou

const ITENS := preload("res://assets/sprites/itens/itens.png")

var _lista: VBoxContainer
var _aviso: Label


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
	caixa.custom_minimum_size = Vector2(290, 180)
	centro.add_child(caixa)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	caixa.add_child(col)
	var titulo := Label.new()
	titulo.text = "Construir"
	titulo.add_theme_font_size_override("font_size", Visual.TAM_TITULO)
	col.add_child(titulo)
	var dica := Label.new()
	dica.text = "Faça a peça e ponha na fazenda com o botão esquerdo."
	dica.add_theme_color_override("font_color", Color("#6e4022"))
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dica.custom_minimum_size = Vector2(270, 0)
	col.add_child(dica)
	var rolar := ScrollContainer.new()
	rolar.custom_minimum_size = Vector2(270, 90)
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(rolar)
	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 2)
	rolar.add_child(_lista)
	var baixo := HBoxContainer.new()
	col.add_child(baixo)
	_aviso = Label.new()
	_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baixo.add_child(_aviso)
	var sair := Button.new()
	sair.text = "Fechar"
	sair.custom_minimum_size = Vector2(60, 20)
	sair.pressed.connect(fechar)
	baixo.add_child(sair)
	get_tree().paused = true
	_atualizar()


func fechar() -> void:
	Som.tocar("clique", 0.0, false)
	get_tree().paused = false
	fechou.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("menu") or e.is_action_pressed("construir"):
		get_viewport().set_input_as_handled()
		fechar()


## Ids dos itens que têm receita, na ordem de itens.json.
static func receitas() -> Array:
	var r: Array = []
	for id in Config.itens:
		if typeof(Config.itens[id]) == TYPE_DICTIONARY and Config.itens[id].has("receita"):
			r.append(id)
	return r


func _atualizar() -> void:
	var d: GameData = GameState.dados
	for f in _lista.get_children():
		f.queue_free()
	for id in receitas():
		var item: Dictionary = Config.itens[id]
		var pode := Construcao.pode_fazer(d, item)
		var linha := Button.new()
		linha.custom_minimum_size = Vector2(260, 22)
		var conteudo := HBoxContainer.new()
		conteudo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		conteudo.offset_left = 4
		conteudo.offset_right = -6
		conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conteudo.add_theme_constant_override("separation", 4)
		linha.add_child(conteudo)
		var ic := AtlasTexture.new()
		ic.atlas = ITENS
		ic.region = Rect2(int(item.get("icone", 0)) * 16, 0, 16, 16)
		var icone := TextureRect.new()
		icone.texture = ic
		icone.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conteudo.add_child(icone)
		var nome := Label.new()
		nome.text = "%s (tem %d)" % [str(item.get("nome", id)), Inventario.contar(d.jogador["inventario"], id)]
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conteudo.add_child(nome)
		var custo := Label.new()
		var partes: Array = []
		for mat in item["receita"]:
			partes.append("%d %s" % [int(item["receita"][mat]), str(Config.itens.get(mat, {}).get("nome", mat))])
		custo.text = ", ".join(partes)
		custo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not pode:
			custo.add_theme_color_override("font_color", Color("#a33f37"))
		conteudo.add_child(custo)
		var item_id: String = id
		linha.pressed.connect(func(): _fazer(item_id))
		_lista.add_child(linha)


func _fazer(id: String) -> void:
	var d: GameData = GameState.dados
	if Construcao.fazer(d, id, Config.itens):
		Som.tocar("enxada", -6.0, false)
		_aviso.text = "Feito: %s." % str(Config.itens[id].get("nome", id))
	elif not Construcao.pode_fazer(d, Config.itens[id]):
		Som.tocar("clique", 0.0, false)
		_aviso.text = "Falta material."
	else:
		_aviso.text = "Inventário cheio."
	_atualizar()
