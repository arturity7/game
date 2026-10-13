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
	_teste_inventario(cfg)
	_teste_plantacao(cfg)
	_teste_migracao_v1_v2()
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
	Inventario.adicionar(d.jogador["inventario"], "semente_teste", 3, {})
	d.progresso["perguntas"]["livro_x.pergunta_01"] = {"acertou": true, "tentativas": 1}
	var r := SaveCodec.decodificar(SaveCodec.codificar(d))
	checar(r["ok"], "save ida e volta: ok")
	var g: GameData = r["dados"]
	checar(g.posicao() == Vector2(120, 136), "save: posição")
	checar(int(g.jogador["dinheiro"]) == int(cfg["dinheiro_inicial"]), "save: dinheiro")
	checar(Inventario.contar(g.jogador["inventario"], "semente_teste") == 3, "save: inventário")
	checar(g.progresso["perguntas"].has("livro_x.pergunta_01"), "save: perguntas respondidas")
	checar(int(r["migrado_de"]) == SaveCodec.VERSAO_ATUAL, "save: versão atual")


func _teste_chaves_desconhecidas() -> void:
	var texto := JSON.stringify({
		"save_version": SaveCodec.VERSAO_ATUAL,
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


func _defs(nome: String) -> Dictionary:
	var d := _json("res://content/config/%s.json" % nome)
	d.erase("_sobre")
	return d


func _teste_inventario(cfg: Dictionary) -> void:
	var itens := _defs("itens")
	var inv := Inventario.criar(cfg, itens)
	checar(inv.size() == int(cfg["slots_inventario"]), "inventário: tamanho")
	checar(Inventario.contar(inv, "enxada") == 1 and Inventario.contar(inv, "regador") == 1, "inventário: kit inicial")
	var reg_slot = inv[1]
	checar(int(reg_slot.get("agua", 0)) == int(itens["regador"]["capacidade"]), "inventário: regador começa cheio")
	var antes := Inventario.contar(inv, "semente_feijao")
	checar(Inventario.adicionar(inv, "semente_feijao", 5, itens) == 0, "inventário: empilha")
	checar(Inventario.contar(inv, "semente_feijao") == antes + 5, "inventário: conta depois de empilhar")
	checar(Inventario.adicionar(inv, "enxada", 1, itens) == 0 and Inventario.contar(inv, "enxada") == 2, "inventário: ferramenta não empilha, ocupa outro slot")
	var cheio := []
	cheio.resize(1)
	checar(Inventario.adicionar(cheio, "feijao", 150, itens) == 51, "inventário: devolve o que não cabe")
	checar(Inventario.remover(cheio, 0, 99) and cheio[0] == null, "inventário: remover tudo esvazia o slot")


func _teste_plantacao(cfg: Dictionary) -> void:
	var itens := _defs("itens")
	var culturas := _defs("culturas")
	for id in culturas:
		checar(itens.has(culturas[id]["semente"]) and itens.has(culturas[id]["produto"]), "cultura com itens: " + id)
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO, itens)
	var c := Vector2i(12, 12)
	checar(not Fazenda.arar(d, "fazenda", c, "caminho", cfg), "não ara caminho")
	checar(Fazenda.arar(d, "fazenda", c, "terra", cfg), "ara terra")
	checar(not Fazenda.arar(d, "fazenda", c, "terra", cfg), "não ara duas vezes")
	checar(Fazenda.plantar(d, "fazenda", c, "feijao"), "planta feijão")
	checar(not Fazenda.plantar(d, "fazenda", c, "cenoura"), "não planta em cima de outra planta")
	Fazenda.crescer(d, "fazenda", 10.0, culturas, {})
	checar(float(Fazenda.canteiro(d, "fazenda", c)["crescimento"]) == 0.0, "seco não cresce")
	checar(Fazenda.regar(d, "fazenda", c, cfg), "rega")
	Fazenda.crescer(d, "fazenda", 10.0, culturas, {})
	checar(float(Fazenda.canteiro(d, "fazenda", c)["crescimento"]) == 10.0, "molhado cresce")
	checar(Fazenda.colher(d, "fazenda", c, culturas).is_empty(), "não colhe antes da hora")
	Fazenda.crescer(d, "fazenda", 100.0, culturas, {Fazenda.chave(c): true})
	checar(Fazenda.estagio(Fazenda.canteiro(d, "fazenda", c), culturas) == 3, "fica pronto")
	var col := Fazenda.colher(d, "fazenda", c, culturas)
	checar(str(col.get("produto", "")) == "feijao" and int(col["qtd"]) >= 1, "colhe feijão")
	checar(str(Fazenda.canteiro(d, "fazenda", c)["cultura"]) == "", "canteiro volta a ficar vazio")
	# o solo seca depois de 'horas_solo_molhado'
	var c2 := Vector2i(13, 12)
	Fazenda.arar(d, "fazenda", c2, "grama", cfg)
	Fazenda.regar(d, "fazenda", c2, cfg)
	Survival.avancar_hora(d, cfg, float(cfg["dia_segundos_reais"]) * 1.1)
	checar(not Fazenda.molhado(Fazenda.canteiro(d, "fazenda", c2), Fazenda.agora(d), false), "o solo seca depois de um dia")
	# lago rega sozinho em volta (D-053)
	var m := MapData.de_dict(_json("res://content/mapas/fazenda.json"))
	var irr := m.celulas_irrigadas(int(cfg["distancia_irrigacao_lago"]), _json("res://content/config/tiles.json"))
	checar(irr.has("28,23") and not irr.has("20,23"), "irrigação: até 4 tiles do lago")
	# comer
	d.jogador["fome"] = 50.0
	checar(Fazenda.comer(d, itens["batata"], cfg) and float(d.jogador["fome"]) == 60.0, "comer enche a fome")
	checar(not Fazenda.comer(d, itens["enxada"], cfg), "não come ferramenta")


func _teste_migracao_v1_v2() -> void:
	var r := SaveCodec.decodificar(FileAccess.get_file_as_string("res://tests/saves/v1_exemplo.json"))
	checar(r["ok"] and int(r["migrado_de"]) == 1, "migração: v1 é reconhecido")
	var g: GameData = r["dados"]
	checar(typeof(g.jogador["inventario"]) == TYPE_ARRAY, "migração: inventário vira lista")
	checar(Inventario.contar(g.jogador["inventario"], "enxada") == 1, "migração: recebe o kit inicial")
	checar(g.mundo.has("canteiros"), "migração: ganha canteiros")
	checar(float(g.jogador["fome"]) == 72.5 and int(g.mundo["dia"]) == 3, "migração: mantém o resto do save")
