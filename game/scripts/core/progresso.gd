class_name Progresso
extends RefCounted
## Avanço do jogador nos livros, guardado em dados.progresso (vai para o save):
##   flags:      nome -> valor (true, texto ou número). Missões: "missao:<id>" -> "ativa" | "feita".
##   perguntas:  id -> {"acertou": bool, "tentativas": int, "reabre_dia": int}
##   conquistas: id -> dia em que foi ganha
## Tudo aqui é sem tela, para os testes poderem conferir.


static func flag(dados: GameData, nome: String, padrao = null):
	return dados.progresso["flags"].get(nome, padrao)


static func tem_flag(dados: GameData, nome: String) -> bool:
	var v = flag(dados, nome)
	return v != null and v != false


static func marcar(dados: GameData, nome: String, valor = true) -> void:
	dados.progresso["flags"][nome] = valor


static func desmarcar(dados: GameData, nome: String) -> void:
	dados.progresso["flags"].erase(nome)


## "nova" (nunca começou), "ativa" ou "feita".
static func missao(dados: GameData, id: String) -> String:
	return str(flag(dados, "missao:" + id, "nova"))


static func definir_missao(dados: GameData, id: String, estado: String) -> void:
	marcar(dados, "missao:" + id, estado)


static func registro(dados: GameData, id_pergunta: String) -> Dictionary:
	var p: Dictionary = dados.progresso["perguntas"]
	if not p.has(id_pergunta):
		p[id_pergunta] = {"acertou": false, "tentativas": 0}
	return p[id_pergunta]


static func acertou(dados: GameData, id_pergunta: String) -> bool:
	return bool(dados.progresso["perguntas"].get(id_pergunta, {}).get("acertou", false))


## Pergunta importante errada com punição "amanhã": fica fechada até o dia seguinte.
static func bloqueada(dados: GameData, id_pergunta: String) -> bool:
	var r: Dictionary = dados.progresso["perguntas"].get(id_pergunta, {})
	return int(r.get("reabre_dia", 0)) > int(dados.mundo["dia"])


## Registra a resposta e aplica a punição leve das perguntas importantes (D-029).
## Retorna o que aconteceu: "certo", "errado" ou "errado_vida" / "errado_amanha".
static func responder(dados: GameData, id_pergunta: String, def: Dictionary, certa: bool, cfg: Dictionary) -> String:
	var r := registro(dados, id_pergunta)
	r["tentativas"] = int(r.get("tentativas", 0)) + 1
	if certa:
		r["acertou"] = true
		r.erase("reabre_dia")
		return "certo"
	if str(def.get("peso", "simples")) != "importante":
		return "errado"
	if str(def.get("punicao", "vida")) == "amanha":
		r["reabre_dia"] = int(dados.mundo["dia"]) + 1
		return "errado_amanha"
	var dano := float(cfg.get("dano_pergunta_errada", 10.0))
	dados.jogador["vida"] = maxf(1.0, float(dados.jogador["vida"]) - dano)
	return "errado_vida"


## Dinheiro guardado com alguém (ex.: a poupança com Arkad): flag numérica "conta:<nome>".
static func saldo(dados: GameData, conta: String) -> int:
	return int(flag(dados, "conta:" + conta, 0))


static func guardar(dados: GameData, conta: String, quantia: int) -> void:
	marcar(dados, "conta:" + conta, maxi(0, saldo(dados, conta) + quantia))


## Livro da Babilônia: quem combinou com Arkad guarda um décimo de cada venda (pague-se primeiro).
## Retorna quanto foi guardado.
static func guardar_decimo(dados: GameData, valor_venda: int) -> int:
	if not tem_flag(dados, "babilonia.decimo"):
		return 0
	var parte := mini(maxi(1, valor_venda / 10), int(dados.jogador["dinheiro"]))
	dados.jogador["dinheiro"] = int(dados.jogador["dinheiro"]) - parte
	guardar(dados, "babilonia.poupanca", parte)
	return parte


## Dá a conquista; retorna true se ela é nova.
static func conquistar(dados: GameData, id: String) -> bool:
	var c: Dictionary = dados.progresso["conquistas"]
	if c.has(id):
		return false
	c[id] = int(dados.mundo["dia"])
	return true


static func tem_conquista(dados: GameData, id: String) -> bool:
	return dados.progresso["conquistas"].has(id)
