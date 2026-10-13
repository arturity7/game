"""Arte da cidade do Leaf & Lore: calçada, prédios (mercado, clínica, ferreiro), enfeites e moradores.

Chamado por gerar_arte.py (tecnico.md §7). Mesma paleta e escala do resto do jogo.
"""
import math
from pixel import *  # noqa: F401,F403
from gerar_arte import caminho, _sombra, contornar, copa, quadro_jogador
import fonte as F

ESCURO = hexc("#1e1420")
RAMPAS.update({
    "telhado_verde": ["#1d3a2a", "#285036", "#356944", "#468453", "#5da066", "#7dbb7c"],
    "telhado_azul": ["#1d2740", "#283757", "#35496f", "#465e89", "#5c78a3", "#7b97bd"],
    "telhado_ardosia": ["#1e1d24", "#2b2a33", "#3a3944", "#4b4a57", "#5f5e6c", "#777684"],
    "reboco": ["#9c8a6c", "#b8a585", "#d2c09e", "#e6d7b6", "#f4e9cf"],
    "reboco_branco": ["#a3a7b3", "#c0c4ce", "#d9dce3", "#eceef2", "#fafbfc"],
    "tijolo": ["#5a2a22", "#74382c", "#8f4a38", "#a85d46", "#c07656"],
    "calcada": ["#5b5751", "#76716a", "#918b82", "#aaa49a", "#c4beb3", "#dad5cb"],
})


def texto_px(img, x, y, t, c, esc=1):
    """Escreve com a fonte Leaf Pixel (linha de base = y)."""
    for ch in t:
        m = F.bitmap(ch if (ch in F.G or ch in F.COMPOSTOS or ch in "çÇ") else "?")
        for yy, linha in enumerate(m):
            for xx, v in enumerate(linha):
                if v:
                    for dy in range(esc):
                        for dx in range(esc):
                            put(img, x + xx * esc + dx, y + (yy - F.BASE) * esc + dy, c)
        x += (len(m[0]) + 1) * esc
    return x


def largura_texto(t, esc=1):
    return sum((len(F.bitmap(ch)[0]) + 1) * esc for ch in t) - esc


# =============================== CALÇADA ===============================

def calcada():
    """Calçada de pedras em grade dupla (bordas com meio-fio)."""
    def pintar(img, x, y, s, wx, wy, q, m):
        if s <= 0:
            # pedras retangulares em fiadas desencontradas (alinhadas ao mundo)
            fila = wy // 5
            desloc = 3 if fila % 2 else 0
            bx = (wx + desloc) % 8
            by = wy % 5
            pedra_id = hash01((wx + desloc) // 8, fila, 71)
            i = 3 if pedra_id > 0.5 else 2 if pedra_id > 0.2 else 4
            if bx == 0 or by == 0:
                i = 1
            elif by == 1 and bx > 0:
                i = min(5, i + 1)
            if s > -1.2:
                i = 1
            elif s > -2.2:
                i = 4
            put(img, x, y, cor("calcada", i))
        elif s <= 1.0:
            put(img, x, y, cor("grama", 1, 170))
    from pixel import tiles_dual
    return tiles_dual(pintar, variantes=2, raio=3.0, ruido=0.0, semente=9)


# =============================== PRÉDIOS ===============================

PREDIOS = {
    "mercado": {"largura": 7, "telhado": "telhado_verde", "parede": "reboco", "placa": "MERCADO", "toldo": "folha"},
    "clinica": {"largura": 7, "telhado": "telhado_azul", "parede": "reboco_branco", "placa": "CLÍNICA", "cruz": True},
    "ferreiro": {"largura": 5, "telhado": "telhado_ardosia", "parede": "tijolo", "placa": "FERREIRO", "chamine": True},
    "sapataria": {"largura": 5, "telhado": "telhado", "parede": "reboco", "placa": "SAPATEIRO", "chamine": True},
}


def predio(nome):
    """Prédio da cidade. Largura em tiles (ímpar, porta no meio); altura 112 px; pegada = largura x 3.
    Devolve (imagem, janelas_acesas, centros_das_janelas)."""
    p = PREDIOS[nome]
    W, H = p["largura"] * 16, 112
    img = nova(W, H)
    noite = nova(W, H)
    _sombra(img, W / 2, H - 4, W / 2 + 2, 5, 90)
    base_y, topo_parede = H - 14, 52
    # fundação
    for y in range(base_y, base_y + 8):
        for x in range(2, W - 2):
            desl = 4 if (y - base_y) // 4 % 2 else 0
            i = 3 if (y - base_y) % 4 == 0 else 2
            if (x + desl) % 8 == 0:
                i = 1
            put(img, x, y, cor("pedra", i))
    # paredes
    rp = p["parede"]
    for y in range(topo_parede, base_y):
        for x in range(4, W - 4):
            if rp == "tijolo":
                fila = (y - topo_parede) // 4
                desl = 4 if fila % 2 else 0
                i = 3
                if (y - topo_parede) % 4 == 3 or (x + desl) % 8 == 0:
                    i = 1
                elif hash01((x + desl) // 8, fila, 72) > 0.7:
                    i = 2
                elif (y - topo_parede) % 4 == 0:
                    i = 4
            else:
                i = 3 if hash01(x // 3, y // 3, 73) > 0.15 else 2
                if x < 7 or x > W - 8:
                    i = 1  # vigas nos cantos
            put(img, x, y, cor(rp, i))
    if rp != "tijolo":  # vigas de madeira (enxaimel)
        for x in list(range(4, 7)) + list(range(W - 7, W - 4)):
            for y in range(topo_parede, base_y):
                put(img, x, y, cor("madeira", 2 if x in (6, W - 5) else 3))
        for y in range(topo_parede + 2, topo_parede + 5):
            for x in range(4, W - 4):
                put(img, x, y, cor("madeira", 3 if y < topo_parede + 4 else 1))
    for y in range(topo_parede, topo_parede + 4):  # sombra do beiral
        for x in range(4, W - 4):
            put(img, x, y, (30, 15, 8, 120 - (y - topo_parede) * 28))
    # porta dupla no meio (vidro nas lojas)
    cx = W // 2
    for y in range(66, base_y):
        for x in range(cx - 9, cx + 9):
            put(img, x, y, cor("madeira", 1))
    for y in range(68, base_y):
        for x in range(cx - 7, cx + 7):
            if x in (cx - 1, cx):
                put(img, x, y, cor("madeira", 1 if x == cx - 1 else 3))
                continue
            if 71 <= y <= 84 and (cx - 6 <= x <= cx - 3 or cx + 2 <= x <= cx + 5):
                v = (x - cx) + (y - 71)
                put(img, x, y, cor("vidro", 4 if 2 <= v % 9 <= 3 else 2))
                put(noite, x, y, hexc("#ffcf6e") if 2 <= v % 9 <= 3 else hexc("#f3a447"))
            else:
                put(img, x, y, cor("madeira", 3 if (y - 68) % 6 else 2))
    for x in range(cx - 10, cx + 10):  # degrau
        for y in range(base_y, base_y + 4):
            put(img, x, y, cor("pedra", 4 if y == base_y else 3))
    # janelas (uma de cada lado)
    centros = []
    for jx in (10, W - 26):
        if p["largura"] <= 5 and jx > 10:
            jx = W - 22
        jw = 16 if p["largura"] > 5 else 12
        for y in range(64, 80):
            for x in range(jx, jx + jw):
                put(img, x, y, cor("madeira", 1))
        for y in range(66, 78):
            for x in range(jx + 2, jx + jw - 2):
                v = (x - jx) + (y - 66)
                i = 1 if y > 72 else 2
                if 4 <= v <= 6 or 9 <= v <= 10:
                    i = 4
                put(img, x, y, cor("vidro", i))
                put(noite, x, y, hexc("#ffe7a3") if 4 <= v <= 7 else hexc("#ffc861") if y < 72 else hexc("#f3a447"))
        mid = jx + jw // 2
        for y in range(66, 78):
            put(img, mid - 1, y, cor("madeira", 1)); put(img, mid, y, cor("madeira", 3))
            put(noite, mid - 1, y, cor("madeira", 1)); put(noite, mid, y, cor("madeira", 3))
        for x in range(jx - 1, jx + jw + 1):
            put(img, x, 80, cor("madeira", 4)); put(img, x, 81, cor("madeira", 2))
        centros.append([mid, 72])
    # toldo listrado (mercado)
    if p.get("toldo"):
        for y in range(58, 66):
            for x in range(cx - 14, cx + 14):
                listra = ((x - cx + 14) // 4) % 2
                i = (4 if listra else 2) if y < 64 else (3 if listra else 1)
                put(img, x, y, cor(p["toldo"], i) if listra else cor("flor_br", 2 if y < 64 else 1))
            if y == 65:
                for x in range(cx - 14, cx + 14, 4):
                    put(img, x + 1, 66, cor(p["toldo"], 3))
        # caixotes de verduras ao lado da porta
        for (bx, cor_v) in ((cx - 24, "cenoura"), (cx + 15, "milho")):
            for y in range(base_y - 8, base_y):
                for x in range(bx, bx + 9):
                    put(img, x, y, cor("madeira", 4 if y == base_y - 8 else 3 if x % 3 else 2))
            for k in range(5):
                put(img, bx + 1 + k * 2, base_y - 9, cor(cor_v, 2)); put(img, bx + 2 + k * 2, base_y - 10, cor(cor_v, 3))
    # cruz da clínica (verde, sobre a porta)
    if p.get("cruz"):
        for y in range(56, 66):
            for x in range(cx - 5, cx + 5):
                if abs(x - cx + 0.5) < 2 or abs(y - 60.5) < 2:
                    put(img, x, y, cor("folha", 5 if (x < cx and y < 61) else 4))
        for (x, y) in ((cx - 2, 55), (cx + 1, 55)):
            put(img, x, y, ESCURO)
    # telhado
    rt = p["telhado"]
    for y in range(6, 54):
        k = (y - 6) / 48.0
        x0 = int(round(10 - 10 * k)); x1 = W - x0
        for x in range(x0, x1):
            fileira = (y - 6) // 6
            desl = 4 if fileira % 2 else 0
            yy = (y - 6) % 6
            i = 4 if yy not in (0, 4, 5) else (5 if yy == 0 else 2 if yy == 4 else 1)
            if (x + desl) % 8 == 0 and yy < 5:
                i = 2
            if hash01((x + desl) // 8, fileira, 74 + len(nome)) > 0.85 and i == 4:
                i = 3
            if x - x0 < 2 or x1 - x < 3:
                i = min(i, 2)
            put(img, x, y, cor(rt, i))
    for x in range(10, W - 10):
        for y in range(3, 7):
            put(img, x, y, cor(rt, 2 if y == 6 else 3 if y > 3 else 5))
    for x in range(0, W):
        for y in range(52, 55):
            if get(img, x, y)[3] == 0 or y < 54:
                put(img, x, y, cor(rt, 1 if y == 54 else 2))
    if p.get("chamine"):
        for y in range(0, 26):
            for x in range(W - 24, W - 14):
                i = 3 if (y + (2 if (x // 5) % 2 else 0)) % 5 else 1
                put(img, x, y, cor("tijolo", i))
        for x in range(W - 25, W - 13):
            put(img, x, 0, cor("pedra", 3))
    # placa com o nome, pendurada no beiral
    t = p["placa"]
    tw = largura_texto(t)
    px0, px1 = cx - tw // 2 - 4, cx + (tw - tw // 2) + 4
    for y in range(37, 52):
        for x in range(px0, px1):
            borda = x in (px0, px1 - 1) or y in (37, 51)
            put(img, x, y, cor("madeira", 1) if borda else cor("papel", 3 if y < 45 else 2))
    texto_px(img, cx - tw // 2, 49, t, cor("madeira", 0))
    contornar(img, ESCURO)
    return img, noite, centros


# =============================== ENFEITES DA CIDADE ===============================

def poste():
    """Poste de luz 16x40 (a lâmpada acende à noite)."""
    img = nova(16, 40)
    _sombra(img, 8, 38, 4, 1.4, 90)
    for y in range(8, 37):
        put(img, 7, y, cor("metal", 2)); put(img, 8, y, cor("metal", 1))
    for x in range(5, 11):
        put(img, x, 36, cor("metal", 2)); put(img, x, 35, cor("metal", 3))
    for y in range(1, 9):  # lanterna
        for x in range(4, 12):
            borda = x in (4, 11) or y in (1, 8)
            put(img, x, y, cor("metal", 1) if borda else hexc("#f6e7a8"))
    for x in range(3, 13):
        put(img, x, 0, cor("metal", 2))
    contornar(img, ESCURO)
    return img


def banco():
    img = nova(32, 22)
    _sombra(img, 16, 20, 15, 2, 90)
    for y in range(2, 8):  # encosto
        for x in range(2, 30):
            put(img, x, y, cor("madeira", 5 if y == 2 else 4 if y < 5 else 3))
    for y in range(10, 15):  # assento
        for x in range(1, 31):
            put(img, x, y, cor("madeira", 5 if y == 10 else 4 if y < 13 else 2))
    for x in (3, 4, 27, 28):
        for y in list(range(8, 10)) + list(range(15, 19)):
            put(img, x, y, cor("metal", 1 if x in (4, 28) else 2))
    contornar(img, ESCURO)
    return img


def fonte_agua(quadro):
    """Chafariz 48x44 (pegada 3x2), 3 quadros de água."""
    img = nova(48, 44)
    _sombra(img, 24, 40, 23, 3, 90)
    for y in range(14, 40):
        for x in range(1, 47):
            dx, dy = (x + 0.5 - 24) / 23, (y + 0.5 - 27) / 12.5
            r = dx * dx + dy * dy
            if r <= 1:
                if r > 0.72:
                    put(img, x, y, cor("pedra", 4 if dy < 0 else 2 if dy > 0.6 else 3))
                else:
                    onda = (x + y * 2 + quadro * 3) % 9
                    c = cor("agua", 4 if onda < 2 else 3)
                    if hash01(x, y, quadro, 75) > 0.93:
                        c = cor("agua", 6)
                    put(img, x, y, c)
    for y in range(4, 28):  # coluna central
        for x in range(21, 27):
            put(img, x, y, cor("pedra", 4 if x < 23 else 3 if x < 25 else 2))
    for y in range(4, 8):  # bacia de cima
        for x in range(15, 33):
            put(img, x, y, cor("pedra", 5 if y == 4 else 3))
    # jato e gotas
    for k in range(6):
        h = (k * 5 + quadro * 2) % 10
        put(img, 24 + (k % 3) - 1, 2 - (k % 2), cor("agua", 6))
        put(img, 14 + (k * 7 + quadro * 3) % 20, 9 + h, cor("agua", 5))
    contornar(img, ESCURO)
    return img


def canteiro_flores():
    img = nova(32, 18)
    _sombra(img, 16, 16, 15, 1.8, 90)
    for y in range(8, 15):
        for x in range(1, 31):
            put(img, x, y, cor("madeira", 4 if y == 8 else 3 if y < 14 else 2))
    for k in range(9):
        fx = 3 + k * 3 + (1 if k % 2 else 0)
        fy = 4 + (k % 3)
        rampa = ("flor_rs", "flor_am", "flor_li", "flor_br")[k % 4]
        for j in range(fy + 1, 9):
            put(img, fx, j, cor("folha", 4))
        for (dx, dy) in ((0, -1), (-1, 0), (1, 0), (0, 1), (0, 0)):
            put(img, fx + dx, fy + dy, cor(rampa, 2 if (dx, dy) != (0, 0) else 0))
    contornar(img, ESCURO)
    return img


def quiosque():
    """Quiosque de revistas da praça 32x44 (pegada 2x1): toldo listrado, revistas e jornais."""
    img = nova(32, 44)
    _sombra(img, 16, 42, 15, 2, 90)
    for y in range(18, 40):
        for x in range(1, 31):
            put(img, x, y, cor("tunica_azul", 3 if x < 16 else 2) if y > 20 else cor("tunica_azul", 4))
    for y in range(22, 34):  # revistas na vitrine
        for x in range(3, 29):
            k = (x - 3) // 5
            put(img, x, y, cor(("coracao", "milho", "folha", "flor_li", "cenoura", "camisa")[k % 6], 2 if (x - 3) % 5 else 0))
    for y in range(6, 18):  # toldo
        for x in range(0, 32):
            listra = (x // 4) % 2
            put(img, x, y, cor("coracao", 2 if y < 16 else 1) if listra else cor("flor_br", 2 if y < 16 else 1))
    for x in range(0, 32, 4):
        put(img, x + 1, 18, cor("coracao", 1))
    for y in range(0, 6):  # placa
        for x in range(8, 24):
            put(img, x, y, cor("papel", 3) if 0 < y < 5 and 8 < x < 23 else cor("madeira", 1))
    return contornar(img, ESCURO)


# =============================== MORADORES ===============================

def _recolorir(folha, trocas):
    """Troca cores da folha do jogador (rampa antiga -> rampa nova)."""
    out = folha.copy()
    for velha, nova_r in trocas.items():
        for i, h in enumerate(RAMPAS[velha]):
            c = hexc(h)
            alvo = hexc(RAMPAS[nova_r][min(i, len(RAMPAS[nova_r]) - 1)])
            m = (folha[:, :, 0] == c[0]) & (folha[:, :, 1] == c[1]) & (folha[:, :, 2] == c[2])
            out[m] = alvo
    return out


RAMPAS.update({
    "cabelo_loiro": ["#6e4b1c", "#98692a", "#c49440", "#ddb55c", "#efd28a"],
    "cabelo_preto": ["#141016", "#1f1a22", "#2c2530", "#3c3341", "#4f4555"],
    "cabelo_grisalho": ["#5d5a62", "#7c7983", "#9c99a3", "#bdbac3", "#dcdae0"],
    "camisa_verde": ["#1d3a22", "#285030", "#356a3e", "#4a8a50", "#68a866"],
    "camisa_branca": ["#8f95a3", "#b4bac6", "#d6dbe3", "#eceff4", "#ffffff"],
    "camisa_vinho": ["#3c1420", "#58202d", "#76303c", "#94434e", "#b05d66"],
    "camisa_xadrez": ["#3a2a12", "#5a4220", "#7d5e30", "#a07c44", "#c29c5e"],
})


def moradores():
    from gerar_arte import jogador
    base = jogador()
    tipos = {
        "vendedora": {"cabelo": "cabelo_loiro", "camisa": "camisa_verde"},
        "enfermeira": {"cabelo": "cabelo_preto", "camisa": "camisa_branca"},
        "ferreiro": {"cabelo": "cabelo_grisalho", "camisa": "camisa_vinho"},
        "jornaleiro": {"cabelo": "cabelo_preto", "camisa": "camisa_xadrez"},
    }
    r = {}
    for nome, t in tipos.items():
        r[nome] = _recolorir(base, t)
    return r


def gerar():
    salvar(calcada(), caminho("terreno", "calcada.png"))
    for nome in PREDIOS:
        img, noite, _ = predio(nome)
        salvar(img, caminho("objetos", nome + ".png"))
        salvar(noite, caminho("objetos", nome + "_janelas.png"))
    salvar(poste(), caminho("objetos", "poste.png"))
    salvar(banco(), caminho("objetos", "banco.png"))
    salvar(canteiro_flores(), caminho("objetos", "canteiro_flores.png"))
    salvar(quiosque(), caminho("objetos", "quiosque.png"))
    for q in range(3):
        salvar(fonte_agua(q), caminho("objetos", "chafariz_%d.png" % q))
    for nome, folha in moradores().items():
        salvar(folha, caminho("personagens", nome + ".png"))


def centros_janelas():
    return {nome: predio(nome)[2] for nome in PREDIOS}
