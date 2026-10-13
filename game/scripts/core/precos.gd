class_name Precos
extends RefCounted
## Quanto as lojas pagam pelos itens (sem tela). Pedido do dono: o Mercado compra tudo o que o
## jogador tiver, e ferramenta usada vale menos.
##   - item com "venda": esse valor;
##   - ferramenta ou arma: 30% do "preco" (ou do "valor"), porque está usada;
##   - item com "receita" (cerca...): o que os materiais valem;
##   - outro item com "preco" (ou "valor"): metade;
##   - sem nada disso: $ 1.
## Itens de missão e chaves ("tipo" missao/chave) não são vendidos, para a história não travar.

const NAO_VENDE := ["missao", "chave"]


static func pode_vender(def: Dictionary) -> bool:
	return not def.is_empty() and not (str(def.get("tipo", "")) in NAO_VENDE)


static func venda(def: Dictionary, itens: Dictionary) -> int:
	if def.has("venda"):
		return maxi(1, int(def["venda"]))
	var base := int(def.get("preco", def.get("valor", 0)))
	var tipo := str(def.get("tipo", ""))
	if tipo in ["ferramenta", "arma"]:
		return maxi(1, base * 30 / 100)
	if def.has("receita"):
		var soma := 0
		for mat in def["receita"]:
			soma += venda(itens.get(str(mat), {}), itens) * int(def["receita"][mat])
		return maxi(1, soma)
	if base > 0:
		return maxi(1, base / 2)
	return 1


## Ids que a loja compra deste inventário, na ordem dos espaços (sem repetir).
## 'compra' = lista da loja ou "tudo".
static func que_a_loja_compra(inv: Array, compra, itens: Dictionary) -> Array:
	var r: Array = []
	if typeof(compra) == TYPE_STRING and str(compra) == "tudo":
		for s in inv:
			if s == null:
				continue
			var id := str(s["id"])
			if not (id in r) and pode_vender(itens.get(id, {})):
				r.append(id)
		return r
	for id in compra:
		if Inventario.contar(inv, str(id)) > 0:
			r.append(str(id))
	return r
