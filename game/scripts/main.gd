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
var _rng := RandomNumberGenerator.new()
var _pronto_para_golpe := 0.0
var _trocando := false        # true durante a passagem de um mapa para outro
var pesca: Pesca = null       # linha na água (D-056)
var _cortina: ColorRect       # tela preta da passagem


func _ready() -> void:
	_rng.randomize()
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
	var roteiros: Array = []
	if "--autoteste" in OS.get_cmdline_user_args():
		roteiros.append("res://tests/autoteste.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fotos="):
			roteiros.append("res://tests/fotos.gd")
	for r in roteiros:
		var scr: GDScript = load(r)
		if scr == null or not scr.can_instantiate():
			printerr("SCRIPT ERROR: roteiro de teste não compila: ", r)
			get_tree().quit(1)
			return
		var t: Node = scr.new()
		t.main = self
		add_child(t)
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
	mundo.inimigo_vencido.connect(_inimigo_vencido)
	mundo.jogador.position = GameState.dados.posicao()
	if mundo.bloqueada(mundo.celula_de(mundo.jogador.position)):
		# save de uma versão do mapa em que ali era livre: volta para o início
		mundo.jogador.position = Vector2(mundo.mapa.inicio) * 16.0 + Vector2(8, 8)
	mundo.atualizar_luz(float(GameState.dados.mundo["hora"]))
	mundo.desenhar_plantacao(GameState.dados)
	_acordar()
	Som.musica(mundo.mapa.musica if mundo.mapa.musica != "" else "musica_fazenda")
	for e in mundo.mapa.ao_entrar:
		if Dialogo.condicao(GameState.dados, e.get("se", {})):
			var dlg := str(e.get("dialogo", ""))
			get_tree().create_timer(0.6).timeout.connect(func(): if em_jogo and not dormindo: conversar(dlg))
			break


func _process(delta: float) -> void:
	var d: GameData = GameState.dados
	if d == null or mundo == null:
		return
	if pesca != null and Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo") != Vector2.ZERO:
		pesca.cancelar()
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
			if not Dialogo.condicao(d, saida.get("se", {})):
				# caminho ainda fechado (ex.: um chefe no caminho): volta um passo
				mundo.jogador.position -= Vector2(mundo.jogador.direcao) * 8.0
				if str(saida.get("aviso", "")) != "":
					hud.avisar(str(saida["aviso"]), 2.0)
			elif loja != "" and not loja_aberta(loja):
				# porta trancada fora do horário: o jogador volta um passo
				mundo.jogador.position += Vector2(0, 8)
				var def: Dictionary = Config.lojas.get(loja, {})
				hud.avisar("%s está fechado. Abre às %dh." % [str(def.get("nome", loja)), int(def.get("abre", 8))], 2.0)
			else:
				trocar_mapa(str(saida["para"]), saida["chegada"], str(saida["olhar"]))
	if float(d.jogador["vida"]) <= 0.0:
		# acorda na clínica da cidade (GDD: vida zerada) e perde um pouco de dinheiro
		var id_clinica := str(cfg.get("mapa_clinica", "clinica"))
		var onde: Dictionary = mundo.mapa.desmaio   # mapas especiais (dimensões) dizem onde acordar
		if not onde.is_empty():
			id_clinica = str(onde.get("mapa", mundo.mapa.id))
		if not FileAccess.file_exists("res://content/mapas/%s.json" % id_clinica):
			id_clinica = "fazenda"
		var clinica: MapData = Config.mapa(id_clinica)
		var inicio := Vector2(clinica.inicio) * 16.0 + Vector2(8, 8)
		if not onde.is_empty() and onde.has("x"):
			inicio = Vector2(int(onde["x"]), int(onde["y"])) * 16.0 + Vector2(8, 8)
		var perda := Survival.desmaiar(d, cfg, inicio, clinica.id)
		if mundo.mapa.id != clinica.id or not onde.is_empty():
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
	var dia_antes := int(d.mundo["dia"])
	Survival.avancar_hora(d, cfg, segundos)
	if int(d.mundo["dia"]) != dia_antes:
		_novo_dia()
	Fazenda.crescer(d, mundo.mapa.id, horas, Config.culturas, mundo.irrigadas)
	mundo.atualizar_luz(float(d.mundo["hora"]))


## Virou o dia: animais crescem e botam ovo (ver Animais).
func _novo_dia() -> void:
	if mundo == null:
		return
	Animais.novo_dia(GameState.dados, mundo.mapa.id, Config.animais, mundo.livre_para_produto)
	mundo.atualizar_animais()
	mundo.atualizar_no_chao()


func _acordar() -> void:
	dormindo = false
	if mundo:
		mundo.jogador.parado = false
	hud.dormindo = false


# ---------- ações do jogador (mouse para ferramentas; D-036) ----------

func _unhandled_input(evento: InputEvent) -> void:
	if not em_jogo or GameState.dados == null or mundo == null or get_tree().paused:
		return
	if pesca != null:
		var puxa: bool = evento.is_action_pressed("interagir") or evento.is_action_pressed("avancar") \
			or (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT)
		if puxa:
			get_viewport().set_input_as_handled()
			pesca.puxar()
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
	if evento.is_action_pressed("construir"):
		get_viewport().set_input_as_handled()
		abrir_construir()
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
	if bool(def.get("sonda", false)):
		sondar(c)
		return
	var bicho := mundo.animal_em(c)
	if bicho != null and _mexer_no_animal(bicho, s):
		return
	match str(def.get("tipo", "")):
		"animal":
			_soltar_animal(c, s, def)
			return
		"construcao":
			_construir_em(c, s, def)
			return
	if str(def.get("tipo", "")) == "arma":
		_atacar(c, def)
		return
	var acao := str(def.get("acao", ""))
	if acao == "" and str(s["id"]) in ["enxada", "regador", "vara_pesca"]:
		acao = {"enxada": "arar", "regador": "regar", "vara_pesca": "pescar"}[str(s["id"])]
	# ferramentas largas agem em 'largura' células em linha, na direção em que o jogador olha
	var celulas: Array = []
	for k in int(def.get("largura", 1)):
		celulas.append(c + mundo.jogador.direcao * k)
	match acao:
		"pescar":
			pescar(c)
			return
		"arar":
			for cel in celulas:
				var tipo := mundo.mapa.tipo_em(cel) if mundo.mapa.objeto_em(cel).is_empty() and not mundo.bloqueada(cel) else "objeto"
				if Fazenda.arar(d, mapa, cel, tipo, cfg):
					feito = true
			Efeitos.ferramenta(mundo, c, icone, "enxada", esquerda)
			Som.tocar("enxada")
		"cortar":
			Efeitos.ferramenta(mundo, c, icone, "machado", esquerda)
			Som.tocar("machado")
			feito = true
			var r := mundo.golpear(c, -1.0 if esquerda else 1.0, _rng)
			if str(r["resultado"]) == "caiu" and int(r["qtd"]) > 0:
				var sobra := Inventario.adicionar(d.jogador["inventario"], str(r["item"]), int(r["qtd"]), Config.itens)
				var nome_item := str(Config.itens.get(str(r["item"]), {}).get("nome", r["item"]))
				hud.avisar("+%d %s" % [int(r["qtd"]) - sobra, nome_item] if sobra < int(r["qtd"]) else "Inventário cheio.", 1.5)
				Som.tocar("tombar" if str(r["vira"]) != "" else "colher", -2.0)
			elif str(r["resultado"]) == "nada" and not mundo.mapa.objeto_em(c).is_empty() and Config.objetos.get(str(mundo.mapa.objeto_em(c)["tipo"]), {}).has("corte"):
				hud.avisar("Essa árvore não dá para cortar.", 1.8)
		"regar":
			if mundo.eh_agua_celula(c):
				s["agua"] = int(def.get("capacidade", 20))
				hud.avisar("Regador cheio.", 1.2)
				Efeitos.particulas(mundo, Vector2(c) * 16.0 + Vector2(8, 8), Color("#8fcbea"), 10, 45.0)
				Som.tocar("encher")
				feito = true
			elif int(s.get("agua", 0)) <= 0:
				hud.avisar("O regador está vazio. Encha na água.", 1.5)
			else:
				for cel in celulas:
					if int(s["agua"]) > 0 and Fazenda.regar(d, mapa, cel, cfg):
						s["agua"] = int(s["agua"]) - 1
						feito = true
						if cel != c:
							Efeitos.gotas(mundo, Vector2(cel) * 16.0 + Vector2(8, 4))
				if feito:
					Efeitos.ferramenta(mundo, c, icone, "regador", esquerda)
					Som.tocar("regar")
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


## Mexer num animal com o item da mão: ferramenta tira o produto (balde, tesoura), a comida preferida
## dá vontade de cria (como no Minecraft). Com 'carinho', sem nada disso, faz carinho e mostra como ele está.
## Retorna true se fez alguma coisa.
func _mexer_no_animal(bicho: Animal, s, carinho := false) -> bool:
	var d: GameData = GameState.dados
	var a: Dictionary = bicho.registro
	var def_a: Dictionary = Config.animais.get(str(a["especie"]), {})
	var nome := str(def_a.get("nome", a["especie"]))
	var id_mao := str(s["id"]) if s != null else ""
	bicho.olhar(mundo.jogador.position)
	mundo.jogador.olhar_para(bicho.celula())
	var prod: Dictionary = def_a.get("produto", {})
	if id_mao != "" and str(prod.get("ferramenta", "")) == id_mao:
		var item := Animais.tirar_produto(d, a, id_mao, Config.animais)
		if item == "":
			hud.avisar("%s: ainda não. Volte outro dia." % nome if not bool(a.get("filhote", false)) else "É só um filhote.", 1.8)
			return true
		var sobra := Inventario.adicionar(d.jogador["inventario"], item, 1, Config.itens)
		if sobra > 0:
			a["produto_dia"] = int(d.mundo["dia"]) - int(prod.get("dias", 1))
			hud.avisar("Inventário cheio.", 1.5)
			return true
		mundo.jogador.acao()
		Efeitos.colheita(mundo, bicho.celula(), int(Config.itens[item].get("icone", 0)))
		Som.tocar("colher")
		hud.avisar("Pegou: %s" % str(Config.itens[item]["nome"]), 1.2)
		bicho.atualizar_visual()
		return true
	if id_mao != "" and id_mao in def_a.get("comida", []):
		if Animais.alimentar(d, a, id_mao, Config.animais):
			Inventario.remover(d.jogador["inventario"], _selecionado(), 1)
			Efeitos.coracoes(mundo, bicho.position + Vector2(0, -14))
			Som.tocar("comer", -4.0)
			var filhote := Animais.tentar_cria(d, mundo.mapa.id)
			if not filhote.is_empty():
				mundo.atualizar_animais()
				hud.avisar("Nasceu um filhote de %s!" % nome.to_lower(), 2.5)
			else:
				hud.avisar("%s comeu e quer cria. Falta outro com vontade hoje." % nome, 2.2)
		else:
			hud.avisar("%s não quer agora." % nome if not bool(a.get("filhote", false)) else "Filhote ainda não tem cria.", 1.8)
		return true
	if not carinho:
		return false
	Efeitos.coracoes(mundo, bicho.position + Vector2(0, -14), 1)
	var estado := "filhote" if bool(a.get("filhote", false)) else "contente"
	var extra := ""
	if str(prod.get("modo", "")) == "ferramenta" and Animais.produto_pronto(d, a, Config.animais):
		extra = " %s pronto (use: %s)." % [str(Config.itens.get(str(prod["item"]), {}).get("nome", "")),
			str(Config.itens.get(str(prod["ferramenta"]), {}).get("nome", ""))]
	hud.avisar("%s (%s).%s" % [nome, estado, extra], 2.0)
	return true


func _soltar_animal(c: Vector2i, s, def: Dictionary) -> void:
	var d: GameData = GameState.dados
	if not mundo.mapa.animais:
		hud.avisar("Solte os animais na sua fazenda.", 1.8)
		return
	if not mundo.livre_para_animal(c) or mundo.celula_de(mundo.jogador.position) == c:
		hud.avisar("Não cabe aí.", 1.2)
		return
	var a := Animais.soltar(d, str(def.get("animal", s["id"])), mundo.mapa.id, c)
	Inventario.remover(d.jogador["inventario"], _selecionado(), 1)
	mundo.atualizar_animais()
	Efeitos.coracoes(mundo, Vector2(c) * 16.0 + Vector2(8, -2))
	Som.tocar("plantar")
	hud.avisar("%s solta na fazenda." % str(Config.animais.get(str(a["especie"]), {}).get("nome", "")), 1.5)


func _construir_em(c: Vector2i, s, def: Dictionary) -> void:
	var d: GameData = GameState.dados
	var livre := not mundo.bloqueada(c) and mundo.celula_de(mundo.jogador.position) != c and mundo.animal_em(c) == null
	if not Construcao.cabe(d, mundo.mapa, c, livre):
		hud.avisar("Não dá para construir aí." if mundo.mapa.animais else "Construa na sua fazenda.", 1.5)
		return
	mundo.por_construcao(c, str(def.get("objeto", s["id"])))
	Inventario.remover(d.jogador["inventario"], _selecionado(), 1)
	mundo.jogador.olhar_para(c)
	mundo.jogador.acao()
	Efeitos.particulas(mundo, Vector2(c) * 16.0 + Vector2(8, 12), Color("#c98c58"), 6, 30.0)
	Som.tocar("enxada", -6.0)


## Golpe com a arma da mão (espada) na direção do alvo; 'recarga' segundos entre golpes.
func _atacar(c: Vector2i, def: Dictionary) -> void:
	var agora := Time.get_ticks_msec() / 1000.0
	if agora < _pronto_para_golpe:
		return
	_pronto_para_golpe = agora + float(def.get("recarga", 0.4))
	var alvo := Vector2(c) * 16.0 + Vector2(8, 8)
	var dir := alvo - (mundo.jogador.position + Vector2(0, -6))
	if dir.length() < 4.0:
		dir = Vector2(mundo.jogador.direcao)
	mundo.jogador.atacar(dir, float(def.get("dano", 1)), float(def.get("alcance", 20)))
	Survival.tick(GameState.dados, {"fome_por_segundo": float(Config.balanceamento.get("fome_por_uso_ferramenta", 0.3))}, 1.0, false)


## Um inimigo virou pó: chefes únicos não voltam; aplica os efeitos do mapa ("ao_vencer") e,
## se houver, abre a conversa ("dialogo_vencer").
func _inimigo_vencido(quem: Inimigo, entrada: Dictionary) -> void:
	var d: GameData = GameState.dados
	if bool(entrada.get("unico", false)):
		Progresso.marcar(d, "venceu:" + str(entrada.get("id", quem.id)))
	var avisos := Dialogo.aplicar(d, entrada.get("ao_vencer", []), Config.itens)
	if not avisos.is_empty():
		hud.avisar("  ".join(avisos), 3.0)
	var dlg := str(entrada.get("dialogo_vencer", ""))
	if dlg != "":
		get_tree().create_timer(0.9).timeout.connect(func(): conversar(dlg))


## A loja está aberta agora? (horário em lojas.json)
func loja_aberta(id: String) -> bool:
	var def: Dictionary = Config.lojas.get(id, {})
	var h := float(GameState.dados.mundo["hora"])
	return h >= float(def.get("abre", 0)) and h < float(def.get("fecha", 24))


## Abre uma conversa dos livros (content/livros/*/dialogos.json).
func conversar(id_dialogo: String, quem := "") -> CaixaDialogo:
	var c := CaixaDialogo.new()
	add_child(c)
	c.acabou.connect(func():
		if mundo:
			mundo.atualizar_npcs()
			mundo.atualizar_depois_de_conversa())
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


func abrir_construir() -> Construir:
	Som.tocar("clique", 0.0, false)
	var c := Construir.new()
	add_child(c)
	return c


func abrir_loja(id: String) -> Loja:
	var l := Loja.new()
	add_child(l)
	l.abrir(id)
	return l


## Água ao alcance para jogar uma linha: a do mouse (até 4 células), a célula alvo ou a primeira
## água à frente (de 3 para 1). Vector2i(-999, -999) se não houver.
func agua_ao_alcance(c: Vector2i) -> Vector2i:
	var pe := mundo.celula_de(mundo.jogador.position)
	var sob_mouse := mundo.celula_de(mundo.get_global_mouse_position())
	if mundo.eh_agua_celula(sob_mouse) and maxi(absi(sob_mouse.x - pe.x), absi(sob_mouse.y - pe.y)) <= 4:
		return sob_mouse
	if mundo.eh_agua_celula(c):
		return c
	if mundo.eh_agua_celula(pe):
		return pe  # nadando: a própria célula
	for dist in [3, 2, 1]:
		var cel: Vector2i = pe + mundo.jogador.direcao * dist
		if mundo.eh_agua_celula(cel):
			return cel
	return Vector2i(-999, -999)


## Linha com pedra (livro Walden): mede a profundidade da água; no ponto mais fundo, a recompensa.
func sondar(c: Vector2i) -> void:
	var alvo := agua_ao_alcance(c)
	if alvo.x == -999:
		hud.avisar("Jogue a pedra na água.", 1.5)
		return
	mundo.jogador.olhar_para(alvo)
	mundo.jogador.acao(0.3)
	Efeitos.particulas(mundo, Vector2(alvo) * 16.0 + Vector2(8, 9), Color("#d4f0fb"), 6, 25.0)
	Som.tocar("encher", -8.0)
	var f: Dictionary = mundo.mapa.sondagem
	if f.is_empty():
		hud.avisar("A pedra bate no fundo logo, logo. É raso aqui.", 1.8)
		return
	var p: Array = f.get("ponto", [0, 0])
	var metros := mundo.mapa.profundidade(alvo)
	if alvo == Vector2i(int(p[0]), int(p[1])):
		var flag := str(f.get("flag", ""))
		if flag != "" and Progresso.tem_flag(GameState.dados, flag):
			hud.avisar("%d metros. O ponto mais fundo, de novo." % metros, 2.0)
			return
		if flag != "":
			Progresso.marcar(GameState.dados, flag)
		var avisos := Dialogo.aplicar(GameState.dados, f.get("efeitos", []), Config.itens)
		ler("", f.get("texto", ["%d metros! O ponto mais fundo." % metros]))
		hud.avisar("  ".join(avisos), 3.0)
		Som.tocar("salvar", 0.0, false)
		return
	hud.avisar("A pedra desce... %d metros." % metros, 1.8)


## Joga a linha: na célula do mouse (se for água e estiver a até 4 células) ou na primeira água
## à frente, de 3 para 1 célula de distância.
func pescar(c: Vector2i) -> void:
	if pesca != null:
		return
	var alvo := agua_ao_alcance(c)
	if alvo.x == -999:
		hud.avisar("Jogue a linha na água.", 1.5)
		return
	if mundo.eh_agua(mundo.jogador.position):
		hud.avisar("Não dá para pescar nadando.", 1.5)
		return
	mundo.jogador.olhar_para(alvo)
	mundo.jogador.acao(0.3)
	mundo.jogador.parado = true
	pesca = Pesca.new()
	mundo.add_child(pesca)
	var dirv := Vector2(mundo.jogador.direcao)
	var cabo := mundo.jogador.position + dirv * 4.0 + Vector2(0, -10)
	var mao := mundo.jogador.position + dirv * 14.0 + Vector2(0, -24)
	pesca.comecar(mao, Vector2(alvo) * 16.0 + Vector2(8, 9), mundo.mapa.peixes, float(GameState.dados.mundo["hora"]), cabo)
	pesca.acabou.connect(_fim_da_pesca)
	Survival.tick(GameState.dados, {"fome_por_segundo": float(Config.balanceamento.get("fome_por_uso_ferramenta", 0.3))}, 1.0, false)


func _fim_da_pesca(resultado: String, item: String) -> void:
	var pos := pesca.alvo if pesca else mundo.jogador.position
	pesca = null
	if not dormindo:
		mundo.jogador.parado = false
	match resultado:
		"pegou":
			if item == "":
				hud.avisar("Nada mordeu a isca.", 1.5)
				return
			var sobra := Inventario.adicionar(GameState.dados.jogador["inventario"], item, 1, Config.itens)
			if sobra > 0:
				hud.avisar("Inventário cheio: o peixe voltou para a água.", 2.0)
				return
			var def: Dictionary = Config.itens.get(item, {})
			hud.avisar("Pescou: %s!" % str(def.get("nome", item)), 2.0)
			Efeitos.colheita(mundo, mundo.celula_de(pos), int(def.get("icone", 0)))
			Som.tocar("salvar", -2.0, false)
		"cedo":
			hud.avisar("Puxou cedo demais.", 1.2)
		"escapou":
			hud.avisar("O peixe escapou...", 1.2)


## Clique direito: fala com morador, colhe, dorme na cama ou come o item da barra.
func interagir(c: Vector2i) -> void:
	if dormindo:
		return
	var d: GameData = GameState.dados
	var tonto := mundo.inimigo_para_terminar(c)
	if tonto == null:
		tonto = mundo.inimigo_para_terminar(mundo.celula_de(mundo.jogador.position))
	if tonto != null:
		mundo.jogador.olhar_para(mundo.celula_de(tonto.global_position))
		mundo.jogador.acao(0.35)
		tonto.vencer()
		return
	# morador na célula; no balcão, quem atende fica atrás dele
	var npc := mundo.mapa.npc_em(c)
	var balcao := mundo.mapa.objeto_em(c)
	if npc.is_empty() and not balcao.is_empty() and bool(Config.objetos.get(str(balcao["tipo"]), {}).get("atende_atras", false)):
		# primeiro quem está bem atrás da célula; depois qualquer um atrás do balcão
		npc = mundo.mapa.npc_em(Vector2i(c.x, int(balcao["y"]) - 1))
		var peg: Array = Config.objetos[str(balcao["tipo"])].get("pegada", [1, 1])
		for dx in int(peg[0]):
			if not npc.is_empty() and mundo.npc_visivel(npc):
				break
			npc = mundo.mapa.npc_em(Vector2i(int(balcao["x"]) + dx, int(balcao["y"]) - 1))
	if not npc.is_empty() and not mundo.npc_visivel(npc):
		npc = {}
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
	var do_chao := Animais.pegar_do_chao(d, mundo.mapa.id, c)
	if do_chao != "":
		var sobra := Inventario.adicionar(d.jogador["inventario"], do_chao, 1, Config.itens)
		if sobra > 0:
			Animais.no_chao(d, mundo.mapa.id)["%d,%d" % [c.x, c.y]] = do_chao
			hud.avisar("Inventário cheio.", 1.5)
		else:
			Efeitos.colheita(mundo, c, int(Config.itens[do_chao].get("icone", 0)))
			Som.tocar("colher")
			hud.avisar("Pegou: %s" % str(Config.itens[do_chao]["nome"]), 1.2)
		mundo.atualizar_no_chao()
		return
	var bicho := mundo.animal_em(c)
	if bicho != null:
		_mexer_no_animal(bicho, _item_selecionado(), true)
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
