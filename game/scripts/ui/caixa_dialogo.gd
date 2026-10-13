class_name CaixaDialogo
extends CanvasLayer
## Caixa de conversa no pé da tela (estilo Pokémon): nome de quem fala, texto letra a letra,
## escolhas e perguntas dos livros. O jogo fica pausado enquanto ela está aberta.
## Espaço, Enter, E ou clique passam a fala; 1 a 4 escolhem uma opção.

signal acabou

const LETRAS_POR_SEGUNDO := 70.0

var id_conversa := ""
var conversa: Dictionary = {}
var _no: Dictionary = {}
var _paginas: Array = []
var _pagina := 0
var _estado := ""          # "texto", "escolhas", "pergunta" ou "aviso"
var _escolhas: Array = []
var _pergunta: Dictionary = {}
var _id_pergunta := ""
var _depois_do_aviso: Callable
var _tempo := 0.0

var _raiz: Control
var _caixa: PanelContainer
var _nome_caixa: PanelContainer
var _nome: Label
var _texto: Label
var _seta: Label
var _opcoes_caixa: PanelContainer
var _opcoes: VBoxContainer


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.theme = Visual.tema
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.gui_input.connect(_clique_fundo)
	add_child(_raiz)
	_caixa = PanelContainer.new()
	_caixa.position = Vector2(8, 192)
	_caixa.size = Vector2(464, 70)
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_caixa)
	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(440, 48)
	_texto.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_caixa.add_child(_texto)
	_seta = Label.new()
	_seta.text = "v"
	_seta.position = Vector2(8 + 464 - 18, 192 + 70 - 20)
	_raiz.add_child(_seta)
	_nome_caixa = PanelContainer.new()
	_nome_caixa.add_theme_stylebox_override("panel", Visual.caixa(preload("res://assets/sprites/ui/slot.png"), 3, 3))
	_nome_caixa.position = Vector2(16, 171)
	_nome_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_nome_caixa)
	_nome = Label.new()
	_nome_caixa.add_child(_nome)
	_opcoes_caixa = PanelContainer.new()
	_opcoes_caixa.visible = false
	_raiz.add_child(_opcoes_caixa)
	_opcoes = VBoxContainer.new()
	_opcoes.add_theme_constant_override("separation", 3)
	_opcoes_caixa.add_child(_opcoes)


## Abre a conversa 'id' (de Config.dialogos). 'quem' = nome padrão de quem fala.
func abrir(id: String, quem := "") -> void:
	id_conversa = id
	conversa = Config.dialogos.get(id, {})
	if quem != "" and not conversa.has("quem"):
		conversa = conversa.duplicate()
		conversa["quem"] = quem
	get_tree().paused = true
	_entrar(Dialogo.no_inicial(GameState.dados, conversa))


## Mostra um texto solto (placas, avisos) com a mesma caixa.
func abrir_texto(quem: String, paginas: Array) -> void:
	conversa = {"quem": quem, "nos": {"a": {"fala": paginas}}}
	get_tree().paused = true
	_entrar("a")


func fechar() -> void:
	get_tree().paused = false
	acabou.emit()
	queue_free()


func _entrar(id: String) -> void:
	_opcoes_caixa.visible = false
	if id == "" or id == "fim" or not conversa.get("nos", {}).has(id):
		fechar()
		return
	_no = conversa["nos"][id]
	if _no.has("ramos"):
		_entrar(Dialogo.escolher_ramo(GameState.dados, _no["ramos"]))
		return
	var avisos := Dialogo.aplicar(GameState.dados, _no.get("efeitos", []), Config.itens)
	_mostrar_avisos(avisos)
	_nome.text = str(_no.get("quem", conversa.get("quem", "")))
	_nome_caixa.visible = _nome.text != ""
	if _no.has("pergunta"):
		_id_pergunta = str(_no["pergunta"])
		if Progresso.bloqueada(GameState.dados, _id_pergunta):
			if _no.has("bloqueada"):
				_entrar(str(_no["bloqueada"]))
			else:
				_paginas = ["Pense mais um pouco... e volte amanhã."]
				_pagina = 0
				_no = {"ir": "fim"}
				_mostrar_pagina()
			return
		_pergunta = Dialogo.preparar_pergunta(Config.perguntas.get(_id_pergunta, {}))
	else:
		_id_pergunta = ""
	_paginas = Dialogo.paginas(_no)
	if _id_pergunta != "":
		_paginas = _paginas + [_pergunta["texto"]]
	_pagina = 0
	if _paginas.is_empty():
		_fim_das_paginas()
	else:
		_mostrar_pagina()


func _mostrar_avisos(avisos: Array) -> void:
	var main := get_parent()
	if avisos.is_empty() or not main or not "hud" in main:
		return
	main.hud.avisar("  ".join(avisos), 2.5)
	for a in avisos:
		if str(a).begins_with("Recebeu") or str(a) == "Missão concluída!" or str(a) == "Conquista!":
			Som.tocar("salvar", -4.0, false)
			break


func _mostrar_pagina() -> void:
	_estado = "texto"
	_texto.text = str(_paginas[_pagina])
	_texto.visible_characters = 0
	_tempo = 0.0


func _completa() -> bool:
	return _texto.visible_characters < 0 or _texto.visible_characters >= _texto.get_total_character_count()


func _process(delta: float) -> void:
	_pronta = true
	_seta.visible = _estado == "texto" and _completa() and int(Time.get_ticks_msec() / 350) % 2 == 0
	if _estado == "texto" and not _completa():
		_tempo += delta
		var n := mini(int(_tempo * LETRAS_POR_SEGUNDO), _texto.get_total_character_count())
		if n != _texto.visible_characters:
			_texto.visible_characters = n
			if n % 3 == 0:
				Som.tocar("selecionar", -14.0)


var _pronta := false


func _unhandled_input(e: InputEvent) -> void:
	if not _pronta:
		return
	if e.is_action_pressed("avancar") or e.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		_avancar()
	elif e.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		if _estado == "texto":
			_avancar()
	else:
		for i in 4:
			if e.is_action_pressed("barra_%d" % (i + 1)) and _opcoes_caixa.visible:
				get_viewport().set_input_as_handled()
				var botoes := _opcoes.get_children()
				if i < botoes.size():
					botoes[i].emit_signal("pressed")


func _clique_fundo(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_avancar()


func _avancar() -> void:
	if _estado != "texto":
		return
	if not _completa():
		_texto.visible_characters = _texto.get_total_character_count()
		return
	if _pagina < _paginas.size() - 1:
		_pagina += 1
		_mostrar_pagina()
		return
	_fim_das_paginas()


func _fim_das_paginas() -> void:
	if _depois_do_aviso.is_valid():
		var f := _depois_do_aviso
		_depois_do_aviso = Callable()
		f.call()
		return
	if _id_pergunta != "":
		_mostrar_opcoes_pergunta()
		return
	_escolhas = Dialogo.escolhas_visiveis(GameState.dados, _no)
	if not _escolhas.is_empty():
		_estado = "escolhas"
		var lista: Array = []
		for e in _escolhas:
			lista.append(str(e.get("texto", "")))
		_montar_opcoes(lista, func(i): _entrar(str(_escolhas[i].get("ir", "fim"))))
		return
	_entrar(str(_no.get("ir", "fim")))


func _mostrar_opcoes_pergunta() -> void:
	_estado = "pergunta"
	var lista: Array = _pergunta["opcoes"].duplicate()
	var com_dica := str(_pergunta.get("dica", "")) != ""
	if com_dica:
		lista.append("(Pedir dica)")
	_montar_opcoes(lista, func(i):
		if com_dica and i == lista.size() - 1:
			_mostrar_aviso_e(["Dica: a resposta está em %s." % _pergunta["dica"]], _mostrar_opcoes_pergunta)
			return
		_responder(i == int(_pergunta["certa"])))


func _responder(certa: bool) -> void:
	var def: Dictionary = Config.perguntas.get(_id_pergunta, {})
	var r := Progresso.responder(GameState.dados, _id_pergunta, def, certa, Config.balanceamento)
	var proximo := str(_no.get("certo" if certa else "errado", "fim"))
	if certa:
		Som.tocar("colher", 0.0, false)
		_entrar(proximo)
		return
	Som.tocar("enxada", -6.0)
	var aviso := ""
	if r == "errado_vida":
		aviso = "Errou... e perdeu um pouco de vida."
	elif r == "errado_amanha":
		aviso = "Errou. Esta pergunta só reabre amanhã."
	if aviso != "":
		_mostrar_aviso_e([aviso], func(): _entrar(proximo))
	else:
		_entrar(proximo)


## Mostra páginas soltas na caixa e, no fim, chama 'depois'.
func _mostrar_aviso_e(paginas: Array, depois: Callable) -> void:
	_opcoes_caixa.visible = false
	_paginas = paginas
	_pagina = 0
	_depois_do_aviso = depois
	_mostrar_pagina()


func _montar_opcoes(textos: Array, ao_escolher: Callable) -> void:
	for c in _opcoes.get_children():
		c.queue_free()
	var largura := 120.0
	for i in textos.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, textos[i]] if i < 4 else str(textos[i])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 20)
		var idx := i
		b.pressed.connect(func():
			Som.tocar("clique", 0.0, false)
			ao_escolher.call(idx))
		_opcoes.add_child(b)
		largura = maxf(largura, Visual.fonte.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Visual.TAM_TEXTO).x + 24)
	largura = minf(largura, 440.0)
	for b in _opcoes.get_children():
		b.custom_minimum_size.x = largura
	_opcoes_caixa.reset_size()
	var tam := _opcoes_caixa.get_combined_minimum_size()
	_opcoes_caixa.position = Vector2(472 - tam.x, 188 - tam.y)
	_opcoes_caixa.visible = true
