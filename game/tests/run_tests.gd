extends SceneTree
## Testes automáticos sem tela.
## Uso: godot --headless --path game --script res://tests/run_tests.gd
## Sai com código 0 se tudo passar e 1 se algo falhar.

var falhas := 0
var total := 0


func _init() -> void:
	var cfg := _json("res://content/config/balanceamento.json")
	_teste_save_ida_e_volta(cfg)
	_teste_chaves_desconhecidas()
	_teste_saves_invalidos()
	_teste_saves_antigos_do_repositorio()
	_teste_fome_e_vida(cfg)
	_teste_relogio(cfg)
	_teste_desmaio(cfg)
	_teste_mapa_fazenda()
	print("\n%d verificações, %d falha(s)" % [total, falhas])
	quit(1 if falhas > 0 else 0)


func checar(cond: bool, nome: String) -> void:
	total += 1
	if not cond:
		falhas += 1
		print("FALHOU: ", nome)


func _json(caminho: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(caminho))


func _teste_save_ida_e_volta(cfg: Dictionary) -> void:
	var d := GameData.novo(cfg, "fazenda", Vector2(120, 136))
	d.jogador["inventario"]["semente_teste"] = 3
	d.progresso["perguntas"]["livro_x.pergunta_01"] = {"acertou": true, "tentativas": 1}
	var r := SaveCodec.decodificar(SaveCodec.codificar(d))
	checar(r["ok"], "save ida e volta: ok")
	var g: GameData = r["dados"]
	checar(g.posicao() == Vector2(120, 136), "save: posição")
	checar(int(g.jogador["dinheiro"]) == int(cfg["dinheiro_inicial"]), "save: dinheiro")
	checar(int(g.jogador["inventario"]["semente_teste"]) == 3, "save: inventário")
	checar(g.progresso["perguntas"].has("livro_x.pergunta_01"), "save: perguntas respondidas")
	checar(int(r["migrado_de"]) == SaveCodec.VERSAO_ATUAL, "save: versão atual")


func _teste_chaves_desconhecidas() -> void:
	var texto := JSON.stringify({
		"save_version": 1,
		"jogador": {"fome": 50.0, "campo_do_futuro": 7},
		"sistema_do_futuro": {"a": 1},
	})
	var r := SaveCodec.decodificar(texto)
	checar(r["ok"], "desconhecidas: ok")
	var g: GameData = r["dados"]
	checar(float(g.jogador["vida"]) == 100.0, "desconhecidas: campo que falta recebe o padrão")
	var de_novo: Dictionary = JSON.parse_string(SaveCodec.codificar(g))
	checar(de_novo.has("sistema_do_futuro"), "desconhecidas: chave de topo preservada")
	checar(int(de_novo["jogador"].get("campo_do_futuro", 0)) == 7, "desconhecidas: campo interno preservado")


func _teste_saves_invalidos() -> void:
	checar(not SaveCodec.decodificar("isso não é json")["ok"], "inválido: texto qualquer")
	checar(not SaveCodec.decodificar("{}")["ok"], "inválido: sem versão")
	var futuro := JSON.stringify({"save_version": SaveCodec.VERSAO_ATUAL + 1})
	checar(not SaveCodec.decodificar(futuro)["ok"], "inválido: versão mais nova é recusada")


## Todo save guardado em tests/saves/ precisa continuar abrindo (tecnico.md §5).
func _teste_saves_antigos_do_repositorio() -> void:
	var pasta := DirAccess.open("res://tests/saves")
	var n := 0
	for nome in pasta.get_files():
		if not nome.ends_with(".json"):
			continue
		n += 1
		var r := SaveCodec.decodificar(FileAccess.get_file_as_string("res://tests/saves/" + nome))
		checar(r["ok"], "save antigo abre: " + nome)
	checar(n > 0, "existe pelo menos um save antigo de teste")


func _teste_fome_e_vida(cfg: Dictionary) -> void:
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO)
	Survival.tick(d, cfg, 10.0, false)
	var parado := 100.0 - float(d.jogador["fome"])
	checar(parado > 0.0, "fome cai com o tempo")
	var e := GameData.novo(cfg, "fazenda", Vector2.ZERO)
	Survival.tick(e, cfg, 10.0, true)
	checar(100.0 - float(e.jogador["fome"]) > parado, "esforço acelera a fome")
	checar(float(d.jogador["vida"]) == 100.0, "com fome, a vida não cai")
	d.jogador["fome"] = 0.0
	Survival.tick(d, cfg, 10.0, false)
	checar(float(d.jogador["vida"]) < 100.0, "sem fome, a vida cai aos poucos")


func _teste_relogio(cfg: Dictionary) -> void:
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO)
	var seg := float(cfg["dia_segundos_reais"])
	checar(seg >= 900.0 and seg <= 1200.0, "um dia dura entre 15 e 20 minutos")
	Survival.avancar_hora(d, cfg, seg)
	checar(int(d.mundo["dia"]) == 2, "um dia inteiro avança a contagem interna")
	checar(absf(float(d.mundo["hora"]) - float(cfg["hora_inicio_dia"])) < 0.01, "volta à mesma hora")
	checar(Survival.texto_hora(6.5) == "06:30", "texto da hora")


func _teste_desmaio(cfg: Dictionary) -> void:
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO)
	d.jogador["dinheiro"] = 1000
	d.jogador["vida"] = 0.0
	var perda := Survival.desmaiar(d, cfg, Vector2(5, 5), "fazenda")
	checar(perda == 100, "desmaio: perde a porcentagem configurada")
	checar(float(d.jogador["vida"]) > 0.0, "desmaio: acorda com vida")
	checar(d.posicao() == Vector2(5, 5), "desmaio: acorda no lugar da clínica")


func _teste_mapa_fazenda() -> void:
	var m := MapData.de_dict(_json("res://content/mapas/fazenda.json"))
	checar(m.largura == 48 and m.altura == 30, "mapa: tamanho")
	checar(m.tipo_em(m.inicio) == "caminho", "mapa: início num caminho")
	checar(m.tipo_em(Vector2i(36, 23)) == "agua", "mapa: lago")
	checar(m.tipo_em(Vector2i(-1, 0)) == "", "mapa: fora do mapa")
	var tiles := _json("res://content/config/tiles.json")
	for linha in _json("res://content/mapas/fazenda.json")["legenda"].values():
		checar(tiles.has(linha), "mapa: tipo de chão conhecido: " + str(linha))
