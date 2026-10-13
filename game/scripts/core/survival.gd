class_name Survival
extends RefCounted
## Regras de fome, vida e passagem do tempo, sem tela (GDD §4.1 e §6).


## Avança fome e vida. 'esforco' = true enquanto o jogador anda, nada ou trabalha.
static func tick(dados: GameData, cfg: Dictionary, delta: float, esforco: bool, correndo := false) -> void:
	var j := dados.jogador
	var gasto := float(cfg.get("fome_por_segundo", 0.05)) * delta
	if esforco:
		gasto *= float(cfg.get("fome_esforco_multiplicador", 1.5))
	if correndo:
		gasto *= float(cfg.get("fome_correr_multiplicador", 2.0))
	j["fome"] = maxf(0.0, float(j["fome"]) - gasto)
	if float(j["fome"]) <= 0.0:
		var perda := float(cfg.get("vida_perdida_por_segundo_sem_fome", 0.5)) * delta
		j["vida"] = maxf(0.0, float(j["vida"]) - perda)


## Avança o relógio. Um dia inteiro dura 'dia_segundos_reais' segundos (GDD §6: 15 a 20 min).
static func avancar_hora(dados: GameData, cfg: Dictionary, delta: float) -> void:
	var horas := 24.0 * delta / float(cfg.get("dia_segundos_reais", 1080))
	var h := float(dados.mundo["hora"]) + horas
	while h >= 24.0:
		h -= 24.0
		dados.mundo["dia"] = int(dados.mundo["dia"]) + 1
	dados.mundo["hora"] = h


## Vida zerada: acorda na clínica e perde parte do dinheiro (GDD §4.1). Sem game over.
static func desmaiar(dados: GameData, cfg: Dictionary, local_clinica: Vector2, mapa_clinica: String) -> int:
	var j := dados.jogador
	var pct := float(cfg.get("perda_dinheiro_ao_desmaiar_pct", 10)) / 100.0
	var perda := int(floor(int(j["dinheiro"]) * pct))
	# "muralha" comprada com Mathon (livro da Babilônia): perde só a metade
	if bool(dados.progresso["flags"].get(str(cfg.get("flag_muralha", "babilonia.muralha")), false)):
		perda = perda / 2
	j["dinheiro"] = int(j["dinheiro"]) - perda
	j["vida"] = float(cfg.get("vida_max", 100.0)) * 0.5
	j["fome"] = maxf(float(j["fome"]), float(cfg.get("fome_max", 100.0)) * 0.25)
	j["mapa"] = mapa_clinica
	dados.definir_posicao(local_clinica)
	return perda


## Luz do ambiente conforme a hora (noite mais escura).
static func cor_do_ceu(hora: float) -> Color:
	var noite := Color(0.35, 0.38, 0.6)
	var dia := Color(1, 1, 1)
	if hora >= 7.0 and hora < 18.0:
		return dia
	if hora >= 18.0 and hora < 21.0:
		return dia.lerp(noite, (hora - 18.0) / 3.0)
	if hora >= 5.0 and hora < 7.0:
		return noite.lerp(dia, (hora - 5.0) / 2.0)
	return noite


static func texto_hora(hora: float) -> String:
	var h := int(floor(hora))
	var m := int(floor((hora - h) * 60.0)) / 10 * 10
	return "%02d:%02d" % [h, m]
