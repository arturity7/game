class_name Dialogo
extends RefCounted
## Conversas e perguntas dos livros, lidas de content/livros/<livro>/dialogos.json (sem tela).
##
## Uma conversa:
##   {"quem": "Nome", "inicio": [{"se": {...}, "ir": "no"}, ..., {"ir": "no"}],
##    "nos": {"no": {...}}}
## Um nó pode ter:
##   "quem"      quem fala (senão, o "quem" da conversa)
##   "fala"      texto ou lista de textos (uma página cada)
##   "efeitos"   lista de efeitos aplicados quando o nó aparece
##   "escolhas"  [{"texto", "ir", "se"}] — só aparecem as que passam no "se"
##   "pergunta"  id em perguntas.json; "certo" e "errado" = nós seguintes; "bloqueada" = nó se
##               a pergunta estiver fechada até amanhã
##   "ramos"     [{"se", "ir"}] — vai direto para o primeiro ramo cuja condição vale (sem mostrar nada)
##   "ir"        próximo nó (sem escolhas); "fim" ou ausente = acaba
## Condições ("se", todas precisam valer):
##   flag, sem_flag, item (+ qtd), sem_item, missao + estado, acertou, nao_acertou
## Efeitos:
##   flag, tirar_flag, dar_item (+ qtd), tirar_item (+ qtd), dinheiro, missao + estado, conquista, vida


static func condicao(dados: GameData, se: Dictionary) -> bool:
	var inv: Array = dados.jogador["inventario"]
	for k in se:
		var v = se[k]
		match k:
			"flag":
				if not Progresso.tem_flag(dados, str(v)):
					return false
			"sem_flag":
				if Progresso.tem_flag(dados, str(v)):
					return false
			"item":
				if Inventario.contar(inv, str(v)) < int(se.get("qtd", 1)):
					return false
			"sem_item":
				if Inventario.contar(inv, str(v)) > 0:
					return false
			"missao":
				if Progresso.missao(dados, str(v)) != str(se.get("estado", "ativa")):
					return false
			"acertou":
				if not Progresso.acertou(dados, str(v)):
					return false
			"nao_acertou":
				if Progresso.acertou(dados, str(v)):
					return false
	return true


## Aplica os efeitos; retorna avisos curtos para a tela (ex.: "Recebeu: Carta").
static func aplicar(dados: GameData, efeitos: Array, itens: Dictionary) -> Array:
	var avisos: Array = []
	var inv: Array = dados.jogador["inventario"]
	for e in efeitos:
		if e.has("flag"):
			Progresso.marcar(dados, str(e["flag"]), e.get("valor", true))
		if e.has("tirar_flag"):
			Progresso.desmarcar(dados, str(e["tirar_flag"]))
		if e.has("dar_item"):
			var id := str(e["dar_item"])
			var qtd := int(e.get("qtd", 1))
			var sobra := Inventario.adicionar(inv, id, qtd, itens)
			if qtd - sobra > 0:
				avisos.append("Recebeu: %s%s" % [str(itens.get(id, {}).get("nome", id)), " x%d" % (qtd - sobra) if qtd - sobra > 1 else ""])
			if sobra > 0:
				avisos.append("Inventário cheio.")
		if e.has("tirar_item"):
			var id := str(e["tirar_item"])
			var falta := int(e.get("qtd", 1))
			for i in inv.size():
				while falta > 0 and inv[i] != null and str(inv[i]["id"]) == id:
					Inventario.remover(inv, i, 1)
					falta -= 1
			avisos.append("Entregou: %s" % str(itens.get(id, {}).get("nome", id)))
		if e.has("dinheiro"):
			dados.jogador["dinheiro"] = maxi(0, int(dados.jogador["dinheiro"]) + int(e["dinheiro"]))
			avisos.append("%s$ %d" % ["+" if int(e["dinheiro"]) >= 0 else "-", absi(int(e["dinheiro"]))])
		if e.has("missao"):
			var antes := Progresso.missao(dados, str(e["missao"]))
			var estado := str(e.get("estado", "ativa"))
			Progresso.definir_missao(dados, str(e["missao"]), estado)
			if antes != estado:
				avisos.append("Missão nova no diário." if estado == "ativa" else "Missão concluída!")
		if e.has("conquista"):
			if Progresso.conquistar(dados, str(e["conquista"])):
				avisos.append("Conquista!")
		if e.has("vida"):
			dados.jogador["vida"] = clampf(float(dados.jogador["vida"]) + float(e["vida"]), 1.0, 100.0)
	return avisos


## Primeiro ramo cuja condição vale ("" se nenhum).
static func escolher_ramo(dados: GameData, ramos: Array) -> String:
	for r in ramos:
		if condicao(dados, r.get("se", {})):
			return str(r.get("ir", ""))
	return ""


## Primeiro nó da conversa: a primeira entrada de "inicio" cuja condição vale.
static func no_inicial(dados: GameData, conversa: Dictionary) -> String:
	var ini = conversa.get("inicio", "")
	if typeof(ini) == TYPE_STRING:
		return ini
	for entrada in ini:
		if condicao(dados, entrada.get("se", {})):
			return str(entrada.get("ir", ""))
	return ""


static func escolhas_visiveis(dados: GameData, no: Dictionary) -> Array:
	var r: Array = []
	for e in no.get("escolhas", []):
		if condicao(dados, e.get("se", {})):
			r.append(e)
	return r


## Páginas de fala do nó (sempre uma lista).
static func paginas(no: Dictionary) -> Array:
	var f = no.get("fala", [])
	if typeof(f) == TYPE_STRING:
		return [f]
	return f


## Prepara uma pergunta para mostrar: opções embaralhadas (a não ser que "embaralhar" seja false).
## Retorna {"texto", "opcoes": [...], "certa": índice, "dica": texto ou ""}.
static func preparar_pergunta(def: Dictionary, semente := -1) -> Dictionary:
	var opcoes: Array = def.get("opcoes", []).duplicate()
	var ordem: Array = range(opcoes.size())
	if bool(def.get("embaralhar", true)):
		var rng := RandomNumberGenerator.new()
		if semente >= 0:
			rng.seed = semente
		else:
			rng.randomize()
		for i in range(ordem.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = ordem[i]
			ordem[i] = ordem[j]
			ordem[j] = t
	var mostradas: Array = []
	var certa := 0
	for k in ordem.size():
		mostradas.append(opcoes[ordem[k]])
		if int(ordem[k]) == int(def.get("certa", 0)):
			certa = k
	var dica := ""
	if str(def.get("nivel", "memoria")) == "releitura":
		dica = str(def.get("dica", ""))
	return {"texto": str(def.get("texto", "")), "opcoes": mostradas, "certa": certa, "dica": dica}
