class_name SaveCodec
extends RefCounted
## Conversão entre save em texto (JSON) e GameData, com versão e migrações (tecnico.md §5).
## Sem acesso a disco: quem lê e grava arquivos é o autoload SaveSystem.

const VERSAO_ATUAL := 2

## Migrações: a chave N transforma um save da versão N para N + 1.
## Exemplo para o futuro: {1: func(d): d["jogador"]["novo_campo"] = 0; return d}
static func migracoes() -> Dictionary:
	return {
		1: func(d: Dictionary) -> Dictionary: return _v1_para_v2(d),
	}


## v1 → v2 (protótipo 1): o inventário vira uma lista de slots e chegam os canteiros.
## Na v1 o inventário ainda não era usado; quem vem dela recebe o kit inicial de ferramentas
## e sementes, que antes não tinha como conseguir. Valores fixos aqui de propósito:
## uma migração nunca muda depois de publicada.
static func _v1_para_v2(d: Dictionary) -> Dictionary:
	var j: Dictionary = d.get("jogador", {})
	var antigo = j.get("inventario", {})
	var slots := []
	slots.resize(30)
	var kit := [["enxada", 1], ["regador", 1], ["semente_feijao", 10], ["semente_cenoura", 10],
		["semente_batata", 5], ["semente_milho", 5], ["cenoura", 3]]
	var i := 0
	for par in kit:
		slots[i] = {"id": par[0], "qtd": par[1]}
		if par[0] == "regador":
			slots[i]["agua"] = 20
		i += 1
	if typeof(antigo) == TYPE_DICTIONARY:
		for id in antigo:
			if i < slots.size():
				slots[i] = {"id": str(id), "qtd": int(antigo[id])}
				i += 1
	j["inventario"] = slots
	j["barra_selecionada"] = 0
	d["jogador"] = j
	var m: Dictionary = d.get("mundo", {})
	if not m.has("canteiros"):
		m["canteiros"] = {}
	d["mundo"] = m
	return d


static func codificar(dados: GameData) -> String:
	return JSON.stringify(dados.to_dict(VERSAO_ATUAL), "\t")


## Retorna {"ok": bool, "dados": GameData, "erro": String, "migrado_de": int}
static func decodificar(texto: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(texto) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"ok": false, "erro": "save ilegível"}
	var d: Dictionary = json.data
	var versao := int(d.get("save_version", 0))
	if versao < 1:
		return {"ok": false, "erro": "save sem versão"}
	if versao > VERSAO_ATUAL:
		return {"ok": false, "erro": "save de uma versão mais nova do jogo (%d)" % versao}
	var original := versao
	var lista := migracoes()
	while versao < VERSAO_ATUAL:
		var migrar: Callable = lista.get(versao, Callable())
		if migrar.is_valid():
			d = migrar.call(d)
		versao += 1
		d["save_version"] = versao
	return {"ok": true, "dados": GameData.from_dict(d), "erro": "", "migrado_de": original}
