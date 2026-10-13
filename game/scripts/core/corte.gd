class_name Corte
extends RefCounted
## Cortar árvores com o machado (D-030), sem tela.
## Estado em dados.mundo["arvores"][id_do_mapa]["x,y"] = {"estado": "golpeada"|"toco"|"removida",
##   "golpes": n, "dia": dia em que virou toco}.
## Regras de cada objeto em objetos.json → "corte": {"golpes", "madeira": [mín, máx], "vira": objeto que
## fica no lugar (ex.: "toco") ou "" (some)}. O toco rebrota em árvore depois de "dias_rebrotar"
## (balanceamento.json), se ninguém o arrancar. Só nos mapas com "corte": true e nunca na beira do mapa.


static func estados(dados: GameData, mapa: String) -> Dictionary:
	if not dados.mundo.has("arvores"):
		dados.mundo["arvores"] = {}
	var todos: Dictionary = dados.mundo["arvores"]
	if not todos.has(mapa):
		todos[mapa] = {}
	return todos[mapa]


## Pode cortar o objeto desta célula?
static func pode(mapa: MapData, c: Vector2i, defs: Dictionary) -> bool:
	if not mapa.corte:
		return false
	if c.x <= 0 or c.y <= 0 or c.x >= mapa.largura - 1 or c.y >= mapa.altura - 1:
		return false
	var o := mapa.objeto_em(c)
	if o.is_empty():
		return false
	return defs.get(str(o["tipo"]), {}).has("corte")


## Um golpe de machado. Retorna {"resultado": "golpe"|"caiu"|"nada", "madeira": n, "vira": tipo}.
## "caiu" = o objeto saiu do lugar (vira o "vira" ou some); a madeira é do jogador.
static func golpear(dados: GameData, mapa: MapData, c: Vector2i, defs: Dictionary, cfg: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if not pode(mapa, c, defs):
		return {"resultado": "nada", "madeira": 0, "vira": ""}
	var o := mapa.objeto_em(c)
	var regra: Dictionary = defs[str(o["tipo"])]["corte"]
	var es := estados(dados, mapa.id)
	var k := "%d,%d" % [c.x, c.y]
	var e: Dictionary = es.get(k, {"estado": "golpeada", "golpes": 0})
	# um toco que já existia guarda o estado "toco"; os golpes contam do zero para ele
	e["golpes"] = int(e.get("golpes", 0)) + 1
	if int(e["golpes"]) < int(regra.get("golpes", 3)):
		es[k] = e
		return {"resultado": "golpe", "madeira": 0, "vira": ""}
	var faixa: Array = regra.get("madeira", [1, 1])
	var madeira := rng.randi_range(int(faixa[0]), int(faixa[-1]))
	var vira := str(regra.get("vira", ""))
	if vira != "":
		es[k] = {"estado": "toco", "golpes": 0, "dia": int(dados.mundo["dia"]), "vira": vira}
		mapa.trocar_objeto(c, vira, defs)
	else:
		es[k] = {"estado": "removida"}
		mapa.remover_objeto(c)
	return {"resultado": "caiu", "madeira": madeira, "vira": vira}


## Aplica no mapa recém-carregado o que já foi cortado (e faz rebrotar os tocos velhos).
static func aplicar(dados: GameData, mapa: MapData, defs: Dictionary, cfg: Dictionary) -> void:
	if not mapa.corte:
		return
	var es := estados(dados, mapa.id)
	var dias := int(cfg.get("dias_rebrotar", 6))
	for k in es.keys():
		var e: Dictionary = es[k]
		var p := str(k).split(",")
		var c := Vector2i(int(p[0]), int(p[1]))
		match str(e.get("estado", "")):
			"toco":
				if int(dados.mundo["dia"]) - int(e.get("dia", 0)) >= dias:
					es.erase(k)   # rebrotou: a árvore do mapa volta
				else:
					mapa.trocar_objeto(c, str(e.get("vira", "toco")), defs)
			"removida":
				mapa.remover_objeto(c)
			"golpeada":
				pass
