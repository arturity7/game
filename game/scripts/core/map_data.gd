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
var saidas: Array = []    # [{"x", "y", "para", "chegada": Vector2i, "olhar", "loja", "se", "aviso"}]
var fundo := ""           # interiores: imagem do cômodo em assets/sprites/interiores/
var interior := false
var musica := ""
var mata := "arvore"      # objeto da mata fechada desenhada em volta do mapa
var npcs: Array = []      # [{"id", "sprite", "x", "y", "olhar", "loja", "fala"}] — moradores parados
var fechadas: Array = []  # [{"x", "y", "aviso"}] — portas trancadas (botão direito mostra o aviso)
var noite := ""           # interiores: imagem por cima à noite (janelas escuras)
var luzes: Array = []     # interiores: pontos (em pixels) que acendem à noite
var peixes: Array = []    # o que se pesca aqui: [{"item", "peso", "noite", "dia"}]
var corte := false        # dá para cortar árvores aqui (machado)? Ver Corte
var animais := false      # dá para soltar animais e pôr construções aqui? Ver Animais, Construcao
var inimigos: Array = []  # [{"id", "tipo" (Config.inimigos), "x", "y", "se", "unico"}]
var clima := ""           # "tempestade" ou "chuva": chuva caindo (e relâmpagos na tempestade)
var hora_fixa := -1.0     # >= 0: a luz do mapa fica sempre nessa hora (ex.: a noite da tempestade)
var desmaio: Dictionary = {}   # onde acorda quem desmaia aqui: {"mapa", "x", "y"} (senão, a clínica)
var ao_entrar: Array = []       # conversas que abrem ao chegar: [{"dialogo", "se"}] (a primeira que vale)
var sondagem: Dictionary = {}  # lago com fundo medível: {"ponto", "maximo", "raio", "flag", "efeitos", "texto"}
var _grade: Array = []    # Array[Array[String]] de tipos de chão
var _ocupado := {}        # "x,y" -> tipo do objeto que ocupa a célula
var _livre := {}          # "x,y" -> true: célula de porta (dentro de uma pegada, mas passável)
var _indice := {}         # "x,y" -> índice em 'objetos' do objeto que cobre a célula


static func de_dict(d: Dictionary, defs_objetos := {}) -> MapData:
	var m := MapData.new()
	m.id = str(d.get("id", ""))
	m.nome = str(d.get("nome", m.id))
	m.fundo = str(d.get("fundo", ""))
	m.interior = bool(d.get("interior", false))
	m.musica = str(d.get("musica", ""))
	m.mata = str(d.get("mata", "arvore"))
	m.noite = str(d.get("noite", ""))
	m.peixes = d.get("peixes", [])
	m.sondagem = d.get("sondagem", {})
	m.corte = bool(d.get("corte", false))
	m.animais = bool(d.get("animais", false))
	m.inimigos = d.get("inimigos", [])
	m.clima = str(d.get("clima", ""))
	m.hora_fixa = float(d.get("hora_fixa", -1.0))
	m.desmaio = d.get("desmaio", {})
	m.ao_entrar = d.get("ao_entrar", [])
	for l in d.get("luzes", []):
		m.luzes.append(Vector2(float(l[0]), float(l[1])))
	for s in d.get("saidas", []):
		var ch: Array = s.get("chegada", [0, 0])
		m.saidas.append({"x": int(s.get("x", 0)), "y": int(s.get("y", 0)), "para": str(s.get("para", "")),
			"chegada": Vector2i(int(ch[0]), int(ch[1])), "olhar": str(s.get("olhar", "")), "loja": str(s.get("loja", "")),
			"se": s.get("se", {}), "aviso": str(s.get("aviso", ""))})
	for n in d.get("npcs", []):
		m.npcs.append({"id": str(n.get("id", "")), "sprite": str(n.get("sprite", "")), "x": int(n.get("x", 0)),
			"y": int(n.get("y", 0)), "olhar": str(n.get("olhar", "baixo")), "loja": str(n.get("loja", "")),
			"fala": str(n.get("fala", "")), "dialogo": str(n.get("dialogo", "")), "nome": str(n.get("nome", "")),
			"se": n.get("se", {}), "quadro": n.get("quadro", [16, 32])})
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
			var chao := "grama"
			if "@" in tipo:  # "objeto@chao": objeto sobre outro chão (ex.: "horta@terra")
				chao = tipo.get_slice("@", 1)
				tipo = tipo.get_slice("@", 0)
			if defs_objetos.has(tipo):
				fila.append(chao)
				m.objetos.append({"tipo": tipo, "x": x, "y": y})
			else:
				fila.append(tipo if not "@" in str(legenda.get(s[x], "")) else chao)
		m._grade.append(fila)
	for o in d.get("objetos", []):
		var obj: Dictionary = o.duplicate(true)
		obj["tipo"] = str(o.get("tipo", ""))
		obj["x"] = int(o.get("x", 0))
		obj["y"] = int(o.get("y", 0))
		m.objetos.append(obj)
	for i in m.objetos.size():
		var o: Dictionary = m.objetos[i]
		var def: Dictionary = defs_objetos.get(o["tipo"], {})
		var peg: Array = def.get("pegada", [1, 1])
		for dy in int(peg[1]):
			for dx in int(peg[0]):
				var k := "%d,%d" % [int(o["x"]) + dx, int(o["y"]) + dy]
				m._indice[k] = i
				if bool(def.get("solido", true)):
					m._ocupado[k] = o["tipo"]
		if def.has("porta"):
			var p: Array = def["porta"]
			m._livre["%d,%d" % [int(o["x"]) + int(p[0]), int(o["y"]) + int(p[1])]] = true
	for n in m.npcs:
		m._ocupado["%d,%d" % [int(n["x"]), int(n["y"])]] = "npc"
	var ini: Array = d.get("inicio", [0, 0])
	m.inicio = Vector2i(int(ini[0]), int(ini[1]))
	return m


## Troca o objeto de 1 célula que está em 'c' por outro tipo (ex.: árvore cortada → toco).
func trocar_objeto(c: Vector2i, tipo: String, defs_objetos: Dictionary) -> void:
	var k := "%d,%d" % [c.x, c.y]
	var i = _indice.get(k)
	if i == null:
		return
	objetos[i]["tipo"] = tipo
	if bool(defs_objetos.get(tipo, {}).get("solido", true)):
		_ocupado[k] = tipo
	else:
		_ocupado.erase(k)


## Põe um objeto de 1 célula em 'c' (construção do jogador). Retorna o índice dele em 'objetos'.
func adicionar_objeto(c: Vector2i, tipo: String, defs_objetos: Dictionary) -> int:
	var k := "%d,%d" % [c.x, c.y]
	objetos.append({"tipo": tipo, "x": c.x, "y": c.y})
	var i := objetos.size() - 1
	_indice[k] = i
	if bool(defs_objetos.get(tipo, {}).get("solido", true)):
		_ocupado[k] = tipo
	return i


## Índice em 'objetos' do objeto que cobre a célula, ou -1.
func indice_em(c: Vector2i) -> int:
	return int(_indice.get("%d,%d" % [c.x, c.y], -1))


## Tira o objeto de 1 célula que está em 'c' (ele fica na lista com tipo "", para os índices não mudarem).
func remover_objeto(c: Vector2i) -> void:
	var k := "%d,%d" % [c.x, c.y]
	var i = _indice.get(k)
	if i == null:
		return
	objetos[i]["tipo"] = ""
	_ocupado.erase(k)
	_indice.erase(k)


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


## O objeto (com todos os campos do mapa) que cobre a célula, ou {} se não houver.
func objeto_em(celula: Vector2i) -> Dictionary:
	var i = _indice.get("%d,%d" % [celula.x, celula.y])
	return objetos[i] if i != null else {}


## Profundidade (em metros) da água nesta célula, se o mapa tiver "sondagem"; 0 se não tiver.
## Cresce de forma suave até o "maximo" no "ponto" mais fundo.
func profundidade(celula: Vector2i) -> int:
	if sondagem.is_empty():
		return 0
	var p: Array = sondagem.get("ponto", [0, 0])
	var dist := Vector2(celula).distance_to(Vector2(float(p[0]), float(p[1])))
	if dist < 0.5:
		return int(sondagem.get("maximo", 30))
	var k := clampf(1.0 - dist / float(sondagem.get("raio", 10)), 0.04, 0.97)
	return maxi(1, int(round(float(sondagem.get("maximo", 30)) * k)))


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
