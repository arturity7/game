class_name Peixes
extends RefCounted
## Regras da pesca sem tela (para os testes). A tela da pesca fica em scripts/world/pesca.gd.


## Escolhe um peixe da tabela pelo peso, respeitando dia e noite.
static func sortear(peixes: Array, hora_do_dia: float, rng: RandomNumberGenerator) -> String:
	var noite := hora_do_dia >= 19.0 or hora_do_dia < 5.0
	var possiveis: Array = []
	var total := 0.0
	for p in peixes:
		if bool(p.get("noite", false)) and not noite:
			continue
		if bool(p.get("dia", false)) and noite:
			continue
		possiveis.append(p)
		total += float(p.get("peso", 1))
	if possiveis.is_empty():
		return ""
	var r := rng.randf() * total
	for p in possiveis:
		r -= float(p.get("peso", 1))
		if r <= 0.0:
			return str(p["item"])
	return str(possiveis[-1]["item"])
