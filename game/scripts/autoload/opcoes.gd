extends Node
## Opções do jogador (menu Opções): volumes, mudo e tela cheia. Ficam em user://opcoes.cfg,
## separadas do save (são do computador, não da partida). "Restaurar padrão" volta tudo ao início.
## O som passa por três canais (barramentos): Master (volume geral e mudo), Musica e Efeitos.

const ARQUIVO := "user://opcoes.cfg"
const PADRAO := {"volume_geral": 80, "volume_musica": 70, "volume_efeitos": 80, "mudo": false, "tela_cheia": false}

var valores := PADRAO.duplicate()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for nome in ["Musica", "Efeitos"]:
		if AudioServer.get_bus_index(nome) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nome)
			AudioServer.set_bus_send(i, "Master")
	carregar()
	aplicar()


func valor(chave: String):
	return valores.get(chave, PADRAO.get(chave))


func definir(chave: String, v) -> void:
	if chave.begins_with("volume_"):
		v = clampi(int(v), 0, 100)
	valores[chave] = v
	aplicar()
	salvar()


func restaurar_padrao() -> void:
	valores = PADRAO.duplicate()
	aplicar()
	salvar()


## 0..100 -> decibéis (0 = silêncio).
static func em_db(v: int) -> float:
	return -80.0 if v <= 0 else linear_to_db(v / 100.0)


func aplicar() -> void:
	AudioServer.set_bus_volume_db(0, em_db(int(valor("volume_geral"))))
	AudioServer.set_bus_mute(0, bool(valor("mudo")))
	var m := AudioServer.get_bus_index("Musica")
	if m >= 0:
		AudioServer.set_bus_volume_db(m, em_db(int(valor("volume_musica"))))
	var e := AudioServer.get_bus_index("Efeitos")
	if e >= 0:
		AudioServer.set_bus_volume_db(e, em_db(int(valor("volume_efeitos"))))
	if DisplayServer.get_name() != "headless":
		var cheia := bool(valor("tela_cheia"))
		var agora := DisplayServer.window_get_mode()
		var e_cheia := agora == DisplayServer.WINDOW_MODE_FULLSCREEN or agora == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if cheia != e_cheia:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if cheia else DisplayServer.WINDOW_MODE_WINDOWED)


func carregar() -> void:
	var cf := ConfigFile.new()
	if cf.load(ARQUIVO) != OK:
		return
	for k in PADRAO:
		valores[k] = cf.get_value("opcoes", k, PADRAO[k])


func salvar() -> void:
	var cf := ConfigFile.new()
	for k in valores:
		cf.set_value("opcoes", k, valores[k])
	cf.save(ARQUIVO)
