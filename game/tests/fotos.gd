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
	jog.position = Vector2(8, 9) * 16.0 + Vector2(8, 8)
	await _foto("4b_noite_casa")
	d.mundo["hora"] = 10.0
	main.mundo.atualizar_luz(10.0)
	jog.position = Vector2(16, 12) * 16.0 + Vector2(8, 8)
	main.selecionar(0)
	main.usar(Vector2i(17, 12))
	await get_tree().create_timer(0.07).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta.path_join("6_enxada.png"))
	main.selecionar(1)
	main.usar(Vector2i(15, 12))
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(pasta.path_join("7_regador.png"))
	d.mundo["hora"] = 10.0
	main.mundo.atualizar_luz(10.0)
	main.menu._abrir()
	await _foto("5_menu")
	main.menu._fechar()
	main.trocar_mapa("casa", Vector2i(5, 7), "baixo")
	await get_tree().create_timer(0.8).timeout
	await _foto("9_casa_dentro")
	d.mundo["hora"] = 21.0
	main.mundo.atualizar_luz(21.0)
	await _foto("9b_casa_noite")
	d.mundo["hora"] = 10.0
	main.trocar_mapa("cidade", Vector2i(12, 12), "direita")
	await get_tree().create_timer(0.8).timeout
	main.mundo.atualizar_luz(10.0)
	await _foto("10_cidade")
	main.mundo.jogador.position = Vector2(21, 19) * 16.0 + Vector2(8, 8)
	await _foto("10b_praca")
	d.mundo["hora"] = 20.0
	main.mundo.atualizar_luz(20.0)
	main.mundo.jogador.position = Vector2(14, 12) * 16.0 + Vector2(8, 8)
	await _foto("10c_cidade_noite")
	d.mundo["hora"] = 10.0
	main.trocar_mapa("mercado", Vector2i(6, 6), "cima")
	await get_tree().create_timer(0.8).timeout
	main.mundo.atualizar_luz(10.0)
	await _foto("11_mercado")
	var loja: Loja = main.abrir_loja("mercado")
	await _foto("11b_loja")
	loja.fechar()
	main.trocar_mapa("jardim", Vector2i(12, 11), "cima")
	await get_tree().create_timer(0.8).timeout
	main.mundo.atualizar_luz(10.0)
	await _foto("12_jardim")
	var cx: CaixaDialogo = main.conversar("epicuro.dialogo.epicuro", "Epicuro")
	await get_tree().create_timer(0.6).timeout
	await _foto("12b_conversa")
	for i in 30:
		if cx._estado == "escolhas":
			break
		cx._avancar()
		await get_tree().process_frame
	await _foto("12c_escolhas")
	cx.fechar()
	var cp: CaixaDialogo = main.conversar("epicuro.dialogo.meneceu", "Meneceu")
	cp._entrar("d3")
	cp._texto.visible_characters = cp._texto.get_total_character_count()
	cp._avancar()
	await _foto("12d_pergunta")
	cp.fechar()
	var dj: Diario = main.abrir_diario()
	await _foto("12e_diario")
	dj.fechar()
	main.trocar_mapa("fazenda", Vector2i(30, 22), "direita")
	await get_tree().create_timer(0.8).timeout
	d.jogador["inventario"][9] = Inventario.novo_slot("vara_pesca", 1, Config.itens)
	main.selecionar(9)
	main.mundo.jogador.virar_para("direita")
	main.usar(Vector2i(31, 22))
	if main.pesca:
		main.pesca._espera = 99.0
		await _foto("14_pesca")
		main.pesca._mordida = main.pesca._t
		main.pesca._espera = 0.0
		await get_tree().create_timer(0.05).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(pasta.path_join("14b_mordida.png"))
		main.pesca.cancelar()
	main.trocar_mapa("colina", Vector2i(16, 9), "direita")
	await get_tree().create_timer(0.8).timeout
	main.mundo.atualizar_luz(10.0)
	await _foto("15_colina")
	main.trocar_mapa("walden", Vector2i(13, 10), "cima")
	await get_tree().create_timer(0.8).timeout
	main.mundo.atualizar_luz(10.0)
	await _foto("15b_walden_cabana")
	main.mundo.jogador.position = Vector2(27, 25) * 16.0 + Vector2(8, 8)
	await _foto("15c_walden_lago")
	main.trocar_mapa("sapataria", Vector2i(5, 6), "cima")
	await get_tree().create_timer(0.8).timeout
	main.mundo.atualizar_luz(10.0)
	await _foto("13_sapataria")
	main.trocar_mapa("cidade", Vector2i(27, 9), "cima")
	await get_tree().create_timer(0.8).timeout
	await _foto("13b_cidade_sapataria")
	main._abrir_tela_inicial()
	await get_tree().create_timer(0.5).timeout
	await _foto("8_abertura")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.ARQUIVO))
	get_tree().quit(0)
