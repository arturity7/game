class_name SaveCodec
extends RefCounted
## Conversão entre save em texto (JSON) e GameData, com versão e migrações (tecnico.md §5).
## Sem acesso a disco: quem lê e grava arquivos é o autoload SaveSystem.

const VERSAO_ATUAL := 1

## Migrações: a chave N transforma um save da versão N para N + 1.
## Exemplo para o futuro: {1: func(d): d["jogador"]["novo_campo"] = 0; return d}
static func migracoes() -> Dictionary:
	return {}


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
