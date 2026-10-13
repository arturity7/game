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
##   flag, sem_flag, item (+ qtd), sem_item, missao + estado, acertou, nao_acertou,
##   dinheiro (tem pelo menos), conta + minimo (saldo guardado), flag_dias [flag, dias] (passaram
##   'dias' desde o dia guardado na flag), conquista, sem_conquista
## Efeitos:
##   flag (+ valor), tirar_flag, marcar_dia (guarda o dia de hoje na flag), dar_item (+ qtd),
##   tirar_item (+ qtd), dinheiro, missao + estado, conquista, vida,
##   conta + depositar/sacar (número ou "tudo"; sai/volta da carteira) ou + render (aparece na conta)
## Textos podem ter {dinheiro}, {dia} e {conta:<nome>} (trocados por Dialogo.texto)


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
			"dinheiro":
				if int(dados.jogador["dinheiro"]) < int(v):
					return false
			"conta":
				if Progresso.saldo(dados, str(v)) < int(se.get("minimo", 1)):
					return false
			"flag_dias":
				var desde = Progresso.flag(dados, str(v[0]))
				if desde == null or int(dados.mundo["dia"]) - int(desde) < int(v[1]):
					return false
			"conquista":
				if not Progresso.tem_conquista(dados, str(v)):
					return false
			"sem_conquista":
				if Progresso.tem_conquista(dados, str(v)):
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
		if e.has("marcar_dia"):
			Progresso.marcar(dados, str(e["marcar_dia"]), int(dados.mundo["dia"]))
		if e.has("conta"):
			var conta := str(e["conta"])
			if e.has("depositar"):
				var q := int(dados.jogador["dinheiro"]) if str(e["depositar"]) == "tudo" else mini(int(e["depositar"]), int(dados.jogador["dinheiro"]))
				dados.jogador["dinheiro"] = int(dados.jogador["dinheiro"]) - q
				Progresso.guardar(dados, conta, q)
			if e.has("sacar"):
				var q := Progresso.saldo(dados, conta) if str(e["sacar"]) == "tudo" else mini(int(e["sacar"]), Progresso.saldo(dados, conta))
				Progresso.guardar(dados, conta, -q)
				dados.jogador["dinheiro"] = int(dados.jogador["dinheiro"]) + q
			if e.has("render"):
				Progresso.guardar(dados, conta, int(e["render"]))
				avisos.append("+$ %d guardados" % int(e["render"]))
	return avisos


## Troca {dinheiro}, {dia} e {conta:<nome>} pelos valores atuais.
static func texto(dados: GameData, t: String) -> String:
	if not "{" in t:
		return t
	t = t.replace("{dinheiro}", str(int(dados.jogador["dinheiro"]))).replace("{dia}", str(int(dados.mundo["dia"])))
	while "{conta:" in t:
		var i := t.find("{conta:")
		var f := t.find("}", i)
		if f < 0:
			break
		var nome := t.substr(i + 7, f - i - 7)
		t = t.substr(0, i) + str(Progresso.saldo(dados, nome)) + t.substr(f + 1)
	return t


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
