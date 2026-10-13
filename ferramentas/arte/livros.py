"""Arte dos lugares e personagens dos livros (tecnico.md §7). Chamado por gerar_arte.py.

Cada livro ganha o que precisa, sempre com a mesma paleta e escala do resto do jogo.
"""
import math
from pixel import *  # noqa: F401,F403
import gerar_arte as GA
from gerar_arte import caminho, _sombra, contornar, copa
from cidade import _recolorir  # noqa: F401  (também registra as rampas da cidade)

ESCURO = hexc("#1e1420")


# =============================== PERSONAGENS ===============================

BARBA = {
    "baixo": {10: "..ohhkkkkkkhho..", 11: "...ohhhhhhhho..."},
    "esquerda": {10: "..ohhkkkSShhho..", 11: "...ohhhhhooo...."},
}


def personagem(cabelo, roupa, calca=None, barba=False):
    """Folha 80x128 no formato do jogador, com cabelo, roupa (túnica) e barba opcionais."""
    guardado = {k: list(v) for k, v in GA.CABECA.items()}
    if barba:
        for lado, linhas in BARBA.items():
            for i, l in linhas.items():
                GA.CABECA[lado][i] = l
    try:
        folha = GA.jogador()
    finally:
        for k, v in guardado.items():
            GA.CABECA[k] = v
    trocas = {"cabelo": cabelo, "camisa": roupa}
    trocas["calca"] = calca or roupa
    return _recolorir(folha, trocas)


# =============================== EPICURO: O JARDIM ===============================

def oliveira(variante=0):
    """Oliveira 32x40: tronco retorcido e copa verde-prateada."""
    img = nova(32, 40)
    _sombra(img, 16, 37, 12, 3)
    s = 500 + variante
    for y in range(22, 37):  # tronco torto
        dx = int(round(math.sin((y - 22) * 0.45 + variante) * 1.5))
        for x in range(13 + dx, 19 + dx):
            i = 3 if x - dx < 15 else 2 if x - dx < 17 else 1
            if hash01(x, y, s) > 0.8:
                i = max(0, i - 1)
            put(img, x, y, cor("tronco", i))
    for (x, y) in ((11, 36), (12, 36), (20, 36), (21, 35)):
        put(img, x, y, cor("tronco", 2))
    j = lambda k: (hash01(s, k) - 0.5) * 2
    circ = [(16, 13, 10), (8 + j(1), 16, 6.5), (24 + j(2), 15, 6.5), (13, 7 + j(3), 6), (20, 8, 6), (16, 20, 6.5)]
    copa(img, circ, semente=s, rampa="oliva")
    for k in range(9):  # azeitonas
        x = 6 + int(hash01(s, k, 4) * 20)
        y = 6 + int(hash01(s, k, 5) * 16)
        if get(img, x, y)[3] > 0:
            put(img, x, y, cor("tunica_roxa", 1))
    contornar(img, hexc("#1a2416"))
    return img


def cevada():
    """Touceira de cevada 16x20 (não bloqueia)."""
    img = nova(16, 20)
    for k in range(7):
        x0 = 2 + int(hash01(k, 61) * 12)
        h = 9 + int(hash01(k, 62) * 6)
        for j in range(h):
            x = x0 + (1 if j > h - 4 and k % 2 else 0)
            put(img, x, 18 - j, cor("cevada", 2 if j < h - 4 else 3))
        for j in range(3):  # espiga
            yy = 18 - h - j
            put(img, x0 + (1 if k % 2 else 0), yy, cor("cevada", 4 if j == 0 else 3))
            put(img, x0 + (1 if k % 2 else 0) + 1, yy + 1, cor("cevada", 1))
    contornar(img, hexc("#4a3a14"))
    return img


def horta(variante=0):
    """Canteiro de chicória e malvas 16x16 (não bloqueia)."""
    img = nova(16, 16)
    for k in range(3):
        cx, cy = 3 + k * 5, 9 + (k % 2)
        s = 600 + variante * 3 + k
        camada = nova(16, 16)
        copa(camada, [(cx + 1, cy, 3), (cx - 0.5, cy + 1.5, 2.2), (cx + 2.5, cy + 1.5, 2.2)], semente=s)
        m = camada[:, :, 3] > 0
        img[m] = camada[m]
    if variante % 2 == 1:
        for (x, y) in ((4, 7), (9, 8), (13, 7)):
            for (dx, dy) in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                put(img, x + dx, y + dy, cor("flor_li", 2))
            put(img, x, y, cor("flor_rs", 2))
    contornar(img, hexc("#1d3a1a"))
    return img


def mesa_comprida():
    """Mesa comprida 64x28 (pegada 4x1), com pães, jarra e copos."""
    img = nova(64, 28)
    _sombra(img, 32, 26, 31, 2.2, 90)
    for y in range(4, 16):
        for x in range(0, 64):
            put(img, x, y, cor("madeira", 5 if y < 6 else 4 if (x // 16 + y) % 7 else 3))
    for y in range(16, 19):
        for x in range(0, 64):
            put(img, x, y, cor("madeira", 2))
    for x in (2, 3, 60, 61, 31, 32):
        for y in range(19, 25):
            put(img, x, y, cor("madeira", 2 if x % 2 else 3))
    for (x, y) in ((10, 7), (40, 8)):  # bolos de cevada
        for yy in range(y, y + 4):
            for xx in range(x, x + 7):
                if (xx - x - 3) ** 2 / 12 + (yy - y - 1.5) ** 2 / 3 <= 1:
                    put(img, xx, yy, cor("cevada", 3 if yy < y + 2 else 2))
    for y in range(1, 10):  # jarra de água
        for x in range(26, 32):
            if (y > 2 or 27 <= x <= 30):
                put(img, x, y, cor("pedra", 4 if x < 28 else 3) if y > 2 else cor("pedra", 2))
    put(img, 32, 4, cor("pedra", 3)); put(img, 33, 5, cor("pedra", 3))
    for x0 in (18, 50):  # copos
        for y in range(5, 10):
            put(img, x0, y, cor("vidro", 3)); put(img, x0 + 1, y, cor("vidro", 2))
    return contornar(img, ESCURO)


def placa():
    """Placa de madeira 16x24 numa estaca."""
    img = nova(16, 24)
    _sombra(img, 8, 22, 4, 1.4, 90)
    for y in range(10, 22):
        put(img, 7, y, cor("madeira", 3)); put(img, 8, y, cor("madeira", 1))
    for y in range(2, 11):
        for x in range(1, 15):
            put(img, x, y, cor("madeira", 5 if y == 2 else 4 if y < 10 else 2))
    for (y, x0, x1) in ((5, 3, 12), (7, 3, 10)):
        for x in range(x0, x1):
            put(img, x, y, cor("madeira", 1))
    return contornar(img, ESCURO)


# =============================== WALDEN E A COLINA DO PORTAL ===============================

def pinheiro(variante=0):
    """Pinheiro 32x56: copa em camadas triangulares, verde-escuro, com sombra e contorno."""
    img = nova(32, 56)
    _sombra(img, 16, 53, 10, 3)
    for y in range(44, 54):
        for x in range(14, 18):
            put(img, x, y, cor("tronco", 3 if x < 16 else 1))
    s = 700 + variante
    camadas = [(4, 9), (12, 12), (21, 14), (30, 15)] if variante == 0 else [(2, 8), (10, 11), (19, 13), (28, 15)]
    for k, (topo, meia) in enumerate(camadas):
        alt = 16
        for y in range(topo, min(topo + alt, 48)):
            f = (y - topo) / alt
            w = 1 + f * meia
            for x in range(16 - int(w), 16 + int(w) + 1):
                dx = (x - 16) / max(1, w)
                i = 4 if dx < -0.35 else 3 if dx < 0.25 else 2
                if y > topo + alt - 4:
                    i -= 1
                if hash01(x, y, s) > 0.9:
                    i += 1
                put(img, x, y, cor("folha", max(0, min(5, i - (1 if variante else 0)))))
    contornar(img, hexc("#13230f"))
    return img


def cabana():
    """Cabana de Thoreau 48x64 (pegada 3x2): tábuas, telhado de ripas, chaminé de tijolo na ponta."""
    img = nova(48, 64)
    _sombra(img, 24, 61, 25, 4, 90)
    for y in range(30, 58):  # paredes de tábuas verticais
        for x in range(3, 45):
            i = 3 if (x - 3) % 5 else 1
            if hash01(x // 5, y // 9, 81) > 0.8 and i == 3:
                i = 4
            put(img, x, y, cor("madeira", i))
    for y in range(40, 58):  # porta
        for x in range(20, 29):
            put(img, x, y, cor("madeira", 2 if (x - 20) % 3 else 1))
    put(img, 27, 49, cor("milho", 2))
    for (jx) in (7, 34):  # janelas
        for y in range(38, 48):
            for x in range(jx, jx + 8):
                borda = x in (jx, jx + 7) or y in (38, 47)
                put(img, x, y, cor("madeira", 1) if borda else cor("vidro", 2 if y > 42 else 3))
    for y in range(4, 32):  # telhado
        k = (y - 4) / 28.0
        x0 = int(round(8 - 8 * k)); x1 = 48 - x0
        for x in range(x0, x1):
            yy = (y - 4) % 4
            i = 2 if yy == 3 else 3
            if (x + (2 if ((y - 4) // 4) % 2 else 0)) % 6 == 0:
                i = 2
            put(img, x, y, cor("madeira", i))
    for x in range(0, 48):
        put(img, x, 31, cor("madeira", 1)); put(img, x, 30, cor("madeira", 2))
    for y in range(0, 20):  # chaminé
        for x in range(36, 42):
            put(img, x, y, cor("tijolo", 3 if (y + (2 if x > 38 else 0)) % 4 else 1))
    for y in range(57, 60):
        for x in range(18, 31):
            put(img, x, y, cor("pedra", 3))
    return contornar(img, ESCURO)


def seixos():
    """Pedrinhas brancas e redondas da margem do Walden (não bloqueiam): cada uma com contorno próprio."""
    img = nova(16, 16)
    for (cx, cy, r) in ((4.5, 10.5, 1.9), (9.5, 12.0, 1.6), (11.5, 8.5, 1.3), (6.5, 6.5, 1.2)):
        pedra = nova(16, 16)
        for y in range(16):
            for x in range(16):
                d = math.hypot(x + 0.5 - cx, (y + 0.5 - cy) * 1.25)
                if d <= r:
                    put(pedra, x, y, cor("flor_br", 2 if y + 0.5 < cy else 1) if d < r - 0.4 or y + 0.5 < cy else cor("pedra", 4))
        contornar(pedra, hexc("#7a7a84"))
        m = pedra[:, :, 3] > 0
        img[m] = pedra[m]
    return img


def pilha_lenha():
    img = nova(32, 24)
    _sombra(img, 16, 22, 15, 2, 90)
    for fila in range(3):
        for k in range(5 - fila):
            cx = 5 + k * 5.5 + fila * 2.7
            cy = 18 - fila * 5
            for y in range(24):
                for x in range(32):
                    d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                    if d <= 2.6:
                        put(img, x, y, cor("tronco", 4 if d > 1.8 else 3) if d > 1.0 else cor("madeira", 5))
    return contornar(img, ESCURO)


def portal(aceso=False):
    """Arco de pedra da Colina do Portal 48x64 (pegada 3x1). Aceso: névoa azul brilhando dentro."""
    img = nova(48, 64)
    _sombra(img, 24, 61, 24, 3, 90)
    for y in range(4, 60):
        for x in range(2, 46):
            dx = (x + 0.5 - 24) / 21.5
            dy = (y + 0.5 - 30) / 26
            fora = dx * dx + dy * dy <= 1 or y > 30
            dx2 = (x + 0.5 - 24) / 14.5
            dy2 = (y + 0.5 - 32) / 20
            dentro = (dx2 * dx2 + dy2 * dy2 <= 1 or y > 32) and 10 <= x <= 37 and y < 60
            if fora and not dentro and 2 <= x <= 45:
                bloco = ((x // 7) + (y // 6)) % 2
                i = 3 if bloco else 2
                if (y % 6 == 0) or (x % 7 == 0):
                    i = 1
                if x < 6:
                    i += 1
                put(img, x, y, cor("pedra", i))
            elif dentro:
                if aceso:
                    v = (math.sin(x * 0.4 + y * 0.25) + 1) / 2
                    put(img, x, y, cor("agua", 4 + int(v * 2)))
                else:
                    put(img, x, y, (20, 16, 28, 140))
    for (x, y) in ((24, 6), (23, 7), (25, 7)):  # pedra-chave
        put(img, x, y, cor("milho", 2 if aceso else 1))
    return contornar(img, hexc("#25252b"))


def menir():
    img = nova(16, 32)
    _sombra(img, 8, 30, 6, 1.8, 90)
    for y in range(6, 30):
        w = 4 if y > 10 else 3
        for x in range(8 - w, 8 + w):
            i = 4 if x < 7 else 3 if x < 10 else 2
            if hash01(x, y // 3, 94) > 0.85:
                i -= 1
            put(img, x, y, cor("pedra", i))
    return contornar(img, hexc("#25252b"))


def trilho():
    """Tile 16x16 de trilho (dormentes de madeira e duas barras de ferro), na horizontal."""
    img = nova(16, 16)
    for x0 in (1, 9):  # dormentes
        for y in range(2, 15):
            for x in range(x0, x0 + 5):
                put(img, x, y, cor("madeira", 2 if x in (x0, x0 + 4) else 3))
    for yb in (4, 11):
        for x in range(16):
            put(img, x, yb, cor("metal", 3)); put(img, x, yb + 1, cor("metal", 1))
    return img


def feijoeiro():
    from gerar_arte import cultura
    return cultura("feijao", 3)


def gerar_walden():
    for v in range(2):
        salvar(pinheiro(v), caminho("objetos", "pinheiro_%d.png" % v))
    salvar(cabana(), caminho("objetos", "cabana.png"))
    salvar(seixos(), caminho("objetos", "seixos.png"))
    salvar(pilha_lenha(), caminho("objetos", "pilha_lenha.png"))
    salvar(portal(False), caminho("objetos", "portal.png"))
    salvar(portal(True), caminho("objetos", "portal_aceso.png"))
    salvar(menir(), caminho("objetos", "menir.png"))
    salvar(feijoeiro(), caminho("objetos", "feijoeiro.png"))
    salvar(trilho(), caminho("terreno", "trilho.png"))
    salvar(personagem("cabelo", "calca", "tunica_ocre", barba=True), caminho("personagens", "thoreau.png"))
    salvar(personagem("cabelo_preto", "camisa_vinho", "calca"), caminho("personagens", "lenhador.png"))


def gerar():
    salvar(personagem("cabelo_grisalho", "tunica_creme", barba=True), caminho("personagens", "epicuro.png"))
    salvar(personagem("cabelo", "tunica_azul"), caminho("personagens", "meneceu.png"))
    salvar(personagem("cabelo_preto", "tunica_roxa", barba=True), caminho("personagens", "pitocles.png"))
    salvar(personagem("cabelo_loiro", "tunica_ocre"), caminho("personagens", "herodoto.png"))
    for v in range(2):
        salvar(oliveira(v), caminho("objetos", "oliveira_%d.png" % v))
        salvar(horta(v), caminho("objetos", "horta_%d.png" % v))
    salvar(personagem("cabelo_grisalho", "tunica_roxa", "tunica_ocre", barba=True), caminho("personagens", "arkad.png"))
    salvar(personagem("cabelo_preto", "camisa_vinho", "tunica_ocre", barba=True), caminho("personagens", "mathon.png"))
    salvar(personagem("pele", "camisa_vinho", "calca"), caminho("personagens", "simon.png"))
    salvar(personagem("coracao", "tunica_azul", "tunica_azul"), caminho("personagens", "matryona.png"))
    salvar(personagem("cabelo_loiro", "camisa_branca", "tunica_creme"), caminho("personagens", "michael.png"))
    salvar(cevada(), caminho("objetos", "cevada.png"))
    gerar_walden()
    salvar(mesa_comprida(), caminho("objetos", "mesa_comprida.png"))
    salvar(placa(), caminho("objetos", "placa.png"))
