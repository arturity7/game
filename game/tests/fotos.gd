extends Node
## Tira fotos da cena para conferir a arte. Uso: godot --path game -- --fotos=/pasta
## (não é teste: só gera PNGs em 480x270).

var main: Node
var pasta := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fotos="):
			pasta = a.substr(8)
	_rodar.call_deferred()


func _foto(nome: String) -> void:
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta.path_join(nome + ".png"))


func _rodar() -> void:
	await get_tree().create_timer(0.4).timeout
	var d: GameData = GameState.dados
	var jog: Jogador = main.mundo.jogador
	d.mundo["hora"] = 10.0
	main.mundo.atualizar_luz(10.0)
	jog.position = Vector2(7, 8) * 16.0 + Vector2(8, 10)
	main.hud.avisar("Bem-vindo à fazenda. Esc abre o menu.", 10.0)
	await _foto("1_casa")
	# plantação com todos os estágios
	var cs := Fazenda.canteiros(d, "fazenda")
	var culturas := ["feijao", "cenoura", "batata", "milho"]
	for y in range(10, 15):
		for x in range(12, 24):
			if (x + y) % 7 == 0:
				continue
			var cult: String = culturas[(y - 10) % 4]
			var est := (x - 12) % 5
			var horas := float(Config.culturas[cult]["horas_para_crescer"])
			cs["%d,%d" % [x, y]] = {"molhado_ate": 9999.0 if x < 18 else -1.0,
				"cultura": "" if est == 4 else cult, "crescimento": horas * [0.0, 0.34, 0.67, 1.0, 0.0][est]}
	main.mundo.desenhar_plantacao(d)
	jog.position = Vector2(17, 16) * 16.0 + Vector2(8, 8)
	jog._lado = "cima"
	await _foto("2_plantacao")
	jog.position = Vector2(35, 23) * 16.0 + Vector2(8, 8)
	Input.action_press("mover_direita")
	await _foto("3_lago")
	Input.action_release("mover_direita")
	jog.position = Vector2(26, 12) * 16.0 + Vector2(8, 8)
	d.mundo["hora"] = 20.5
	main.mundo.atualizar_luz(20.5)
	await _foto("4_noite")
	d.mundo["hora"] = 10.0
	main.mundo.atualizar_luz(10.0)
	main.menu._abrir()
	await _foto("5_menu")
	main.menu._fechar()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.ARQUIVO))
	get_tree().quit(0)
