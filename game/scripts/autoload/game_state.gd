extends Node
## Guarda o GameData da partida atual e avisa a tela quando ele muda.

signal partida_carregada
signal desmaiou(perda: int)

var dados: GameData


func nova_partida() -> void:
	var m: MapData = Config.mapa("fazenda")
	var inicio := Vector2(m.inicio) * 16.0 + Vector2(8, 8)
	dados = GameData.novo(Config.balanceamento, m.id, inicio, Config.itens)
	partida_carregada.emit()


func definir(novos: GameData) -> void:
	dados = novos
	partida_carregada.emit()
