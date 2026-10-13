extends Node2D
## Cena principal do protótipo: carrega ou cria a partida, monta o mundo e roda as regras.

var mundo: Mundo
var hud: Hud
var menu: MenuPausa
var dormindo := false
var _redesenhar_em := 0.0


func _ready() -> void:
	hud = Hud.new()
	add_child(hud)
	menu = MenuPausa.new()
	add_child(menu)
	menu.pediu_salvar.connect(_salvar)
	menu.pediu_carregar.connect(_carregar)
	if "--autoteste" in OS.get_cmdline_user_args():
		var t: Node = load("res://tests/autoteste.gd").new()
		t.main = self
		add_child(t)
	if SaveSystem.existe() and _carregar():
		pass
	else:
		GameState.nova_partida()
		_montar_mundo()
		hud.avisar("Bem-vindo à fazenda. Esc abre o menu.")


func _montar_mundo() -> void:
	if mundo:
		mundo.queue_free()
	mundo = Mundo.new()
	mundo.name = "Mundo"
	add_child(mundo)
	move_child(mundo, 0)
	mundo.montar(str(GameState.dados.jogador["mapa"]))
	mundo.jogador.position = GameState.dados.posicao()
	mundo.atualizar_luz(float(GameState.dados.mundo["hora"]))
	mundo.desenhar_plantacao(GameState.dados)
	_acordar()


func _process(delta: float) -> void:
	var d: GameData = GameState.dados
	if d == null or mundo == null:
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
	if float(d.jogador["vida"]) <= 0.0:
		var inicio := Vector2(mundo.mapa.inicio) * 16.0 + Vector2(8, 8)
		var perda := Survival.desmaiar(d, cfg, inicio, mundo.mapa.id)
		mundo.jogador.position = inicio
		_acordar()
		hud.avisar("Você desmaiou. Perdeu $ %d." % perda, 4.0)


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
	if GameState.dados == null or mundo == null or get_tree().paused:
		return
	for i in 10:
		if evento.is_action_pressed("barra_%d" % (i + 1)):
			selecionar(i)
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
	match str(s["id"]):
		"enxada":
			feito = Fazenda.arar(d, mapa, c, mundo.mapa.tipo_em(c), cfg)
		"regador":
			if mundo.eh_agua_celula(c):
				s["agua"] = int(def.get("capacidade", 20))
				hud.avisar("Regador cheio.", 1.2)
				feito = true
			elif int(s.get("agua", 0)) <= 0:
				hud.avisar("O regador está vazio. Encha na água.", 1.5)
			elif Fazenda.regar(d, mapa, c, cfg):
				s["agua"] = int(s["agua"]) - 1
				feito = true
		_:
			if str(def.get("tipo", "")) == "semente":
				if Fazenda.plantar(d, mapa, c, str(def.get("cultura", ""))):
					Inventario.remover(d.jogador["inventario"], _selecionado(), 1)
					feito = true
	if feito:
		Survival.tick(d, {"fome_por_segundo": float(cfg.get("fome_por_uso_ferramenta", 0.3))}, 1.0, false)
		mundo.desenhar_plantacao(d)


## Clique direito: colhe, dorme na casa ou come o item da barra.
func interagir(c: Vector2i) -> void:
	if dormindo:
		return
	var d: GameData = GameState.dados
	var colheita := Fazenda.colher(d, mundo.mapa.id, c, Config.culturas)
	if not colheita.is_empty():
		var inv: Array = d.jogador["inventario"]
		Inventario.adicionar(inv, colheita["produto"], colheita["qtd"], Config.itens)
		if int(colheita["sementes"]) > 0:
			Inventario.adicionar(inv, colheita["semente"], colheita["sementes"], Config.itens)
		hud.avisar("Colheu %d %s." % [colheita["qtd"], Config.itens[colheita["produto"]]["nome"]], 1.5)
		mundo.desenhar_plantacao(d)
		return
	if mundo.mapa.tipo_em(c) == "casa":
		dormir()
		return
	var s = _item_selecionado()
	if s != null and Fazenda.comer(d, Config.itens.get(s["id"], {}), Config.balanceamento):
		Inventario.remover(d.jogador["inventario"], _selecionado(), 1)
		hud.avisar("Comeu %s." % Config.itens[s["id"]]["nome"], 1.2)


## Dormir faz a noite passar mais rápido (D-026). Só à noite (das 18h às 6h).
func dormir() -> void:
	var h := float(GameState.dados.mundo["hora"])
	if h >= 6.0 and h < 18.0:
		hud.avisar("Ainda é dia. Dá para dormir a partir das 18h.", 1.8)
		return
	dormindo = true
	mundo.jogador.parado = true
	hud.dormindo = true
	hud.avisar("Dormindo...", 2.0)


func _salvar() -> void:
	if SaveSystem.salvar(GameState.dados):
		hud.avisar("Jogo salvo.")
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
