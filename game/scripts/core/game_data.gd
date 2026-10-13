class_name GameData
extends RefCounted
## Estado do jogo, separado da tela (tecnico.md §2: pensando num multiplayer futuro).
## Tudo que vai para o save mora aqui. Nenhum nó visual guarda estado próprio.

const CHAVES_CONHECIDAS := [
	"save_version", "jogador", "mundo", "progresso", "extras_desconhecidos",
]

var jogador := {
	"mapa": "fazenda",
	"posicao": [0.0, 0.0],
	"fome": 100.0,
	"vida": 100.0,
	"dinheiro": 0,
	"inventario": [],      # slots; ver Inventario
	"barra_selecionada": 0,
}
var mundo := {
	"dia": 1,          # contagem interna; não aparece na tela (GDD §6)
	"hora": 6.0,       # hora do dia, de 0.0 a 24.0
	"canteiros": {},   # id do mapa -> "x,y" -> canteiro; ver Fazenda
	"arvores": {},     # id do mapa -> "x,y" -> árvore cortada/toco; ver Corte
}
var progresso := {
	"flags": {},
	"perguntas": {},   # id da pergunta -> {"acertou": bool, "tentativas": int}
	"livros": {},      # id do livro -> {"concluido": bool}
	"conquistas": {},
}
## Chaves de saves futuros que esta versão não conhece: nunca são descartadas (tecnico.md §5).
var extras_desconhecidos := {}


static func novo(config: Dictionary, mapa_inicial: String, inicio: Vector2, itens := {}) -> GameData:
	var d := GameData.new()
	d.jogador["inventario"] = Inventario.criar(config, itens)
	d.jogador["mapa"] = mapa_inicial
	d.jogador["posicao"] = [inicio.x, inicio.y]
	d.jogador["fome"] = float(config.get("fome_max", 100.0))
	d.jogador["vida"] = float(config.get("vida_max", 100.0))
	d.jogador["dinheiro"] = int(config.get("dinheiro_inicial", 0))
	d.mundo["hora"] = float(config.get("hora_inicio_dia", 6.0))
	return d


func posicao() -> Vector2:
	var p: Array = jogador["posicao"]
	return Vector2(float(p[0]), float(p[1]))


func definir_posicao(v: Vector2) -> void:
	jogador["posicao"] = [v.x, v.y]


func to_dict(versao: int) -> Dictionary:
	var d := {
		"save_version": versao,
		"jogador": jogador.duplicate(true),
		"mundo": mundo.duplicate(true),
		"progresso": progresso.duplicate(true),
	}
	for k in extras_desconhecidos:
		d[k] = extras_desconhecidos[k]
	return d


static func from_dict(d: Dictionary) -> GameData:
	var g := GameData.new()
	g.jogador = _mesclar(g.jogador, d.get("jogador", {}))
	g.mundo = _mesclar(g.mundo, d.get("mundo", {}))
	g.progresso = _mesclar(g.progresso, d.get("progresso", {}))
	for k in d:
		if not (k in CHAVES_CONHECIDAS):
			g.extras_desconhecidos[k] = d[k]
	return g


## Mantém os valores padrão para o que faltar e preserva o que vier a mais.
static func _mesclar(padrao: Dictionary, vindo) -> Dictionary:
	var r := padrao.duplicate(true)
	if typeof(vindo) != TYPE_DICTIONARY:
		return r
	for k in vindo:
		r[k] = vindo[k]
	return r
