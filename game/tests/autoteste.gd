extends Node
## Teste de integração com a cena principal rodando.
## Uso: godot --path game -- --autoteste [--foto=/caminho/foto.png]
## Anda com o jogador, salva, muda o estado, carrega e confere. Sai com 0 (ok) ou 1 (falha).

var main: Node
var falhas: Array[String] = []
var foto := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--foto="):
			foto = a.substr(7)
	_rodar.call_deferred()


func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg).timeout


## Espera até a condição valer (ou o tempo acabar).
func _ate(cond: Callable, limite: float) -> void:
	var t := 0.0
	while t < limite and not cond.call():
		await get_tree().process_frame
		t += get_process_delta_time()


func checar(cond: bool, nome: String) -> void:
	if not cond:
		falhas.append(nome)
		print("FALHOU: ", nome)


func _rodar() -> void:
	await _esperar(0.3)
	var jog: Jogador = main.mundo.jogador
	var antes := jog.position
	Input.action_press("mover_direita")
	await _esperar(0.6)
	Input.action_release("mover_direita")
	checar(jog.position.x > antes.x + 10, "o jogador anda para a direita")
	# logo abaixo da casa (pegada nas linhas 4 a 6 do mapa), andando para cima: tem que parar na parede
	jog.position = Vector2(6, 8) * 16.0 + Vector2(8, 8)
	Input.action_press("mover_cima")
	await _esperar(1.0)
	Input.action_release("mover_cima")
	checar(main.mundo.tipo_em(jog.position) != "casa" and jog.position.y > 7 * 16, "a casa é sólida")
	var fome_antes := float(GameState.dados.jogador["fome"])
	await _esperar(0.5)
	checar(float(GameState.dados.jogador["fome"]) < fome_antes, "a fome cai com o tempo")
	if foto != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(foto)
	var pos_salva := jog.position
	main._salvar()
	jog.position += Vector2(64, 64)
	GameState.dados.jogador["dinheiro"] = 1
	await _esperar(0.1)
	checar(main._carregar(), "carregar o save")
	await _esperar(0.1)
	checar(main.mundo.jogador.position.distance_to(pos_salva) < 1.0, "a posição volta à salva")
	checar(int(GameState.dados.jogador["dinheiro"]) != 1, "o dinheiro volta ao salvo")
	# nadar: põe o jogador no lago e confere a velocidade menor
	var lago := Vector2(36, 23) * 16.0 + Vector2(8, 8)
	main.mundo.jogador.position = lago
	Input.action_press("mover_direita")
	await _esperar(0.3)
	checar(main.mundo.jogador.nadando, "na água o jogador nada (D-070)")
	Input.action_release("mover_direita")
	# plantação: arar, regar, plantar, crescer, colher, comer
	var d: GameData = GameState.dados
	var inv: Array = d.jogador["inventario"]
	main.mundo.jogador.position = Vector2(14, 12) * 16.0 + Vector2(8, 8)
	var alvo := Vector2i(15, 12)
	main.selecionar(0)
	main.usar(alvo)
	checar(Fazenda.canteiro(d, "fazenda", alvo) != null, "a enxada ara")
	main.selecionar(1)
	var agua_antes := int(inv[1]["agua"])
	main.usar(alvo)
	checar(int(inv[1]["agua"]) == agua_antes - 1, "o regador gasta água")
	main.selecionar(2)
	var sementes := Inventario.contar(inv, "semente_feijao")
	main.usar(alvo)
	checar(Inventario.contar(inv, "semente_feijao") == sementes - 1, "plantar gasta uma semente")
	main.avancar_tempo(20.0)
	main.selecionar(1)
	main.usar(alvo)
	main.avancar_tempo(20.0)
	main.interagir(alvo)
	checar(Inventario.contar(inv, "feijao") >= 1, "colhe o feijão")
	d.jogador["fome"] = 50.0
	for i in 10:
		if inv[i] != null and inv[i]["id"] == "feijao":
			main.selecionar(i)
	main.interagir(alvo)
	checar(float(d.jogador["fome"]) > 50.0, "comer o feijão enche a fome")
	# entrar em casa pela porta, dormir na cama e sair
	main.mundo.jogador.position = Vector2(7, 7) * 16.0 + Vector2(8, 10)
	Input.action_press("mover_cima")
	await _ate(func(): return main.mundo.mapa.id == "casa", 2.0)
	Input.action_release("mover_cima")
	await _esperar(0.6)
	checar(main.mundo.mapa.id == "casa" and str(d.jogador["mapa"]) == "casa", "entra em casa pela porta")
	checar(main.mundo.celula_de(main.mundo.jogador.position) == Vector2i(5, 8), "chega na porta, por dentro")
	d.mundo["hora"] = 21.0
	main.interagir(Vector2i(2, 4))
	checar(main.dormindo, "dorme na cama")
	main.avancar_tempo(10.0)
	checar(not main.dormindo, "acorda de manhã")
	Input.action_press("mover_baixo")
	await _ate(func(): return main.mundo.mapa.id == "fazenda", 2.0)
	Input.action_release("mover_baixo")
	await _esperar(0.6)
	checar(main.mundo.mapa.id == "fazenda" and main.mundo.celula_de(main.mundo.jogador.position) == Vector2i(7, 7), "sai de casa para a fazenda")
	# dormir à noite faz o tempo correr até as 6h
	d.mundo["hora"] = 22.0
	main.dormir()
	checar(main.dormindo, "dorme à noite")
	main.avancar_tempo(10.0)
	checar(not main.dormindo and absf(float(d.mundo["hora"]) - 6.0) < 0.01, "acorda às 6h")
	d.mundo["hora"] = 10.0
	main.dormir()
	checar(not main.dormindo, "não dorme de dia")
	# tela de abertura: abre por cima da fazenda e "Novo jogo" volta ao jogo
	main._abrir_tela_inicial()
	await _esperar(0.1)
	checar(not main.em_jogo and main._inicio != null and not main.hud.visible, "abre a tela de abertura")
	main._comecar("novo")
	await _esperar(0.1)
	checar(main.em_jogo and main.hud.visible and main.mundo.jogador.visible, "novo jogo sai da abertura")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.ARQUIVO))
	print("autoteste: %d falha(s)" % falhas.size())
	get_tree().quit(1 if falhas.size() > 0 else 0)
