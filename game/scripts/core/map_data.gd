class_name MapData
extends RefCounted
## Mapa vindo de content/mapas/<id>.json: uma grade de caracteres com legenda.
## Cada caractere vira um tipo de chão (tiles.json) ou um objeto (objetos.json) sobre grama.
## Objetos maiores que uma célula (a casa) vêm na lista "objetos".

var id := ""
var nome := ""
var largura := 0
var altura := 0
var inicio := Vector2i.ZERO
var objetos: Array = []   # [{"tipo", "x", "y"}] — x, y = canto de cima à esquerda da pegada
var saidas: Array = []    # [{"x", "y", "para", "chegada": Vector2i, "olhar"}]
var fundo := ""           # interiores: imagem do cômodo em assets/sprites/interiores/
var interior := false
var musica := ""
var npcs: Array = []      # [{"id", "sprite", "x", "y", "olhar", "loja", "fala"}] — moradores parados
var fechadas: Array = []  # [{"x", "y", "aviso"}] — portas trancadas (botão direito mostra o aviso)
var noite := ""           # interiores: imagem por cima à noite (janelas escuras)
var luzes: Array = []     # interiores: pontos (em pixels) que acendem à noite
var _grade: Array = []    # Array[Array[String]] de tipos de chão
var _ocupado := {}        # "x,y" -> tipo do objeto que ocupa a célula
var _livre := {}          # "x,y" -> true: célula de porta (dentro de uma pegada, mas passável)


static func de_dict(d: Dictionary, defs_objetos := {}) -> MapData:
	var m := MapData.new()
	m.id = str(d.get("id", ""))
	m.nome = str(d.get("nome", m.id))
	m.fundo = str(d.get("fundo", ""))
	m.interior = bool(d.get("interior", false))
	m.musica = str(d.get("musica", ""))
	m.noite = str(d.get("noite", ""))
	for l in d.get("luzes", []):
		m.luzes.append(Vector2(float(l[0]), float(l[1])))
	for s in d.get("saidas", []):
		var ch: Array = s.get("chegada", [0, 0])
		m.saidas.append({"x": int(s.get("x", 0)), "y": int(s.get("y", 0)), "para": str(s.get("para", "")),
			"chegada": Vector2i(int(ch[0]), int(ch[1])), "olhar": str(s.get("olhar", "")), "loja": str(s.get("loja", ""))})
	for n in d.get("npcs", []):
		m.npcs.append({"id": str(n.get("id", "")), "sprite": str(n.get("sprite", "")), "x": int(n.get("x", 0)),
			"y": int(n.get("y", 0)), "olhar": str(n.get("olhar", "baixo")), "loja": str(n.get("loja", "")),
			"fala": str(n.get("fala", ""))})
	for f in d.get("fechadas", []):
		m.fechadas.append({"x": int(f.get("x", 0)), "y": int(f.get("y", 0)), "aviso": str(f.get("aviso", ""))})
	var legenda: Dictionary = d.get("legenda", {})
	var linhas: Array = d.get("linhas", [])
	m.altura = linhas.size()
	for y in linhas.size():
		var s := str(linhas[y])
		m.largura = maxi(m.largura, s.length())
		var fila: Array = []
		for x in s.length():
			var tipo := str(legenda.get(s[x], "grama"))
			if defs_objetos.has(tipo):
				fila.append("grama")
				m.objetos.append({"tipo": tipo, "x": x, "y": y})
			else:
				fila.append(tipo)
		m._grade.append(fila)
	for o in d.get("objetos", []):
		m.objetos.append({"tipo": str(o.get("tipo", "")), "x": int(o.get("x", 0)), "y": int(o.get("y", 0))})
	for o in m.objetos:
		var def: Dictionary = defs_objetos.get(o["tipo"], {})
		var peg: Array = def.get("pegada", [1, 1])
		for dy in int(peg[1]):
			for dx in int(peg[0]):
				m._ocupado["%d,%d" % [int(o["x"]) + dx, int(o["y"]) + dy]] = o["tipo"]
		if def.has("porta"):
			var p: Array = def["porta"]
			m._livre["%d,%d" % [int(o["x"]) + int(p[0]), int(o["y"]) + int(p[1])]] = true
	for n in m.npcs:
		m._ocupado["%d,%d" % [int(n["x"]), int(n["y"])]] = "npc"
	var ini: Array = d.get("inicio", [0, 0])
	m.inicio = Vector2i(int(ini[0]), int(ini[1]))
	return m


## O que há na célula: o objeto que a ocupa ou, se não houver, o tipo de chão. "" fora do mapa.
func tipo_em(celula: Vector2i) -> String:
	var obj = _ocupado.get("%d,%d" % [celula.x, celula.y])
	if obj != null:
		return obj
	return chao_em(celula)


## Só o tipo de chão da célula (ignora objetos). "" fora do mapa.
func chao_em(celula: Vector2i) -> String:
	if celula.y < 0 or celula.y >= altura:
		return ""
	var fila: Array = _grade[celula.y]
	if celula.x < 0 or celula.x >= fila.size():
		return ""
	return fila[celula.x]


func ocupada(celula: Vector2i) -> bool:
	var k := "%d,%d" % [celula.x, celula.y]
	return _ocupado.has(k) and not _livre.has(k)


## Porta de um objeto (passável, mas tipo_em ainda diz o objeto).
func porta(celula: Vector2i) -> bool:
	return _livre.has("%d,%d" % [celula.x, celula.y])


## O morador parado nesta célula, ou {} se não houver.
func npc_em(celula: Vector2i) -> Dictionary:
	for n in npcs:
		if int(n["x"]) == celula.x and int(n["y"]) == celula.y:
			return n
	return {}


## A porta trancada nesta célula, ou {} se não houver.
func fechada_em(celula: Vector2i) -> Dictionary:
	for f in fechadas:
		if int(f["x"]) == celula.x and int(f["y"]) == celula.y:
			return f
	return {}


## A saída que fica nesta célula, ou {} se não houver.
func saida_em(celula: Vector2i) -> Dictionary:
	for s in saidas:
		if int(s["x"]) == celula.x and int(s["y"]) == celula.y:
			return s
	return {}


## Células a até 'dist' tiles de alguma água (distância de xadrez, como no Minecraft; D-053).
## Retorna um dicionário "x,y" -> true.
func celulas_irrigadas(dist: int, defs_tiles: Dictionary) -> Dictionary:
	var r := {}
	for y in altura:
		for x in largura:
			var tipo := chao_em(Vector2i(x, y))
			if not bool(defs_tiles.get(tipo, {}).get("agua", false)):
				continue
			for dy in range(-dist, dist + 1):
				for dx in range(-dist, dist + 1):
					r["%d,%d" % [x + dx, y + dy]] = true
	return r
