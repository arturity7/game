extends Node
## Teclas do jogo (GDD §8: teclado e mouse, WASD para andar). Registradas em código
## para o project.godot ficar curto e legível.

const ACOES := {
	"mover_cima": [KEY_W, KEY_UP],
	"mover_baixo": [KEY_S, KEY_DOWN],
	"mover_esquerda": [KEY_A, KEY_LEFT],
	"mover_direita": [KEY_D, KEY_RIGHT],
	"menu": [KEY_ESCAPE],
	"correr": [KEY_SHIFT],             # segurando, anda mais rápido (gasta mais fome)
	"interagir": [KEY_E],              # o mesmo que o botão direito (na célula à frente)
	"avancar": [KEY_SPACE, KEY_ENTER, KEY_E],   # passa a fala nas conversas
	"diario": [KEY_J, KEY_TAB],        # diário de missões e conquistas
	"construir": [KEY_C],              # menu Construir (cercas, porteiras...)
	"barra_1": [KEY_1], "barra_2": [KEY_2], "barra_3": [KEY_3], "barra_4": [KEY_4], "barra_5": [KEY_5],
	"barra_6": [KEY_6], "barra_7": [KEY_7], "barra_8": [KEY_8], "barra_9": [KEY_9], "barra_10": [KEY_0],
}


func _ready() -> void:
	registrar()


static func registrar() -> void:
	for acao in ACOES:
		if not InputMap.has_action(acao):
			InputMap.add_action(acao)
		for tecla in ACOES[acao]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla
			InputMap.action_add_event(acao, ev)
