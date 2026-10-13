class_name Inventario
extends RefCounted
## Inventário em slots. Cada slot é null ou {"id": String, "qtd": int, ...campos do item}.
## Os primeiros slots formam a barra de itens. Regras puras, sem tela.


static func criar(cfg: Dictionary, itens: Dictionary) -> Array:
	var slots := []
	slots.resize(int(cfg.get("slots_inventario", 30)))
	for par in cfg.get("inventario_inicial", []):
		adicionar(slots, str(par[0]), int(par[1]), itens)
	return slots


static func novo_slot(id: String, qtd: int, itens: Dictionary) -> Dictionary:
	var s := {"id": id, "qtd": qtd}
	var def: Dictionary = itens.get(id, {})
	if def.has("capacidade"):
		s["agua"] = int(def["capacidade"])
	return s


## Põe itens no inventário: primeiro completa pilhas iguais, depois usa slots vazios.
## Retorna quantos não couberam.
static func adicionar(slots: Array, id: String, qtd: int, itens: Dictionary) -> int:
	var pilha := int(itens.get(id, {}).get("pilha", 99))
	var resto := qtd
	for s in slots:
		if resto <= 0:
			break
		if s != null and s["id"] == id and int(s["qtd"]) < pilha:
			var cabe := mini(resto, pilha - int(s["qtd"]))
			s["qtd"] = int(s["qtd"]) + cabe
			resto -= cabe
	for i in slots.size():
		if resto <= 0:
			break
		if slots[i] == null:
			var cabe := mini(resto, pilha)
			slots[i] = novo_slot(id, cabe, itens)
			resto -= cabe
	return resto


## Tira 'qtd' do slot 'indice'. Retorna true se tinha o suficiente.
static func remover(slots: Array, indice: int, qtd := 1) -> bool:
	if indice < 0 or indice >= slots.size() or slots[indice] == null:
		return false
	var s: Dictionary = slots[indice]
	if int(s["qtd"]) < qtd:
		return false
	s["qtd"] = int(s["qtd"]) - qtd
	if int(s["qtd"]) <= 0:
		slots[indice] = null
	return true


static func contar(slots: Array, id: String) -> int:
	var n := 0
	for s in slots:
		if s != null and s["id"] == id:
			n += int(s["qtd"])
	return n
