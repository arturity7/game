extends Node2D
## Cena principal do protótipo: carrega ou cria a partida, monta o mundo e roda as regras.

var mundo: Mundo
var hud: Hud
var menu: MenuPausa
var dormindo := false
var em_jogo := false          # false enquanto a tela de abertura está aberta
var _redesenhar_em := 0.0
var _inicio: TelaInicial
var _passeio := 0.0
var _trocando := false        # true durante a passagem de um mapa para outro
var _cortina: ColorRect       # tela preta da passagem


func _ready() -> void:
	hud = Hud.new()
	add_child(hud)
	menu = MenuPausa.new()
	add_child(menu)
	menu.pediu_salvar.connect(_salvar)
	menu.pediu_carregar.connect(_carregar)
	var camada := CanvasLayer.new()
	camada.layer = 15
	add_child(camada)
	_cortina = ColorRect.new()
	_cortina.color = Color(0.02, 0.01, 0.03, 0.0)
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(_cortina)
	var teste := false
	if "--autoteste" in OS.get_cmdline_user_args():
		var t: Node = load("res://tests/autoteste.gd").new()
		t.main = self
		add_child(t)
		teste = true
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fotos="):
			var f: Node = load("res://tests/fotos.gd").new()
			f.main = self
			add_child(f)
			teste = true
	if teste:
		_comecar("continuar" if SaveSystem.existe() else "novo")
	else:
		_abrir_tela_inicial()


## Abertura: a fazenda ao fundo, a câmera passeando, e as opções por cima.
func _abrir_tela_inicial() -> void:
	em_jogo = false
	menu.ativo = false
	GameState.nova_partida()
	_montar_mundo()
	mundo.jogador.visible = false
	mundo.jogador.parado = true
	mundo.cursor.visible = false
	mundo.atualizar_luz(10.0)
	hud.visible = false
	_inicio = TelaInicial.new()
	add_child(_inicio)
	_inicio.escolheu.connect(_comecar)


func _comecar(opcao: String) -> void:
	match opcao:
		"sair":
			get_tree().quit()
			return
		"continuar":
			if not _carregar():
				return
		_:
			GameState.nova_partida()
			_montar_mundo()
			hud.avisar("Bem-vindo à fazenda. Esc abre o menu.")
	if _inicio:
		_inicio.queue_free()
		_inicio = null
	em_jogo = true
	menu.ativo = true
	hud.visible = true


func _montar_mundo() -> void:
	if mundo:
		mundo.queue_free()
	mundo = Mundo.new()
	mundo.name = "Mundo"
	add_child(mundo)
	move_child(mundo, 0)
	mundo.montar(str(GameState.dados.jogador["mapa"]))
	mundo.jogador.position = GameState.dados.posicao()
	if mundo.bloqueada(mundo.celula_de(mundo.jogador.position)):
		# save de uma versão do mapa em que ali era livre: volta para o início
		mundo.jogador.position = Vector2(mundo.mapa.inicio) * 16.0 + Vector2(8, 8)
	mundo.atualizar_luz(float(GameState.dados.mundo["hora"]))
	mundo.desenhar_plantacao(GameState.dados)
	_acordar()
	Som.musica(mundo.mapa.musica if mundo.mapa.musica != "" else "musica_fazenda")


func _process(delta: float) -> void:
	var d: GameData = GameState.dados
	if d == null or mundo == null:
		return
	if not em_jogo:
		_passeio += delta
		mundo.jogador.position = Vector2(24.0 * 16.0 + sin(_passeio * 0.07) * 13.0 * 16.0, 13.0 * 16.0)
		return
	var cfg: Dictionary = Config.balanceamento
	d.definir_posicao(mundo.jogador.position)
	Survival.tick(d, cfg, delta, mundo.jogador.andando)
	var mult := float(cfg.get("velocidade_tempo_dormindo", 30)) if dormindo else 1.0
	avancar_tempo(24.0 * delta * mult / float(cfg.get("dia_segundos_reais", 1080)))
	mundo.cursor.mostrar(celula_alvo())
	_redesenhar_em -= delta
	if _redesenhar_em <= 0.0:
		_redesenhar_em = 0.5
		mundo.desenhar_plantacao(d)
	if not _trocando:
		var saida := mundo.mapa.saida_em(mundo.celula_de(mundo.jogador.position))
		if not saida.is_empty():
			var loja := str(saida.get("loja", ""))
			if loja != "" and not loja_aberta(loja):
				# porta trancada fora do horário: o jogador volta um passo
				mundo.jogador.position += Vector2(0, 8)
				var def: Dictionary = Config.lojas.get(loja, {})
				hud.avisar("%s está fechado. Abre às %dh." % [str(def.get("nome", loja)), int(def.get("abre", 8))], 2.0)
			else:
				trocar_mapa(str(saida["para"]), saida["chegada"], str(saida["olhar"]))
	if float(d.jogador["vida"]) <= 0.0:
		# acorda na clínica da cidade (GDD: vida zerada) e perde um pouco de dinheiro
		var id_clinica := str(cfg.get("mapa_clinica", "clinica"))
		if not FileAccess.file_exists("res://content/mapas/%s.json" % id_clinica):
			id_clinica = "fazenda"
		var clinica: MapData = Config.mapa(id_clinica)
		var inicio := Vector2(clinica.inicio) * 16.0 + Vector2(8, 8)
		var perda := Survival.desmaiar(d, cfg, inicio, clinica.id)
		if mundo.mapa.id != clinica.id:
			_montar_mundo()
		mundo.jogador.position = inicio
		_acordar()
		hud.avisar("Você desmaiou. Perdeu $ %d." % perda, 4.0)


## Passa para outro mapa (porta da casa etc.): escurece, monta o mapa novo e clareia.
func trocar_mapa(para: String, chegada: Vector2i, olhar := "") -> void:
	if _trocando:
		return
	_trocando = true
	mundo.jogador.parado = true
	var tw := create_tween()
	tw.tween_property(_cortina, "color:a", 1.0, 0.18)
	await tw.finished
	var d: GameData = GameState.dados
	d.jogador["mapa"] = para
	d.definir_posicao(Vector2(chegada) * 16.0 + Vector2(8, 8))
	_montar_mundo()
	if olhar != "":
		mundo.jogador.virar_para(olhar)
	mundo.jogador.parado = true
	var tw2 := create_tween()
	tw2.tween_property(_cortina, "color:a", 0.0, 0.25)
	await tw2.finished
	if not dormindo:
		mundo.jogador.parado = false
	_trocando = false


## Passa 'horas' de jogo: relógio, plantas e, se estiver dormindo, acorda na hora certa.
func avancar_tempo(horas: float) -> void:
	var d: GameData = GameState.dados
	var cfg: Dictionary = Config.balanceamento
	if dormindo:
		var acordar := float(cfg.get("hora_acordar", 6.0))
		var falta := fposmod(acordar - float(d.mundo["hora"]), 24.0)
		if horas >= falta:
			horas = falta
			_passar(d, cfg, horas)
			_acordar()
			hud.avisar("Bom dia!")
			return
	_passar(d, cfg, horas)


func _passar(d: GameData, cfg: Dictionary, horas: float) -> void:
	if horas <= 0.0:
		return
	var segundos := horas * float(cfg.get("dia_segundos_reais", 1080)) / 24.0
	Survival.avancar_hora(d, cfg, segundos)
	Fazenda.crescer(d, mundo.mapa.id, horas, Config.culturas, mundo.irrigadas)
	mundo.atualizar_luz(float(d.mundo["hora"]))


func _acordar() -> void:
	dormindo = false
	if mundo:
		mundo.jogador.parado = false
	hud.dormindo = false


# ---------- ações do jogador (mouse para ferramentas; D-036) ----------

func _unhandled_input(evento: InputEvent) -> void:
	if not em_jogo or GameState.dados == null or mundo == null or get_tree().paused:
		return
	for i in 10:
		if evento.is_action_pressed("barra_%d" % (i + 1)):
			selecionar(i)
	if evento.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		interagir(mundo.celula_de(mundo.jogador.position) + mundo.jogador.direcao)
		return
	if evento.is_action_pressed("diario"):
		get_viewport().set_input_as_handled()
		abrir_diario()
		return
	if evento is InputEventMouseButton and evento.pressed:
		match evento.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				selecionar(posmod(_selecionado() - 1, _tamanho_barra()))
			MOUSE_BUTTON_WHEEL_DOWN:
				selecionar(posmod(_selecionado() + 1, _tamanho_barra()))
			MOUSE_BUTTON_LEFT:
				usar(celula_alvo())
			MOUSE_BUTTON_RIGHT:
				interagir(celula_alvo())


func _tamanho_barra() -> int:
	return int(Config.balanceamento.get("slots_barra", 10))


func _selecionado() -> int:
	return int(GameState.dados.jogador["barra_selecionada"])


func selecionar(i: int) -> void:
	if i != int(GameState.dados.jogador["barra_selecionada"]):
		Som.tocar("selecionar")
	GameState.dados.jogador["barra_selecionada"] = i
	var s = GameState.dados.jogador["inventario"][i]
	if s != null:
		hud.avisar(str(Config.itens.get(s["id"], {}).get("nome", s["id"])), 1.2)


## Célula sob o mouse, se estiver ao alcance; senão, a célula à frente do jogador.
func celula_alvo() -> Vector2i:
	var pe := mundo.celula_de(mundo.jogador.position)
	var sob_mouse := mundo.celula_de(mundo.get_global_mouse_position())
	var alcance := int(Config.balanceamento.get("alcance_ferramenta_tiles", 1))
	if maxi(absi(sob_mouse.x - pe.x), absi(sob_mouse.y - pe.y)) <= alcance:
		return sob_mouse
	return pe + mundo.jogador.direcao


func _item_selecionado():
	return GameState.dados.jogador["inventario"][_selecionado()]


## Clique esquerdo: usa o item da barra na célula.
func usar(c: Vector2i) -> void:
	if dormindo:
		return
	var d: GameData = GameState.dados
	var cfg: Dictionary = Config.balanceamento
	var s = _item_selecionado()
	if s == null:
		return
	var def: Dictionary = Config.itens.get(s["id"], {})
	var mapa := mundo.mapa.id
	var feito := false
	var esquerda := c.x < mundo.celula_de(mundo.jogador.position).x or mundo.jogador.direcao.x < 0
	var icone := int(def.get("icone", 0))
	match str(s["id"]):
		"enxada":
			var tipo := mundo.mapa.tipo_em(c) if mundo.mapa.objeto_em(c).is_empty() else "objeto"
			feito = Fazenda.arar(d, mapa, c, tipo, cfg)
			Efeitos.ferramenta(mundo, c, icone, "enxada", esquerda)
			Som.tocar("enxada")
		"regador":
			if mundo.eh_agua_celula(c):
				s["agua"] = int(def.get("capacidade", 20))
				hud.avisar("Regador cheio.", 1.2)
				Efeitos.particulas(mundo, Vector2(c) * 16.0 + Vector2(8, 8), Color("#8fcbea"), 10, 45.0)
				Som.tocar("encher")
				feito = true
			elif int(s.get("agua", 0)) <= 0:
				hud.avisar("O regador está vazio. Encha na água.", 1.5)
			elif Fazenda.regar(d, mapa, c, cfg):
				s["agua"] = int(s["agua"]) - 1
				Efeitos.ferramenta(mundo, c, icone, "regador", esquerda)
				Som.tocar("regar")
				feito = true
		_:
			if str(def.get("tipo", "")) == "semente":
				if Fazenda.plantar(d, mapa, c, str(def.get("cultura", ""))):
					Inventario.remover(d.jogador["inventario"], _selecionado(), 1)
					Efeitos.particulas(mundo, Vector2(c) * 16.0 + Vector2(8, 10), Color("#61402a"), 5, 25.0)
					Som.tocar("plantar")
					feito = true
	if feito:
		mundo.jogador.olhar_para(c)
		mundo.jogador.acao()
		Survival.tick(d, {"fome_por_segundo": float(cfg.get("fome_por_uso_ferramenta", 0.3))}, 1.0, false)
		mundo.desenhar_plantacao(d)


## A loja está aberta agora? (horário em lojas.json)
func loja_aberta(id: String) -> bool:
	var def: Dictionary = Config.lojas.get(id, {})
	var h := float(GameState.dados.mundo["hora"])
	return h >= float(def.get("abre", 0)) and h < float(def.get("fecha", 24))


## Abre uma conversa dos livros (content/livros/*/dialogos.json).
func conversar(id_dialogo: String, quem := "") -> CaixaDialogo:
	var c := CaixaDialogo.new()
	add_child(c)
	c.abrir(id_dialogo, quem)
	return c


## Mostra um texto solto (placa, inscrição) na caixa de conversa.
func ler(quem: String, paginas: Array) -> CaixaDialogo:
	var c := CaixaDialogo.new()
	add_child(c)
	c.abrir_texto(quem, paginas)
	return c


func abrir_diario() -> Diario:
	Som.tocar("clique", 0.0, false)
	var j := Diario.new()
	add_child(j)
	return j


func abrir_loja(id: String) -> Loja:
	var l := Loja.new()
	add_child(l)
	l.abrir(id)
	return l


## Clique direito: fala com morador, colhe, dorme na cama ou come o item da barra.
func interagir(c: Vector2i) -> void:
	if dormindo:
		return
	var d: GameData = GameState.dados
	# morador na célula; no balcão, quem atende fica atrás dele
	var npc := mundo.mapa.npc_em(c)
	var balcao := mundo.mapa.objeto_em(c)
	if npc.is_empty() and not balcao.is_empty() and bool(Config.objetos.get(str(balcao["tipo"]), {}).get("atende_atras", false)):
		var peg: Array = Config.objetos[str(balcao["tipo"])].get("pegada", [1, 1])
		for dx in int(peg[0]):
			npc = mundo.mapa.npc_em(Vector2i(int(balcao["x"]) + dx, int(balcao["y"]) - 1))
			if not npc.is_empty():
				break
	if not npc.is_empty():
		mundo.jogador.olhar_para(c)
		var loja := str(npc.get("loja", ""))
		if loja != "":
			if loja_aberta(loja):
				Som.tocar("clique", 0.0, false)
				abrir_loja(loja)
			else:
				hud.avisar("A loja já fechou. Abre às %dh." % int(Config.lojas.get(loja, {}).get("abre", 8)), 2.0)
		elif str(npc.get("dialogo", "")) != "":
			conversar(str(npc["dialogo"]), str(npc.get("nome", "")))
		elif str(npc.get("fala", "")) != "":
			ler(str(npc.get("nome", "")), [str(npc["fala"])])
		return
	var obj := mundo.mapa.objeto_em(c)
	if obj.has("texto"):
		var paginas = obj["texto"]
		ler(str(obj.get("nome", "")), paginas if typeof(paginas) == TYPE_ARRAY else [str(paginas)])
		return
	if obj.has("dialogo"):
		conversar(str(obj["dialogo"]), str(obj.get("nome", "")))
		return
	var fechada := mundo.mapa.fechada_em(c)
	if not fechada.is_empty():
		hud.avisar(str(fechada["aviso"]), 2.0)
		return
	var colheita := Fazenda.colher(d, mundo.mapa.id, c, Config.culturas)
	if not colheita.is_empty():
		var inv: Array = d.jogador["inventario"]
		Inventario.adicionar(inv, colheita["produto"], colheita["qtd"], Config.itens)
		if int(colheita["sementes"]) > 0:
			Inventario.adicionar(inv, colheita["semente"], colheita["sementes"], Config.itens)
		hud.avisar("Colheu %d %s." % [colheita["qtd"], Config.itens[colheita["produto"]]["nome"]], 1.5)
		Efeitos.colheita(mundo, c, int(Config.itens[colheita["produto"]].get("icone", 0)))
		Som.tocar("colher")
		mundo.desenhar_plantacao(d)
		return
	if bool(Config.objetos.get(mundo.mapa.tipo_em(c), {}).get("dormir", false)):
		dormir()
		return
	var s = _item_selecionado()
	var fome_antes := float(d.jogador["fome"])
	if s != null and Fazenda.comer(d, Config.itens.get(s["id"], {}), Config.balanceamento):
		var def_comida: Dictionary = Config.itens[s["id"]]
		Inventario.remover(d.jogador["inventario"], _selecionado(), 1)
		hud.avisar("Comeu %s." % def_comida["nome"], 1.2)
		Som.tocar("comer")
		# comida simples com a fome quase zerada: o maior prazer (conquista do livro de Epicuro)
		var conq := str(def_comida.get("conquista_simples", ""))
		if conq != "" and fome_antes <= float(Config.balanceamento.get("fome_max", 100.0)) * 0.1:
			if Progresso.conquistar(d, conq):
				hud.avisar("Conquista: %s!" % str(Config.conquistas.get(conq, {}).get("nome", conq)), 3.0)
				Som.tocar("salvar", 0.0, false)


## Dormir faz a noite passar mais rápido (D-026). Só à noite (das 18h às 6h).
func dormir() -> void:
	var h := float(GameState.dados.mundo["hora"])
	if h >= 6.0 and h < 18.0:
		hud.avisar("Ainda é dia. Dá para dormir a partir das 18h.", 1.8)
		return
	dormindo = true
	Som.tocar("dormir", 0.0, false)
	mundo.jogador.parado = true
	hud.dormindo = true
	hud.avisar("Dormindo...", 2.0)


func _salvar() -> void:
	if SaveSystem.salvar(GameState.dados):
		hud.avisar("Jogo salvo.")
		Som.tocar("salvar", 0.0, false)
	else:
		hud.avisar("Não foi possível salvar.")


func _carregar() -> bool:
	var r := SaveSystem.carregar()
	if not r.get("ok", false):
		hud.avisar("Não foi possível carregar: %s" % r.get("erro", "?"))
		return false
	GameState.definir(r["dados"])
	_montar_mundo()
	hud.avisar("Partida carregada.")
	return true
