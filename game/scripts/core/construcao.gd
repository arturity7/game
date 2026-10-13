class_name Construcao
extends RefCounted
## Construções do jogador (D-057), sem tela: itens do tipo "construcao" (cerca, porteira) são feitos
## no menu Construir com a "receita" (materiais) e postos numa célula livre da fazenda.
## Estado em dados.mundo["construcoes"][id_do_mapa]["x,y"] = tipo do objeto.
## Desfazer = machado (Corte), que devolve o item.


static func do_mapa(dados: GameData, mapa: String) -> Dictionary:
	if not dados.mundo.has("construcoes"):
		dados.mundo["construcoes"] = {}
	var todos: Dictionary = dados.mundo["construcoes"]
	if not todos.has(mapa):
		todos[mapa] = {}
	return todos[mapa]


## Tem os materiais da receita?
static func pode_fazer(dados: GameData, def_item: Dictionary) -> bool:
	var receita: Dictionary = def_item.get("receita", {})
	if receita.is_empty():
		return false
	for mat in receita:
		if Inventario.contar(dados.jogador["inventario"], str(mat)) < int(receita[mat]):
			return false
	return true


## Gasta os materiais e põe o item no inventário. Retorna true se fez.
static func fazer(dados: GameData, id_item: String, itens: Dictionary) -> bool:
	var def: Dictionary = itens.get(id_item, {})
	if not pode_fazer(dados, def):
		return false
	var inv: Array = dados.jogador["inventario"]
	if Inventario.adicionar(inv.duplicate(true), id_item, 1, itens) > 0:
		return false   # não cabe
	var receita: Dictionary = def["receita"]
	for mat in receita:
		_tirar(inv, str(mat), int(receita[mat]))
	Inventario.adicionar(inv, id_item, 1, itens)
	return true


static func _tirar(inv: Array, id: String, qtd: int) -> void:
	for i in inv.size():
		while qtd > 0 and inv[i] != null and str(inv[i]["id"]) == id:
			Inventario.remover(inv, i, 1)
			qtd -= 1


## A célula aceita uma construção? (mapa com "animais": true, chão de grama/terra/caminho, livre)
static func cabe(dados: GameData, mapa: MapData, c: Vector2i, livre: bool) -> bool:
	if not mapa.animais or not livre:
		return false
	if not mapa.objeto_em(c).is_empty() or not mapa.saida_em(c).is_empty():
		return false
	if Fazenda.canteiro(dados, mapa.id, c) != null:
		return false
	return mapa.chao_em(c) in ["grama", "terra", "caminho"]


## Põe a construção (o objeto do item) na célula: vai para o save e para o mapa carregado.
static func por(dados: GameData, mapa: MapData, c: Vector2i, tipo_objeto: String, defs: Dictionary) -> void:
	do_mapa(dados, mapa.id)["%d,%d" % [c.x, c.y]] = tipo_objeto
	mapa.adicionar_objeto(c, tipo_objeto, defs)


## Põe no mapa recém-carregado as construções do save (depois de Corte.aplicar).
static func aplicar(dados: GameData, mapa: MapData, defs: Dictionary) -> void:
	var feitas := do_mapa(dados, mapa.id)
	for k in feitas:
		var p := str(k).split(",")
		var c := Vector2i(int(p[0]), int(p[1]))
		if mapa.objeto_em(c).is_empty():
			mapa.adicionar_objeto(c, str(feitas[k]), defs)
