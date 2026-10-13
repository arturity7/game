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
	# logo abaixo da casa (linhas 3 a 6 do mapa), andando para cima: tem que parar na parede
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
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.ARQUIVO))
	print("autoteste: %d falha(s)" % falhas.size())
	get_tree().quit(1 if falhas.size() > 0 else 0)
