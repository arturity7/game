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
	_teste_conteudo_dos_livros(cfg)
	_teste_mapas_ligados()
	_teste_epicuro_do_comeco_ao_fim(cfg)
	_teste_babilonia(cfg)
	_teste_tolstoi_sapataria(cfg)
	_teste_pesca()
	_teste_walden(cfg)
	_teste_seja_util(cfg)
	_teste_corte(cfg)
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
	var objetos := _defs("objetos")
	for linha in _json("res://content/mapas/fazenda.json")["legenda"].values():
		var tipo_l := str(linha).get_slice("@", 0)
		checar(tiles.has(tipo_l) or objetos.has(tipo_l), "mapa: tipo conhecido: " + str(linha))
	# com as definições de objetos: árvores, cercas e a casa ocupam células sobre a grama
	var mo := MapData.de_dict(_json("res://content/mapas/fazenda.json"), objetos)
	checar(mo.tipo_em(Vector2i(0, 0)) == "arvore" and mo.chao_em(Vector2i(0, 0)) == "grama", "mapa: árvore sobre grama")
	checar(mo.tipo_em(Vector2i(6, 5)) == "casa" and mo.ocupada(Vector2i(9, 6)), "mapa: pegada da casa")
	checar(mo.tipo_em(Vector2i(6, 3)) == "grama" and mo.tipo_em(Vector2i(7, 7)) == "caminho", "mapa: fora da pegada da casa")
	checar(mo.tipo_em(Vector2i(11, 9)) == "cerca", "mapa: cerca")
	checar(mo.tipo_em(mo.inicio) == "caminho" and not mo.ocupada(mo.inicio), "mapa: início livre")
	checar(mo.tipo_em(Vector2i(36, 23)) == "agua", "mapa: lago com objetos")
	var cfg := _json("res://content/config/balanceamento.json")
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO)
	checar(not Fazenda.arar(d, "fazenda", Vector2i(0, 0), mo.tipo_em(Vector2i(0, 0)), cfg), "mapa: não ara debaixo de árvore")
	# porta da casa: dentro da pegada, mas passável, e leva para dentro
	checar(mo.tipo_em(Vector2i(7, 6)) == "casa" and mo.porta(Vector2i(7, 6)) and not mo.ocupada(Vector2i(7, 6)), "mapa: porta da casa livre")
	checar(mo.ocupada(Vector2i(6, 6)) and mo.ocupada(Vector2i(8, 6)), "mapa: paredes ao lado da porta")
	var porta := mo.saida_em(Vector2i(7, 6))
	checar(str(porta.get("para", "")) == "casa" and porta.get("chegada") == Vector2i(5, 8), "mapa: saída da porta para dentro de casa")
	checar(mo.saida_em(Vector2i(7, 7)).is_empty(), "mapa: célula sem saída")
	# interior da casa: paredes sólidas, piso, cama e a saída de volta
	var mc := MapData.de_dict(_json("res://content/mapas/casa.json"), objetos)
	checar(mc.interior and mc.fundo == "casa.png", "casa: é interior com fundo")
	checar(bool(tiles[mc.chao_em(Vector2i(0, 0))].get("solido", false)) and mc.chao_em(Vector2i(5, 8)) == "piso", "casa: parede e piso")
	checar(mc.tipo_em(Vector2i(1, 3)) == "cama" and bool(objetos["cama"].get("dormir", false)), "casa: cama para dormir")
	checar(str(mc.saida_em(Vector2i(5, 9)).get("para", "")) == "fazenda", "casa: porta de volta à fazenda")
	checar(not mc.ocupada(mc.inicio) and mc.chao_em(mc.inicio) == "piso", "casa: chegada livre")
	checar(ResourceLoader.exists("res://assets/sprites/interiores/" + mc.fundo), "casa: arte do fundo")
	# cidade: entrada pela estrada da fazenda, mercado (com horário), clínica e ferreiro fechado
	checar(str(mo.saida_em(Vector2i(47, 16)).get("para", "")) == "cidade", "fazenda: estrada leva à cidade")
	var mcid := MapData.de_dict(_json("res://content/mapas/cidade.json"), objetos)
	checar(str(mcid.saida_em(Vector2i(0, 12)).get("para", "")) == "fazenda", "cidade: volta à fazenda")
	var porta_m := mcid.saida_em(Vector2i(7, 7))
	checar(str(porta_m.get("para", "")) == "mercado" and str(porta_m.get("loja", "")) == "mercado", "cidade: porta do mercado com horário")
	checar(str(mcid.saida_em(Vector2i(18, 7)).get("para", "")) == "clinica", "cidade: porta da clínica")
	checar(str(mcid.saida_em(Vector2i(35, 7)).get("loja", "")) == "ferreiro" and not mcid.ocupada(Vector2i(35, 7)), "cidade: porta da forja (com horário)")
	checar(mcid.chao_em(Vector2i(10, 12)) == "calcada" and not mcid.ocupada(mcid.inicio), "cidade: estrada de calçada")
	for o in mcid.objetos:
		checar(objetos.has(o["tipo"]), "cidade: objeto conhecido: " + str(o["tipo"]))
	var mm := MapData.de_dict(_json("res://content/mapas/mercado.json"), objetos)
	checar(str(mm.npc_em(Vector2i(6, 3)).get("loja", "")) == "mercado" and mm.ocupada(Vector2i(6, 3)), "mercado: vendedora no balcão")
	checar(bool(objetos[mm.tipo_em(Vector2i(6, 4))].get("atende_atras", false)), "mercado: balcão na frente dela")
	checar(str(mm.saida_em(Vector2i(6, 9)).get("para", "")) == "cidade", "mercado: porta de volta")
	var lojas := _defs("lojas")
	var cfg_l := _config()
	var itens: Dictionary = cfg_l.itens.duplicate()
	cfg_l.free()
	for id in lojas["mercado"]["vende"]:
		checar(int(itens[id].get("preco", 0)) > 0, "loja: preço de " + str(id))
	for id in lojas["mercado"]["compra"]:
		checar(int(itens[id].get("venda", 0)) > 0, "loja: compra " + str(id))
	var mcl := MapData.de_dict(_json("res://content/mapas/clinica.json"), objetos)
	checar(not mcl.ocupada(mcl.inicio) and mcl.chao_em(mcl.inicio) == "piso", "clínica: lugar para acordar")
	# a arte citada nos dados existe
	for tipo in tiles:
		if typeof(tiles[tipo]) == TYPE_DICTIONARY and tiles[tipo].has("terreno"):
			checar(ResourceLoader.exists("res://assets/sprites/terreno/" + str(tiles[tipo]["terreno"])), "arte do terreno: " + tipo)
	for tipo in objetos:
		var lista: Array = objetos[tipo].get("sprites", [])
		if objetos[tipo].has("cerca"):
			lista = [objetos[tipo]["cerca"]]
		if objetos[tipo].has("noite"):
			lista = lista + [objetos[tipo]["noite"]]
		if objetos[tipo].has("quadros"):
			lista = lista + objetos[tipo]["quadros"]
		checar(not lista.is_empty(), "objeto com arte: " + tipo)
		for s in lista:
			checar(ResourceLoader.exists("res://assets/sprites/objetos/" + str(s)), "arte do objeto: " + str(s))


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



# ---------- conteúdo dos livros ----------

func _config() -> Node:
	var c: Node = load("res://scripts/autoload/config.gd").new()
	c._ready()
	return c


## Confere todas as conversas, perguntas, itens, missões e conquistas de content/livros.
func _teste_conteudo_dos_livros(_cfg: Dictionary) -> void:
	var c := _config()
	checar(c.livros.has("epicuro"), "livros: Epicuro carregado")
	for id in c.perguntas:
		var p: Dictionary = c.perguntas[id]
		var n: int = p.get("opcoes", []).size()
		checar(n >= 2 and int(p.get("certa", 0)) < n, "pergunta com opções: " + id)
		checar(str(p.get("nivel", "")) in ["memoria", "releitura"], "pergunta com nível: " + id)
		if str(p.get("nivel", "")) == "releitura":
			checar(str(p.get("dica", "")) != "", "releitura tem dica: " + id)
		if str(p.get("peso", "simples")) == "importante":
			checar(str(p.get("punicao", "")) in ["vida", "amanha"], "importante tem punição: " + id)
		checar(str(p.get("ref", "")) != "", "pergunta com referência: " + id)
	for id in c.dialogos:
		var conv: Dictionary = c.dialogos[id]
		var nos: Dictionary = conv.get("nos", {})
		var alvos: Array = []
		for e in conv.get("inicio", []):
			alvos.append(e.get("ir", ""))
		for nid in nos:
			var no: Dictionary = nos[nid]
			for k in ["ir", "certo", "errado", "bloqueada"]:
				if no.has(k):
					alvos.append(no[k])
			for e in no.get("escolhas", []) + no.get("ramos", []):
				alvos.append(e.get("ir", ""))
			if no.has("pergunta"):
				checar(c.perguntas.has(str(no["pergunta"])), "%s: pergunta existe (%s)" % [id, no["pergunta"]])
				checar(no.has("certo") and no.has("errado"), "%s.%s: pergunta com certo e errado" % [id, nid])
			for e in no.get("efeitos", []):
				for k in ["dar_item", "tirar_item"]:
					if e.has(k):
						checar(c.itens.has(str(e[k])), "%s: item existe (%s)" % [id, e[k]])
				if e.has("missao"):
					checar(c.missoes.has(str(e["missao"])), "%s: missão existe (%s)" % [id, e["missao"]])
				if e.has("conquista"):
					checar(c.conquistas.has(str(e["conquista"])), "%s: conquista existe (%s)" % [id, e["conquista"]])
		for a in alvos:
			checar(str(a) == "fim" or nos.has(str(a)), "%s: nó existe (%s)" % [id, a])
	var n_icones: int = (load("res://assets/sprites/itens/itens.png") as Texture2D).get_width() / 16
	for id in c.itens:
		var it: Dictionary = c.itens[id]
		checar(int(it.get("icone", -1)) >= 0 and int(it.get("icone", 0)) < n_icones, "item com ícone: " + id)
		if it.has("conquista_simples"):
			checar(c.conquistas.has(str(it["conquista_simples"])), "item: conquista existe: " + id)
	c.free()


## Toda saída leva a um mapa que existe, e a chegada é uma célula livre; NPCs em células livres.
func _teste_mapas_ligados() -> void:
	var c := _config()
	var dir := DirAccess.open("res://content/mapas")
	var mapas := {}
	for f in dir.get_files():
		if f.ends_with(".json"):
			mapas[f.get_basename()] = MapData.de_dict(_json("res://content/mapas/" + f), c.objetos)
	for id in mapas:
		var m: MapData = mapas[id]
		var leg: Dictionary = _json("res://content/mapas/%s.json" % id).get("legenda", {})
		for v in leg.values():
			var tipo := str(v).get_slice("@", 0)
			checar(c.tiles.has(tipo) or c.objetos.has(tipo), "%s: tipo conhecido %s" % [id, v])
		for o in m.objetos:
			checar(c.objetos.has(str(o["tipo"])), "%s: objeto conhecido %s" % [id, o["tipo"]])
		for s in m.saidas:
			var para := str(s["para"])
			checar(mapas.has(para), "%s: saída para mapa que existe (%s)" % [id, para])
			if mapas.has(para):
				var dest: MapData = mapas[para]
				var ch: Vector2i = s["chegada"]
				var chao := dest.chao_em(ch)
				checar(chao != "" and not dest.ocupada(ch) and not bool(c.tiles.get(chao, {}).get("solido", false)),
					"%s -> %s: chegada livre %s" % [id, para, ch])
				checar(dest.saida_em(ch).is_empty(), "%s -> %s: chegada não é outra saída" % [id, para])
		for n in m.npcs:
			var cel := Vector2i(int(n["x"]), int(n["y"]))
			checar(m.chao_em(cel) != "" and m.objeto_em(cel).is_empty(), "%s: NPC em célula livre (%s)" % [id, n["id"]])
			if str(n.get("dialogo", "")) != "":
				checar(c.dialogos.has(str(n["dialogo"])), "%s: conversa do NPC existe (%s)" % [id, n["dialogo"]])
			checar(ResourceLoader.exists("res://assets/sprites/personagens/" + str(n["sprite"])), "%s: sprite do NPC (%s)" % [id, n["sprite"]])
	c.free()


## Segue uma conversa como o jogador faria: aplica efeitos, escolhe a primeira opção e acerta as
## perguntas (ou erra, se 'errar' tiver o id). Retorna os nós visitados.
func _conversar(c: Node, d: GameData, id: String, errar := "") -> Array:
	var conv: Dictionary = c.dialogos[id]
	var no_id := Dialogo.no_inicial(d, conv)
	var vistos: Array = []
	var passos := 0
	while no_id != "" and no_id != "fim" and passos < 500:
		passos += 1
		vistos.append(no_id)
		var no: Dictionary = conv["nos"][no_id]
		if no.has("ramos"):
			no_id = Dialogo.escolher_ramo(d, no["ramos"])
			continue
		Dialogo.aplicar(d, no.get("efeitos", []), c.itens)
		if no.has("pergunta"):
			var pid := str(no["pergunta"])
			if Progresso.bloqueada(d, pid):
				no_id = str(no.get("bloqueada", "fim"))
				continue
			var certa := pid != errar
			Progresso.responder(d, pid, c.perguntas[pid], certa, {})
			no_id = str(no["certo"] if certa else no["errado"])
			continue
		var esc := Dialogo.escolhas_visiveis(d, no)
		if not esc.is_empty():
			no_id = str(esc[0].get("ir", "fim"))
			continue
		no_id = str(no.get("ir", "fim"))
	return vistos


func _teste_epicuro_do_comeco_ao_fim(cfg: Dictionary) -> void:
	var c := _config()
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO, c.itens)
	var inv: Array = d.jogador["inventario"]
	_conversar(c, d, "epicuro.dialogo.meneceu")
	checar(not Progresso.tem_flag(d, "epicuro.meneceu_leu"), "epicuro: Meneceu sem carta só cumprimenta")
	_conversar(c, d, "epicuro.dialogo.epicuro")
	checar(Progresso.missao(d, "epicuro.missao.carta_meneceu") == "ativa", "epicuro: primeira missão começa")
	checar(Inventario.contar(inv, "epicuro.item.carta_meneceu") == 1 and Inventario.contar(inv, "epicuro.item.bolo_cevada") == 2, "epicuro: carta e bolos")
	_conversar(c, d, "epicuro.dialogo.epicuro")
	checar(Progresso.missao(d, "epicuro.missao.carta_meneceu") == "ativa", "epicuro: só lembra onde fica Meneceu")
	_conversar(c, d, "epicuro.dialogo.meneceu", "epicuro.pergunta.desejo_fama")
	checar(not Progresso.tem_flag(d, "epicuro.meneceu_leu") and Inventario.contar(inv, "epicuro.item.carta_meneceu") == 1, "epicuro: errar não perde a carta")
	_conversar(c, d, "epicuro.dialogo.meneceu")
	checar(Progresso.tem_flag(d, "epicuro.meneceu_leu") and Inventario.contar(inv, "epicuro.item.carta_meneceu") == 0, "epicuro: Meneceu lê a carta")
	_conversar(c, d, "epicuro.dialogo.epicuro")
	checar(Progresso.missao(d, "epicuro.missao.carta_meneceu") == "feita" and Progresso.missao(d, "epicuro.missao.carta_pitocles") == "ativa", "epicuro: segunda carta")
	_conversar(c, d, "epicuro.dialogo.pitocles")
	_conversar(c, d, "epicuro.dialogo.epicuro")
	checar(Progresso.missao(d, "epicuro.missao.carta_herodoto") == "ativa", "epicuro: terceira carta")
	_conversar(c, d, "epicuro.dialogo.herodoto")
	var vida := float(d.jogador["vida"])
	_conversar(c, d, "epicuro.dialogo.epicuro", "epicuro.pergunta.morte")
	checar(Progresso.bloqueada(d, "epicuro.pergunta.morte") and float(d.jogador["vida"]) == vida, "epicuro: errar a pergunta importante fecha até amanhã")
	var vistos := _conversar(c, d, "epicuro.dialogo.epicuro")
	checar("ainda_pensando" in vistos, "epicuro: no mesmo dia, ainda pensando")
	d.mundo["dia"] = int(d.mundo["dia"]) + 1
	_conversar(c, d, "epicuro.dialogo.epicuro")
	checar(Progresso.missao(d, "epicuro.missao.carta_herodoto") == "feita", "epicuro: as três cartas entregues")
	checar(Inventario.contar(inv, "epicuro.item.chave_alem_nevoa") == 1, "epicuro: ganha a chave de Além da Névoa")
	checar(Progresso.tem_conquista(d, "epicuro.conquista.hospede_satisfeito"), "epicuro: conquista Hóspede satisfeito")
	var antes := Inventario.contar(inv, "epicuro.item.bolo_cevada")
	vistos = _conversar(c, d, "epicuro.dialogo.epicuro")
	checar("quiz_certo" in vistos and "quiz_fim" in vistos and Inventario.contar(inv, "epicuro.item.bolo_cevada") > antes, "epicuro: perguntas livres dão bolo")
	c.free()



## Segue uma conversa escolhendo, em cada menu, a opção com o texto pedido (na ordem da lista).
func _conversar_escolhendo(c: Node, d: GameData, id: String, textos: Array) -> Array:
	var conv: Dictionary = c.dialogos[id]
	var no_id := Dialogo.no_inicial(d, conv)
	var vistos: Array = []
	var passos := 0
	while no_id != "" and no_id != "fim" and passos < 200:
		passos += 1
		vistos.append(no_id)
		var no: Dictionary = conv["nos"][no_id]
		if no.has("ramos"):
			no_id = Dialogo.escolher_ramo(d, no["ramos"])
			continue
		Dialogo.aplicar(d, no.get("efeitos", []), c.itens)
		if no.has("pergunta"):
			var pid := str(no["pergunta"])
			Progresso.responder(d, pid, c.perguntas[pid], true, {})
			no_id = str(no["certo"])
			continue
		var esc := Dialogo.escolhas_visiveis(d, no)
		if not esc.is_empty():
			var alvo := "fim"
			if not textos.is_empty():
				var quero := str(textos.pop_front())
				for e in esc:
					if str(e["texto"]).begins_with(quero):
						alvo = str(e["ir"])
			no_id = alvo
			continue
		no_id = str(no.get("ir", "fim"))
	return vistos


func _teste_babilonia(cfg: Dictionary) -> void:
	var c := _config()
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO, c.itens)
	d.jogador["dinheiro"] = 500
	_conversar_escolhendo(c, d, "babilonia.dialogo.arkad", ["Quero guardar", "Guardar $ 50", "Até logo"])
	checar(Progresso.tem_flag(d, "babilonia.decimo") and Progresso.saldo(d, "babilonia.poupanca") == 50 and int(d.jogador["dinheiro"]) == 450, "babilônia: guarda o décimo e $ 50 com Arkad")
	checar(Dialogo.texto(d, "tem $ {conta:babilonia.poupanca}") == "tem $ 50", "babilônia: texto mostra a poupança")
	var g := Progresso.guardar_decimo(d, 100)
	checar(g == 10 and Progresso.saldo(d, "babilonia.poupanca") == 60 and int(d.jogador["dinheiro"]) == 440, "babilônia: uma venda de $ 100 guarda $ 10")
	_conversar_escolhendo(c, d, "babilonia.dialogo.arkad", ["Retirar tudo", "Até logo"])
	checar(Progresso.saldo(d, "babilonia.poupanca") == 0 and int(d.jogador["dinheiro"]) == 500, "babilônia: retira tudo")
	var vistos := _conversar_escolhendo(c, d, "babilonia.dialogo.arkad", ["Me ensina", "Outra", "Voltar", "Até logo"])
	checar("licao_certa" in vistos and Progresso.saldo(d, "babilonia.poupanca") == 10, "babilônia: cada lição rende $ 5 na poupança")
	d.mundo["dia"] = int(d.mundo["dia"]) + 30
	_conversar_escolhendo(c, d, "babilonia.dialogo.arkad", ["Me ensina", "Até logo"])
	checar(Progresso.tem_conquista(d, "babilonia.conquista.uma_parte"), "babilônia: um mês guardando o décimo dá a conquista")
	var perda_sem := Survival.desmaiar(d, cfg, Vector2.ZERO, "clinica")
	d.jogador["dinheiro"] = 500
	_conversar_escolhendo(c, d, "babilonia.dialogo.mathon", ["O que é a muralha", "Quero a muralha", "Até logo"])
	checar(Progresso.tem_flag(d, "babilonia.muralha") and int(d.jogador["dinheiro"]) == 400, "babilônia: compra a muralha de Mathon")
	d.jogador["dinheiro"] = 500
	var perda_com := Survival.desmaiar(d, cfg, Vector2.ZERO, "clinica")
	checar(perda_com == perda_sem / 2, "babilônia: com a muralha, perde só metade ao desmaiar")
	c.free()



func _teste_tolstoi_sapataria(cfg: Dictionary) -> void:
	var c := _config()
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO, c.itens)
	var inv: Array = d.jogador["inventario"]
	var vistos := _conversar(c, d, "tolstoi.dialogo.michael")
	checar("calado" in vistos, "tolstói: Michael calado antes de conhecer Simon")
	_conversar(c, d, "tolstoi.dialogo.simon")
	checar(Progresso.missao(d, "tolstoi.missao.tres_sorrisos") == "ativa", "tolstói: Simon apresenta o ajudante")
	_conversar(c, d, "tolstoi.dialogo.michael", "tolstoi.pergunta.ultimo_pao")
	checar(not Progresso.tem_flag(d, "tolstoi.sorriso_1"), "tolstói: errar não faz sorrir")
	_conversar(c, d, "tolstoi.dialogo.michael")
	_conversar(c, d, "tolstoi.dialogo.michael")
	checar(Progresso.tem_flag(d, "tolstoi.sorriso_2") and not Progresso.tem_flag(d, "tolstoi.sorriso_3"), "tolstói: dois sorrisos")
	_conversar(c, d, "tolstoi.dialogo.michael")
	checar(Progresso.tem_flag(d, "tolstoi.revelacao") and Progresso.tem_conquista(d, "tolstoi.conquista.tres_sorrisos"), "tolstói: terceiro sorriso e revelação")
	var m := MapData.de_dict(_json("res://content/mapas/sapataria.json"), c.objetos)
	var michael := m.npc_em(Vector2i(7, 4))
	checar(not Dialogo.condicao(d, michael.get("se", {})), "tolstói: Michael some depois da revelação")
	_conversar(c, d, "tolstoi.dialogo.simon")
	checar(Inventario.contar(inv, "tolstoi.item.casaco_la") == 1 and Progresso.missao(d, "tolstoi.missao.tres_sorrisos") == "feita", "tolstói: Simon entrega o casaco de lã")
	c.free()



func _teste_pesca() -> void:
	var tabela := [{"item": "perca", "peso": 1}, {"item": "bagre", "peso": 1, "noite": true}]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var de_dia := {}
	var de_noite := {}
	for i in 200:
		de_dia[Peixes.sortear(tabela, 12.0, rng)] = true
		de_noite[Peixes.sortear(tabela, 22.0, rng)] = true
	checar(de_dia.has("perca") and not de_dia.has("bagre"), "pesca: de dia, só os peixes do dia")
	checar(de_noite.has("perca") and de_noite.has("bagre"), "pesca: à noite aparece o bagre")
	checar(Peixes.sortear([], 12.0, rng) == "", "pesca: sem peixes, nada")
	var c := _config()
	var dir := DirAccess.open("res://content/mapas")
	for f in dir.get_files():
		if f.ends_with(".json"):
			for p in _json("res://content/mapas/" + f).get("peixes", []):
				checar(c.itens.has(str(p["item"])), "%s: peixe existe (%s)" % [f, p["item"]])
	for id in c.lojas:
		for k in ["vende", "compra"]:
			for item in c.lojas[id].get(k, []):
				checar(c.itens.has(str(item)), "loja %s: item existe (%s)" % [id, item])
	c.free()



func _teste_walden(cfg: Dictionary) -> void:
	var c := _config()
	var m := MapData.de_dict(_json("res://content/mapas/walden.json"), c.objetos)
	var p: Array = m.sondagem["ponto"]
	var centro := Vector2i(int(p[0]), int(p[1]))
	checar(m.chao_em(centro) == "agua", "walden: o ponto mais fundo é água")
	checar(m.profundidade(centro) == 31, "walden: 31 metros no ponto mais fundo")
	checar(m.profundidade(centro + Vector2i(3, 0)) < 31 and m.profundidade(centro + Vector2i(3, 0)) > m.profundidade(centro + Vector2i(8, 0)), "walden: mais raso longe do centro")
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO, c.itens)
	_conversar_escolhendo(c, d, "walden.dialogo.thoreau", ["O lago tem fundo", "Até logo"])
	checar(Inventario.contar(d.jogador["inventario"], "walden.item.linha_sonda") == 1 and Progresso.missao(d, "walden.missao.fundo") == "ativa", "walden: Thoreau dá a linha com pedra")
	Dialogo.aplicar(d, m.sondagem["efeitos"], c.itens)
	checar(Progresso.missao(d, "walden.missao.fundo") == "feita" and Inventario.contar(d.jogador["inventario"], "walden.item.arca_ferro") == 1, "walden: achar o fundo dá a arca")
	var mc := MapData.de_dict(_json("res://content/mapas/colina.json"), c.objetos)
	checar(mc.chao_em(Vector2i(5, 14)) == "trilho" and not mc.ocupada(Vector2i(15, 14)), "colina: trilhos e passagem no caminho")
	checar(c.dialogos.has(str(mc.objeto_em(Vector2i(21, 6)).get("dialogo", ""))), "colina: o portal conversa")
	c.free()



func _teste_seja_util(cfg: Dictionary) -> void:
	var c := _config()
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO, c.itens)
	_conversar_escolhendo(c, d, "seja_util.dialogo.ferreiro", ["Me ensina", "Até logo"])
	checar(Progresso.tem_flag(d, "seja_util.ferramenta_1"), "seja útil: primeira ferramenta")
	var vistos := _conversar_escolhendo(c, d, "seja_util.dialogo.ferreiro", ["Me ensina", "Até logo"])
	checar("amanha" in vistos and not Progresso.tem_flag(d, "seja_util.ferramenta_2"), "seja útil: uma ferramenta por dia")
	for dia in 6:
		d.mundo["dia"] = int(d.mundo["dia"]) + 1
		_conversar_escolhendo(c, d, "seja_util.dialogo.ferreiro", ["Me ensina", "Até logo"])
	checar(Progresso.tem_flag(d, "seja_util.ferramenta_7") and Progresso.tem_conquista(d, "seja_util.conquista.seja_util"), "seja útil: as sete ferramentas")
	checar(Progresso.missao(d, "seja_util.missao.sete_ferramentas") == "feita", "seja útil: missão concluída")
	vistos = _conversar(c, d, "seja_util.dialogo.jornaleiro")
	checar("quiz_fim" in vistos and Progresso.tem_conquista(d, "seja_util.conquista.esponja"), "seja útil: todas as perguntas do Jornaleiro")
	c.free()


func _teste_corte(cfg: Dictionary) -> void:
	var objs := _defs("objetos")
	var itens := _defs("itens")
	var d := GameData.novo(cfg, "fazenda", Vector2.ZERO, itens)
	checar(Inventario.contar(d.jogador["inventario"], "machado") == 1, "corte: jogo novo começa com machado")
	var m := MapData.de_dict(_json("res://content/mapas/fazenda.json"), objs)
	checar(m.corte, "corte: a fazenda deixa cortar")
	var arv := Vector2i(-1, -1)
	for o in m.objetos:
		var c := Vector2i(int(o["x"]), int(o["y"]))
		if str(o["tipo"]) == "arvore" and Corte.pode(m, c, objs):
			arv = c
			break
	checar(arv != Vector2i(-1, -1), "corte: há árvore cortável na fazenda")
	checar(not Corte.pode(m, Vector2i(0, 5), objs), "corte: árvore da beira do mapa não")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var golpes := int(objs["arvore"]["corte"]["golpes"])
	for k in golpes - 1:
		checar(str(Corte.golpear(d, m, arv, objs, cfg, rng)["resultado"]) == "golpe", "corte: golpe %d só balança" % (k + 1))
	var r := Corte.golpear(d, m, arv, objs, cfg, rng)
	checar(str(r["resultado"]) == "caiu" and int(r["madeira"]) >= 3 and int(r["madeira"]) <= 5, "corte: a árvore cai e dá madeira")
	checar(m.tipo_em(arv) == "toco" and m.ocupada(arv), "corte: fica um toco no lugar")
	# recarregar o mapa: o toco continua; depois de alguns dias, rebrota
	var m2 := MapData.de_dict(_json("res://content/mapas/fazenda.json"), objs)
	Corte.aplicar(d, m2, objs, cfg)
	checar(m2.tipo_em(arv) == "toco", "corte: o toco continua ao voltar ao mapa")
	d.mundo["dia"] = int(d.mundo["dia"]) + int(cfg.get("dias_rebrotar", 6))
	var m3 := MapData.de_dict(_json("res://content/mapas/fazenda.json"), objs)
	Corte.aplicar(d, m3, objs, cfg)
	checar(m3.tipo_em(arv) == "arvore", "corte: o toco rebrota em árvore com os dias")
	# arrancar o toco libera a célula de vez
	for k in golpes:
		Corte.golpear(d, m3, arv, objs, cfg, rng)
	checar(m3.tipo_em(arv) == "toco", "corte: derrubada de novo")
	var r2 := {}
	for k in int(objs["toco"]["corte"]["golpes"]):
		r2 = Corte.golpear(d, m3, arv, objs, cfg, rng)
	checar(str(r2["resultado"]) == "caiu" and str(r2["vira"]) == "" and not m3.ocupada(arv) and m3.objeto_em(arv).is_empty(), "corte: o toco sai e a célula fica livre")
	var m4 := MapData.de_dict(_json("res://content/mapas/fazenda.json"), objs)
	d.mundo["dia"] = int(d.mundo["dia"]) + 30
	Corte.aplicar(d, m4, objs, cfg)
	checar(not m4.ocupada(arv), "corte: célula livre continua livre no save")
	var gd := GameData.from_dict(d.to_dict(2))
	checar(gd.mundo.get("arvores", {}).get("fazenda", {}).size() == 1, "corte: estado vai para o save")
	var cidade := MapData.de_dict(_json("res://content/mapas/cidade.json"), objs)
	checar(not cidade.corte, "corte: na cidade não")
