class_name Loja
extends CanvasLayer
## Tela da loja: abas Comprar e Vender. Clique compra ou vende 1; com Shift, compra 5 ou vende tudo.
## O jogo fica pausado enquanto ela está aberta. Dados em content/config/lojas.json e itens.json.

signal fechou

const ITENS := preload("res://assets/sprites/itens/itens.png")

var id_loja := ""
var _def: Dictionary = {}
var _aba := "comprar"
var _lista: VBoxContainer
var _dinheiro: Label
var _aviso: Label
var _botoes_aba := {}


func abrir(id: String) -> void:
	id_loja = id
	_def = Config.lojas.get(id, {})
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
	caixa.custom_minimum_size = Vector2(280, 200)
	centro.add_child(caixa)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	caixa.add_child(col)
	var topo := HBoxContainer.new()
	col.add_child(topo)
	var titulo := Label.new()
	titulo.text = str(_def.get("nome", id))
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	_dinheiro = Label.new()
	topo.add_child(_dinheiro)
	var abas := HBoxContainer.new()
	abas.add_theme_constant_override("separation", 4)
	col.add_child(abas)
	for a in [["comprar", "Comprar"], ["vender", "Vender"]]:
		var b := Button.new()
		b.text = a[1]
		b.custom_minimum_size = Vector2(70, 20)
		b.toggle_mode = true
		var chave: String = a[0]
		b.pressed.connect(func(): _mudar_aba(chave))
		abas.add_child(b)
		_botoes_aba[chave] = b
	var rolar := ScrollContainer.new()
	rolar.custom_minimum_size = Vector2(260, 116)
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
	_mudar_aba("comprar")


func fechar() -> void:
	Som.tocar("clique", 0.0, false)
	get_tree().paused = false
	fechou.emit()
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		fechar()


func _mudar_aba(aba: String) -> void:
	_aba = aba
	for k in _botoes_aba:
		_botoes_aba[k].button_pressed = (k == aba)
	_aviso.text = ""
	_atualizar()


func _atualizar() -> void:
	var d: GameData = GameState.dados
	_dinheiro.text = "$ %d" % int(d.jogador["dinheiro"])
	for f in _lista.get_children():
		f.queue_free()
	var inv: Array = d.jogador["inventario"]
	var ids: Array = _def.get("vende", []) if _aba == "comprar" else Precos.que_a_loja_compra(inv, _def.get("compra", []), Config.itens)
	var algum := false
	for id in ids:
		var item: Dictionary = Config.itens.get(id, {})
		var preco := int(item.get("preco", 0)) if _aba == "comprar" else Precos.venda(item, Config.itens)
		var tem := Inventario.contar(inv, id)
		if _aba == "vender" and tem <= 0:
			continue
		algum = true
		var linha := Button.new()
		linha.custom_minimum_size = Vector2(250, 22)
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
		nome.text = str(item.get("nome", id)) + (" (%d)" % tem if _aba == "vender" else "")
		if _aba == "vender" and str(item.get("tipo", "")) in ["ferramenta", "arma"] and not item.has("venda"):
			var primeira := str(item.get("nome", id)).split(" ")[0]
			nome.text += " usada" if primeira.ends_with("a") else " usado"
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conteudo.add_child(nome)
		var valor := Label.new()
		valor.text = "$ %d" % preco
		valor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		conteudo.add_child(valor)
		var item_id: String = id
		linha.gui_input.connect(func(e): _clique(e, item_id, preco))
		_lista.add_child(linha)
	if not algum:
		var nada := Label.new()
		nada.text = "Nada para vender." if _aba == "vender" else "Nada à venda."
		_lista.add_child(nada)


func _clique(e: InputEvent, id: String, preco: int) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	var d: GameData = GameState.dados
	var inv: Array = d.jogador["inventario"]
	var qtd := 5 if e.shift_pressed else 1
	if _aba == "comprar":
		var feitas := 0
		for i in qtd:
			if int(d.jogador["dinheiro"]) < preco:
				_aviso.text = "Dinheiro não basta."
				break
			if Inventario.adicionar(inv, id, 1, Config.itens) > 0:
				_aviso.text = "Inventário cheio."
				break
			d.jogador["dinheiro"] = int(d.jogador["dinheiro"]) - preco
			feitas += 1
		if feitas > 0:
			Som.tocar("colher")
			_aviso.text = "Comprou %d." % feitas
	else:
		var total := Inventario.contar(inv, id) if e.shift_pressed else 1
		var vendidas := 0
		for i in total:
			var slot := _slot_com(inv, id)
			if slot < 0:
				break
			Inventario.remover(inv, slot, 1)
			d.jogador["dinheiro"] = int(d.jogador["dinheiro"]) + preco
			vendidas += 1
		if vendidas > 0:
			Som.tocar("colher")
			_aviso.text = "Vendeu %d." % vendidas
			var guardado := Progresso.guardar_decimo(d, preco * vendidas)
			if guardado > 0:
				_aviso.text += " Arkad guardou $ %d." % guardado
	_atualizar()


func _slot_com(inv: Array, id: String) -> int:
	for i in inv.size():
		if inv[i] != null and str(inv[i]["id"]) == id:
			return i
	return -1
