class_name MapData
extends RefCounted
## Mapa vindo de content/mapas/<id>.json: uma grade de caracteres com legenda.

var id := ""
var nome := ""
var largura := 0
var altura := 0
var inicio := Vector2i.ZERO
var _grade: Array = []   # Array[Array[String]] de tipos de chão


static func de_dict(d: Dictionary) -> MapData:
	var m := MapData.new()
	m.id = str(d.get("id", ""))
	m.nome = str(d.get("nome", m.id))
	var legenda: Dictionary = d.get("legenda", {})
	var linhas: Array = d.get("linhas", [])
	m.altura = linhas.size()
	for linha in linhas:
		var s := str(linha)
		m.largura = maxi(m.largura, s.length())
		var fila: Array = []
		for c in s:
			fila.append(str(legenda.get(c, "grama")))
		m._grade.append(fila)
	var ini: Array = d.get("inicio", [0, 0])
	m.inicio = Vector2i(int(ini[0]), int(ini[1]))
	return m


func tipo_em(celula: Vector2i) -> String:
	if celula.y < 0 or celula.y >= altura:
		return ""
	var fila: Array = _grade[celula.y]
	if celula.x < 0 or celula.x >= fila.size():
		return ""
	return fila[celula.x]


## Células a até 'dist' tiles de alguma água (distância de xadrez, como no Minecraft; D-053).
## Retorna um dicionário "x,y" -> true.
func celulas_irrigadas(dist: int, defs_tiles: Dictionary) -> Dictionary:
	var r := {}
	for y in altura:
		for x in largura:
			var tipo := tipo_em(Vector2i(x, y))
			if not bool(defs_tiles.get(tipo, {}).get("agua", false)):
				continue
			for dy in range(-dist, dist + 1):
				for dx in range(-dist, dist + 1):
					r["%d,%d" % [x + dx, y + dy]] = true
	return r
