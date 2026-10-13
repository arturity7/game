class_name Fazenda
extends RefCounted
## Regras da plantação (GDD §4.1, D-053), sem tela.
## Canteiros ficam em dados.mundo["canteiros"][id_do_mapa]["x,y"] =
##   {"molhado_ate": horas_totais, "cultura": String, "crescimento": horas, "mexido_em": horas_totais}
## Canteiro vazio em que ninguém mexe (arar, regar, plantar, colher) por "horas_voltar_grama"
## volta a ser grama (voltar_grama).


static func chave(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


static func celula_da_chave(k: String) -> Vector2i:
	var p := k.split(",")
	return Vector2i(int(p[0]), int(p[1]))


## Tempo do jogo em horas desde o começo da partida.
static func agora(dados: GameData) -> float:
	return (int(dados.mundo["dia"]) - 1) * 24.0 + float(dados.mundo["hora"])


static func canteiros(dados: GameData, mapa: String) -> Dictionary:
	var todos: Dictionary = dados.mundo["canteiros"]
	if not todos.has(mapa):
		todos[mapa] = {}
	return todos[mapa]


static func canteiro(dados: GameData, mapa: String, c: Vector2i):
	return canteiros(dados, mapa).get(chave(c))


static func arar(dados: GameData, mapa: String, c: Vector2i, tipo_chao: String, cfg: Dictionary) -> bool:
	if not (tipo_chao in cfg.get("tipos_de_chao_aravel", ["grama", "terra"])):
		return false
	var cs := canteiros(dados, mapa)
	if cs.has(chave(c)):
		return false
	cs[chave(c)] = {"molhado_ate": -1.0, "cultura": "", "crescimento": 0.0, "mexido_em": agora(dados)}
	return true


static func regar(dados: GameData, mapa: String, c: Vector2i, cfg: Dictionary) -> bool:
	var k = canteiro(dados, mapa, c)
	if k == null:
		return false
	k["molhado_ate"] = agora(dados) + float(cfg.get("horas_solo_molhado", 24))
	k["mexido_em"] = agora(dados)
	return true


static func plantar(dados: GameData, mapa: String, c: Vector2i, cultura: String) -> bool:
	var k = canteiro(dados, mapa, c)
	if k == null or str(k["cultura"]) != "":
		return false
	k["cultura"] = cultura
	k["crescimento"] = 0.0
	k["mexido_em"] = agora(dados)
	return true


static func molhado(k: Dictionary, t: float, irrigado: bool) -> bool:
	return irrigado or float(k["molhado_ate"]) > t


## Faz as plantas do mapa crescerem 'horas' horas de jogo. Só cresce o que está molhado.
## 'irrigadas' = células regadas por um lago perto (D-053).
static func crescer(dados: GameData, mapa: String, horas: float, culturas: Dictionary, irrigadas: Dictionary) -> void:
	var t := agora(dados)
	var cs := canteiros(dados, mapa)
	for k in cs:
		var cant: Dictionary = cs[k]
		var cult := str(cant["cultura"])
		if cult == "" or not culturas.has(cult):
			continue
		if not molhado(cant, t, irrigadas.has(k)):
			continue
		var total := float(culturas[cult]["horas_para_crescer"])
		cant["crescimento"] = minf(total, float(cant["crescimento"]) + horas)


## Canteiros vazios esquecidos voltam a ser grama. Retorna quantos voltaram.
## (Canteiro de save antigo, sem "mexido_em", começa a contar agora.)
static func voltar_grama(dados: GameData, mapa: String, cfg: Dictionary) -> int:
	var horas := float(cfg.get("horas_voltar_grama", 18))
	var t := agora(dados)
	var cs := canteiros(dados, mapa)
	var n := 0
	for k in cs.keys():
		var cant: Dictionary = cs[k]
		if str(cant.get("cultura", "")) != "":
			continue
		if not cant.has("mexido_em"):
			cant["mexido_em"] = t
			continue
		if t - float(cant["mexido_em"]) >= horas:
			cs.erase(k)
			n += 1
	return n


## 0 = semente, 1 = broto, 2 = crescendo, 3 = pronto. -1 se não há planta.
static func estagio(k: Dictionary, culturas: Dictionary) -> int:
	var cult := str(k.get("cultura", ""))
	if cult == "" or not culturas.has(cult):
		return -1
	var total := float(culturas[cult]["horas_para_crescer"])
	var f := float(k["crescimento"]) / total
	if f >= 1.0:
		return 3
	return mini(2, int(floor(f * 3.0)))


## Colhe se estiver pronto. Retorna {} ou {"produto", "qtd", "semente", "sementes"}.
static func colher(dados: GameData, mapa: String, c: Vector2i, culturas: Dictionary) -> Dictionary:
	var k = canteiro(dados, mapa, c)
	if k == null or estagio(k, culturas) != 3:
		return {}
	var def: Dictionary = culturas[str(k["cultura"])]
	k["cultura"] = ""
	k["crescimento"] = 0.0
	k["mexido_em"] = agora(dados)
	return {"produto": def["produto"], "qtd": int(def.get("colheita", 1)),
		"semente": def["semente"], "sementes": int(def.get("sementes_na_colheita", 0))}


static func comer(dados: GameData, item: Dictionary, cfg: Dictionary) -> bool:
	if str(item.get("tipo", "")) != "comida":
		return false
	var maximo := float(cfg.get("fome_max", 100.0))
	if float(dados.jogador["fome"]) >= maximo:
		return false
	dados.jogador["fome"] = minf(maximo, float(dados.jogador["fome"]) + float(item.get("fome", 0)))
	return true
