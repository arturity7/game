extends Node
## Fonte e tema da interface: madeira e pergaminho, no estilo da arte do jogo.
## A fonte é a Leaf Pixel (desenho próprio, gerada por ferramentas/arte/fonte.py): cada pixel do
## desenho cai num pixel da tela no tamanho 13; títulos usam 26 (o dobro). Caracteres que ela
## não tem caem na Pixelify Sans (licença OFL).

const FONTE := preload("res://assets/fontes/leaf_pixel.fnt")
const RESERVA := preload("res://assets/fontes/PixelifySans-Regular.woff2")
const PAINEL := preload("res://assets/sprites/ui/painel.png")
const SLOT := preload("res://assets/sprites/ui/slot.png")
const SLOT_SEL := preload("res://assets/sprites/ui/slot_sel.png")
const ICONES := preload("res://assets/sprites/ui/icones_hud.png")

const TAM_TEXTO := 13
const TAM_TITULO := 26
const COR_TEXTO := Color("#3b2214")
const COR_CLARA := Color("#fff3d6")
const COR_SOMBRA := Color("#1e1420")
## Ícones de icones_hud.png (12x12 cada).
const ICONE := {"vida": 0, "fome": 1, "sol": 2, "lua": 3, "moeda": 4}

var fonte: FontFile
var fonte_forte: FontFile
var painel: StyleBoxTexture
var tema: Theme


func _ready() -> void:
	var reserva := _pixelada(RESERVA)
	fonte = FONTE
	fonte.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	fonte.fallbacks = [reserva]
	fonte_forte = fonte
	ThemeDB.fallback_font = fonte
	ThemeDB.fallback_font_size = TAM_TEXTO
	painel = caixa(PAINEL, 7, 7)
	tema = Theme.new()
	tema.default_font = fonte
	tema.default_font_size = TAM_TEXTO
	tema.set_stylebox("panel", "PanelContainer", painel)
	var botao := caixa(SLOT, 3, 2)
	var botao_sel := caixa(SLOT_SEL, 3, 2)
	tema.set_stylebox("normal", "Button", botao)
	tema.set_stylebox("hover", "Button", botao_sel)
	tema.set_stylebox("pressed", "Button", botao_sel)
	tema.set_stylebox("hover_pressed", "Button", botao_sel)
	tema.set_stylebox("focus", "Button", botao_sel)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		tema.set_color(c, "Button", COR_TEXTO)
	tema.set_color("font_color", "Label", COR_TEXTO)
	get_tree().root.theme = tema


func _pixelada(f: FontFile) -> FontFile:
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	return f


## Caixa 9-patch a partir de uma textura: 'margem' = borda que não estica; 'dentro' = folga do conteúdo.
func caixa(tex: Texture2D, margem: int, dentro: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	for lado in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_texture_margin(lado, margem)
		s.set_content_margin(lado, margem + dentro)
	return s


## Texto com contorno escuro (para ler sobre qualquer fundo).
func texto(alvo: CanvasItem, pos: Vector2, t: String, cor := COR_CLARA, tam := TAM_TEXTO,
		alinhar := HORIZONTAL_ALIGNMENT_LEFT, largura := -1.0, forte := false) -> void:
	var f := fonte_forte if forte else fonte
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		alvo.draw_string(f, pos + d, t, alinhar, largura, tam, COR_SOMBRA)
	alvo.draw_string(f, pos, t, alinhar, largura, tam, cor)


func icone(alvo: CanvasItem, pos: Vector2, nome: String) -> void:
	alvo.draw_texture_rect_region(ICONES, Rect2(pos, Vector2(12, 12)), Rect2(ICONE[nome] * 12, 0, 12, 12))
