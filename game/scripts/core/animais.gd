class_name Animais
extends RefCounted
## Animais da fazenda (GDD §4, D-054), sem tela. Regras de cada espécie em content/config/animais.json.
## Estado em dados.mundo["animais"] = lista de
##   {"id", "especie", "mapa", "x", "y", "nasceu": dia, "filhote": bool,
##    "produto_dia": dia do último produto, "amor_dia": dia em que quis cria (-1), "cria_dia": dia da última cria}
## Ovos e outros produtos "no chão": dados.mundo["no_chao"][mapa]["x,y"] = id do item.


static func todos(dados: GameData) -> Array:
	if not dados.mundo.has("animais"):
		dados.mundo["animais"] = []
	return dados.mundo["animais"]


static func do_mapa(dados: GameData, mapa: String) -> Array:
	var r: Array = []
	for a in todos(dados):
		if str(a.get("mapa", "")) == mapa:
			r.append(a)
	return r


static func no_chao(dados: GameData, mapa: String) -> Dictionary:
	if not dados.mundo.has("no_chao"):
		dados.mundo["no_chao"] = {}
	var t: Dictionary = dados.mundo["no_chao"]
	if not t.has(mapa):
		t[mapa] = {}
	return t[mapa]


static func _novo_id(dados: GameData) -> int:
	var m := 0
	for a in todos(dados):
		m = maxi(m, int(a.get("id", 0)))
	return m + 1


## Solta um animal (comprado ou nascido) na célula. Retorna o registro dele.
static func soltar(dados: GameData, especie: String, mapa: String, c: Vector2i, filhote := false) -> Dictionary:
	var dia := int(dados.mundo["dia"])
	var a := {"id": _novo_id(dados), "especie": especie, "mapa": mapa, "x": c.x, "y": c.y, "nasceu": dia,
		"filhote": filhote, "produto_dia": dia, "amor_dia": -1, "cria_dia": -99}
	todos(dados).append(a)
	return a


## Passa o dia para os animais do mapa: filhotes crescem; galinhas botam ovo numa célula livre perto.
## 'livre' = Callable(Vector2i) -> bool (célula onde cabe um produto no chão).
static func novo_dia(dados: GameData, mapa: String, defs: Dictionary, livre: Callable) -> Array:
	var dia := int(dados.mundo["dia"])
	var postos: Array = []
	var chao := no_chao(dados, mapa)
	for a in do_mapa(dados, mapa):
		var def: Dictionary = defs.get(str(a["especie"]), {})
		if bool(a.get("filhote", false)) and dia - int(a.get("nasceu", dia)) >= int(def.get("dias_crescer", 3)):
			a["filhote"] = false
			a["produto_dia"] = dia - 1
		var prod: Dictionary = def.get("produto", {})
		if prod.is_empty() or bool(a.get("filhote", false)) or str(prod.get("modo", "")) != "chao":
			continue
		if dia - int(a.get("produto_dia", -99)) < int(prod.get("dias", 1)):
			continue
		var c := Vector2i(int(a["x"]), int(a["y"]))
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var p: Vector2i = c + d
			var k := "%d,%d" % [p.x, p.y]
			if not chao.has(k) and livre.call(p):
				chao[k] = str(prod["item"])
				a["produto_dia"] = dia
				postos.append(p)
				break
	return postos


## O produto tirado com ferramenta (balde, tesoura) está pronto?
static func produto_pronto(dados: GameData, a: Dictionary, defs: Dictionary) -> bool:
	var prod: Dictionary = defs.get(str(a["especie"]), {}).get("produto", {})
	if prod.is_empty() or bool(a.get("filhote", false)):
		return false
	return int(dados.mundo["dia"]) - int(a.get("produto_dia", -99)) >= int(prod.get("dias", 1))


## Usa a ferramenta no animal. Retorna o item ganho ("" se nada).
static func tirar_produto(dados: GameData, a: Dictionary, ferramenta: String, defs: Dictionary) -> String:
	var prod: Dictionary = defs.get(str(a["especie"]), {}).get("produto", {})
	if str(prod.get("modo", "")) != "ferramenta" or str(prod.get("ferramenta", "")) != ferramenta:
		return ""
	if not produto_pronto(dados, a, defs):
		return ""
	a["produto_dia"] = int(dados.mundo["dia"])
	return str(prod["item"])


## Dá a comida preferida: o animal adulto fica com vontade de cria hoje. Retorna true se aceitou.
static func alimentar(dados: GameData, a: Dictionary, item: String, defs: Dictionary) -> bool:
	var def: Dictionary = defs.get(str(a["especie"]), {})
	if not (item in def.get("comida", [])) or bool(a.get("filhote", false)):
		return false
	var dia := int(dados.mundo["dia"])
	if int(a.get("amor_dia", -1)) == dia:
		return false
	if dia - int(a.get("cria_dia", -99)) < int(def.get("dias_cria", 3)):
		return false
	a["amor_dia"] = dia
	return true


## Se dois adultos da mesma espécie estão com vontade hoje no mesmo mapa, nasce um filhote
## na célula do primeiro. Retorna o filhote ({} se não nasceu).
static func tentar_cria(dados: GameData, mapa: String) -> Dictionary:
	var dia := int(dados.mundo["dia"])
	var por_especie := {}
	for a in do_mapa(dados, mapa):
		if int(a.get("amor_dia", -1)) == dia and not bool(a.get("filhote", false)):
			var e := str(a["especie"])
			if not por_especie.has(e):
				por_especie[e] = []
			por_especie[e].append(a)
	for e in por_especie:
		var par: Array = por_especie[e]
		if par.size() < 2:
			continue
		for a in [par[0], par[1]]:
			a["amor_dia"] = -1
			a["cria_dia"] = dia
		return soltar(dados, e, mapa, Vector2i(int(par[0]["x"]), int(par[0]["y"])), true)
	return {}


## Pega o que está no chão nesta célula (ovo). Retorna o id do item ou "".
static func pegar_do_chao(dados: GameData, mapa: String, c: Vector2i) -> String:
	var chao := no_chao(dados, mapa)
	var k := "%d,%d" % [c.x, c.y]
	if not chao.has(k):
		return ""
	var item := str(chao[k])
	chao.erase(k)
	return item
