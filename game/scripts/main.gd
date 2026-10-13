extends Node2D
## Cena principal do protótipo: carrega ou cria a partida, monta o mundo e roda as regras.

var mundo: Mundo
var hud: Hud
var menu: MenuPausa


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


func _process(delta: float) -> void:
	var d: GameData = GameState.dados
	if d == null or mundo == null:
		return
	var cfg: Dictionary = Config.balanceamento
	d.definir_posicao(mundo.jogador.position)
	Survival.tick(d, cfg, delta, mundo.jogador.andando)
	Survival.avancar_hora(d, cfg, delta)
	mundo.atualizar_luz(float(d.mundo["hora"]))
	if float(d.jogador["vida"]) <= 0.0:
		var inicio := Vector2(mundo.mapa.inicio) * 16.0 + Vector2(8, 8)
		var perda := Survival.desmaiar(d, cfg, inicio, mundo.mapa.id)
		mundo.jogador.position = inicio
		hud.avisar("Você desmaiou. Perdeu $ %d." % perda, 4.0)


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
