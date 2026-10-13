extends Node
## Efeitos sonoros e música (gerados por ferramentas/som/gerar_sons.py; D-039).
## Som.tocar("enxada") toca um efeito; Som.musica("musica_fazenda") troca a música (em laço).

const PASTA := "res://assets/sons/"
const CANAIS := 8

var _efeitos := {}           # nome -> AudioStream
var _canais: Array = []
var _proximo := 0
var _musica: AudioStreamPlayer
var _musica_atual := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in CANAIS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_canais.append(p)
	_musica = AudioStreamPlayer.new()
	_musica.finished.connect(func(): _musica.play())
	add_child(_musica)


func _volume(chave: String, padrao: float) -> float:
	return float(Config.balanceamento.get(chave, padrao))


func _carregar(nome: String) -> AudioStream:
	if not _efeitos.has(nome):
		_efeitos[nome] = null
		for ext in [".ogg", ".wav"]:
			var caminho: String = PASTA + nome + str(ext)
			if ResourceLoader.exists(caminho):
				_efeitos[nome] = load(caminho)
				break
	return _efeitos[nome]


## Toca um efeito com uma variação pequena de tom, para não cansar.
func tocar(nome: String, volume_db := 0.0, variar := true) -> void:
	var s := _carregar(nome)
	if s == null:
		return
	var p: AudioStreamPlayer = _canais[_proximo]
	_proximo = (_proximo + 1) % CANAIS
	p.stream = s
	p.volume_db = _volume("volume_efeitos_db", -4.0) + volume_db
	p.pitch_scale = randf_range(0.94, 1.06) if variar else 1.0
	p.play()


func musica(nome: String) -> void:
	if nome == _musica_atual and _musica.playing:
		return
	_musica_atual = nome
	var s := _carregar(nome)
	if s == null:
		_musica.stop()
		return
	_musica.stream = s
	_musica.volume_db = _volume("volume_musica_db", -12.0)
	_musica.play()
