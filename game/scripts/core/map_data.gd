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
var _grade: Array = []    # Array[Array[String]] de tipos de chão
var _ocupado := {}        # "x,y" -> tipo do objeto que ocupa a célula


static func de_dict(d: Dictionary, defs_objetos := {}) -> MapData:
	var m := MapData.new()
	m.id = str(d.get("id", ""))
	m.nome = str(d.get("nome", m.id))
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
		var peg: Array = defs_objetos.get(o["tipo"], {}).get("pegada", [1, 1])
		for dy in int(peg[1]):
			for dx in int(peg[0]):
				m._ocupado["%d,%d" % [int(o["x"]) + dx, int(o["y"]) + dy]] = o["tipo"]
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
	return _ocupado.has("%d,%d" % [celula.x, celula.y])


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
