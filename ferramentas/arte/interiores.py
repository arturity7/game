"""Arte de interiores do Leaf & Lore: fundo do cômodo e móveis (tecnico.md §7).

Chamado por gerar_arte.py. O fundo de cada interior é uma imagem só (paredes, piso, janela,
tapete); os móveis são objetos separados, com profundidade e colisão (objetos.json).
"""
import math
from pixel import *  # noqa: F401,F403
from gerar_arte import caminho, _sombra, contornar

ESCURO = hexc("#1e1420")


# ---------- fundo da casa ----------
# Grade de 11 x 10 células (176 x 160 px):
#   linhas 0-2: parede do fundo (papel de parede, rodapé de madeira, janela)
#   linhas 3-8: piso de tábuas; colunas 0 e 10: paredes laterais
#   linha 9: parede da frente, com a porta na coluna 5
CASA_L, CASA_A = 11, 10


def _piso(img, x0, y0, x1, y1):
    for y in range(y0, y1):
        for x in range(x0, x1):
            fila = (y - y0) // 5
            desloc = (fila * 13) % 24
            yy = (y - y0) % 5
            i = 4
            if yy == 4:
                i = 2
            elif yy == 0:
                i = 5
            if (x + desloc) % 24 == 0 and yy < 4:
                i = 2
            if hash01((x + desloc) // 24, fila, 81) > 0.7 and i == 4:
                i = 3
            if hash01(x, y, 82) > 0.985:
                i = 3
            put(img, x, y, cor("madeira", i))


def fundo_casa():
    W, H = CASA_L * 16, CASA_A * 16
    img = nova(W, H)
    retangulo(img, 0, 0, W, H, hexc("#120c10"))
    # piso
    _piso(img, 16, 48, W - 16, H - 16)
    # papel de parede (listras) — linhas 0..2, sem as laterais
    for y in range(4, 48):
        for x in range(16, W - 16):
            listra = (x // 6) % 2
            c = hexc("#e6cf9e") if listra else hexc("#dcc08b")
            if (x % 6 == 0):
                c = hexc("#cfb07a")
            if y >= 30:  # lambri de madeira
                c = cor("madeira", 3 if (x - 16) % 8 else 1)
                if y == 30:
                    c = cor("madeira", 5)
                if y == 31:
                    c = cor("madeira", 2)
            if y >= 45:  # rodapé
                c = cor("madeira", 1 if y == 47 else 2)
            put(img, x, y, c)
    for x in range(16, W - 16):  # moldura de cima
        put(img, x, 4, cor("madeira", 2)); put(img, x, 5, cor("madeira", 4)); put(img, x, 6, cor("madeira", 1))
    # janela no meio da parede (mostra o céu e a copa de uma árvore)
    jx, jy, jw, jh = 72, 9, 32, 19
    retangulo(img, jx - 2, jy - 2, jx + jw + 2, jy + jh + 2, cor("madeira", 1))
    retangulo(img, jx - 1, jy - 1, jx + jw + 1, jy + jh + 1, cor("madeira", 4))
    for y in range(jy, jy + jh):
        for x in range(jx, jx + jw):
            c = hexc("#9fd4ee") if y < jy + 10 else hexc("#b9e2f3")
            if (x - jx - 4) ** 2 / 90 + (y - jy - 17) ** 2 / 40 <= 1:
                c = cor("folha", 4 if y < jy + 14 else 3)
            if 3 <= (x - jx) + (y - jy) * 0.6 - 6 <= 5:
                c = hexc("#e3f5fc")
            put(img, x, y, c)
    for y in range(jy, jy + jh):
        put(img, jx + jw // 2, y, cor("madeira", 4)); put(img, jx + jw // 2 - 1, y, cor("madeira", 2))
    for x in range(jx, jx + jw):
        put(img, x, jy + jh // 2, cor("madeira", 4))
    for x in range(jx - 3, jx + jw + 3):  # peitoril
        put(img, x, jy + jh + 2, cor("madeira", 5)); put(img, x, jy + jh + 3, cor("madeira", 2))
    # quadros na parede
    for (qx, qy, cor_q) in ((30, 12, "flor_li"), (130, 11, "camisa")):
        retangulo(img, qx, qy, qx + 14, qy + 12, cor("madeira", 1))
        retangulo(img, qx + 1, qy + 1, qx + 13, qy + 11, cor(cor_q, 2))
        for x in range(qx + 2, qx + 12):
            put(img, x, qy + 8 - int(2 * math.sin((x - qx) * 0.7)), cor("folha", 4))
        put(img, qx + 9, qy + 3, cor("flor_am", 2))
    # sombra da parede sobre o piso
    for y in range(48, 52):
        for x in range(16, W - 16):
            put(img, x, y, (30, 15, 8, 110 - (y - 48) * 25))
    # paredes laterais e da frente (topo grosso de madeira escura)
    def topo_parede(x0, y0, x1, y1):
        for y in range(y0, y1):
            for x in range(x0, x1):
                put(img, x, y, cor("madeira", 1))
        for x in range(x0, x1):
            put(img, x, y0, cor("madeira", 3))
        for y in range(y0, y1):
            put(img, x0, y, cor("madeira", 2))
            put(img, x1 - 1, y, cor("madeira", 0))
    topo_parede(4, 0, 16, H)
    topo_parede(W - 16, 0, W - 4, H)
    topo_parede(4, 0, W - 4, 4)
    topo_parede(4, H - 16, 5 * 16, H - 4)
    topo_parede(6 * 16, H - 16, W - 4, H - 4)
    # porta (vão na parede da frente) com capacho
    for y in range(H - 16, H):
        for x in range(5 * 16, 6 * 16):
            put(img, x, y, cor("madeira", 2) if y < H - 4 else hexc("#120c10"))
    for y in range(H - 30, H - 19):
        for x in range(5 * 16 + 1, 6 * 16 - 1):
            put(img, x, y, cor("telhado", 3 if (x + y) % 4 < 2 else 2))
    for x in range(5 * 16 + 1, 6 * 16 - 1):
        put(img, x, H - 30, cor("telhado", 4)); put(img, x, H - 20, cor("telhado", 1))
    # tapete no meio do piso
    tx0, ty0, tx1, ty1 = 3 * 16 + 4, 5 * 16 + 2, 8 * 16 - 4, 8 * 16 + 2
    for y in range(ty0, ty1):
        for x in range(tx0, tx1):
            b = min(x - tx0, y - ty0, tx1 - 1 - x, ty1 - 1 - y)
            if b == 0:
                c = cor("telhado", 1)
            elif b <= 2:
                c = cor("flor_am", 1 if b == 1 else 0)
            else:
                c = cor("telhado", 3 if ((x - tx0) // 4 + (y - ty0) // 4) % 2 else 2)
                if (x - (tx0 + tx1) // 2) ** 2 / 120 + (y - (ty0 + ty1) // 2) ** 2 / 40 <= 1:
                    c = cor("flor_am", 1)
            put(img, x, y, c)
    return img


def fundo_casa_noite():
    """Só a janela, à noite (céu escuro com estrelas e lua), para pôr por cima do fundo."""
    W, H = CASA_L * 16, CASA_A * 16
    img = nova(W, H)
    jx, jy, jw, jh = 72, 9, 32, 19
    for y in range(jy, jy + jh):
        for x in range(jx, jx + jw):
            c = hexc("#1b2447") if y < jy + 10 else hexc("#24305a")
            if (x - jx - 4) ** 2 / 90 + (y - jy - 17) ** 2 / 40 <= 1:
                c = hexc("#13261c")
            if hash01(x, y, 95) > 0.96 and y < jy + 12:
                c = hexc("#f4f0d0")
            if (x - jx - 25) ** 2 + (y - jy - 5) ** 2 <= 6:
                c = hexc("#f6eebd")
            put(img, x, y, c)
    for y in range(jy, jy + jh):
        put(img, jx + jw // 2, y, cor("madeira", 4)); put(img, jx + jw // 2 - 1, y, cor("madeira", 2))
    for x in range(jx, jx + jw):
        put(img, x, jy + jh // 2, cor("madeira", 4))
    return img


# ---------- móveis ----------

def cama():
    """Cama 32x40 (pegada 2x2): cabeceira de madeira, travesseiro, colcha de retalhos."""
    img = nova(32, 40)
    _sombra(img, 16, 38, 15, 2.5, 90)
    for y in range(0, 12):  # cabeceira
        for x in range(1, 31):
            i = 4 if 3 < x < 28 else 2
            if y < 2:
                i = 5
            if x in (1, 30) or y == 11:
                i = 1
            put(img, x, y, cor("madeira", i))
    for x in (2, 29):
        for y in range(0, 37):
            put(img, x, y, cor("madeira", 2))
    for y in range(10, 36):  # colchão e lençol
        for x in range(3, 29):
            put(img, x, y, cor("flor_br", 1 if y > 32 else 2))
    for y in range(12, 19):  # travesseiro
        for x in range(6, 26):
            if not (y in (12, 18) and x in (6, 25)):
                put(img, x, y, cor("flor_br", 2 if y < 16 else 1))
    for y in range(19, 36):  # colcha de retalhos
        for x in range(3, 29):
            q = ((x - 3) // 6 + (y - 19) // 6) % 3
            rampa = ("telhado", "camisa", "flor_am")[q]
            i = 3 if rampa != "flor_am" else 1
            if (x - 3) % 6 == 0 or (y - 19) % 6 == 0:
                i = max(0, i - 1)
            if y == 19:
                i += 1
            put(img, x, y, cor(rampa, i))
    for x in range(3, 29):
        put(img, x, 36, cor("madeira", 1))
    contornar(img, ESCURO)
    return img


def estante():
    """Estante 32x48 cheia de livros (pegada 2x1, encostada na parede)."""
    img = nova(32, 48)
    _sombra(img, 16, 46, 15, 2, 90)
    for y in range(0, 46):
        for x in range(0, 32):
            i = 3
            if x in (0, 1, 30, 31) or y < 2:
                i = 4 if x < 2 or y < 2 else 2
            put(img, x, y, cor("madeira", i))
    cores = ["telhado", "camisa", "folha", "flor_li", "flor_am", "milho", "calca", "cenoura"]
    for k, prat in enumerate((3, 17, 31)):
        for y in range(prat, prat + 12):
            for x in range(2, 30):
                put(img, x, y, cor("madeira", 1))
        x = 3
        n = 0
        while x < 29:
            w = 2 + int(hash01(k, n, 91) * 2)
            h = 8 + int(hash01(k, n, 92) * 4)
            rampa = cores[int(hash01(k, n, 93) * len(cores))]
            if hash01(k, n, 94) > 0.88 and x < 25:  # livro deitado
                for yy in range(prat + 9, prat + 12):
                    for xx in range(x, x + 6):
                        put(img, xx, yy, cor(rampa, 2 if yy > prat + 9 else 3))
                x += 7
                n += 1
                continue
            for yy in range(prat + 12 - h, prat + 12):
                for xx in range(x, min(29, x + w)):
                    i = 3 if xx == x else 2
                    if yy == prat + 12 - h:
                        i = 3
                    put(img, xx, yy, cor(rampa, max(0, min(len(RAMPAS[rampa]) - 1, i))))
            put(img, x, prat + 12 - h + 3, cor("flor_am", 2))
            x += w
            n += 1
        for x in range(2, 30):  # tábua da prateleira
            put(img, x, prat + 12, cor("madeira", 5)); put(img, x, prat + 13, cor("madeira", 2))
    contornar(img, ESCURO)
    return img


def mesa():
    """Mesa 32x26 (pegada 2x1) com toalha e uma vela."""
    img = nova(32, 26)
    _sombra(img, 16, 24, 15, 2.2, 90)
    for y in range(4, 16):
        for x in range(0, 32):
            put(img, x, y, cor("madeira", 5 if y < 6 else 4))
    for y in range(16, 19):
        for x in range(0, 32):
            put(img, x, y, cor("madeira", 2))
    for x in (1, 2, 29, 30):  # pés
        for y in range(19, 24):
            put(img, x, y, cor("madeira", 2 if x in (2, 30) else 3))
    for y in range(5, 17):  # toalha
        for x in range(8, 24):
            put(img, x, y, cor("flor_br", 2 if (x // 2 + y // 2) % 2 else 1))
    for y in range(0, 8):  # vela
        put(img, 15, y + 2, cor("papel", 3)); put(img, 16, y + 2, cor("papel", 2))
    put(img, 15, 0, cor("flor_am", 2)); put(img, 15, 1, cor("cenoura", 2)); put(img, 16, 1, cor("flor_am", 1))
    contornar(img, ESCURO)
    return img


def cadeira():
    img = nova(16, 26)
    _sombra(img, 8, 24, 7, 1.8, 90)
    for y in range(0, 12):  # encosto
        for x in (3, 4, 11, 12):
            put(img, x, y, cor("madeira", 4 if x in (3, 11) else 2))
        if y in (1, 2, 6, 7):
            for x in range(3, 13):
                put(img, x, y, cor("madeira", 5 if y in (1, 6) else 3))
    for y in range(12, 16):  # assento
        for x in range(2, 14):
            put(img, x, y, cor("madeira", 5 if y == 12 else 4 if y < 15 else 2))
    for x in (3, 12):
        for y in range(16, 23):
            put(img, x, y, cor("madeira", 2))
    contornar(img, ESCURO)
    return img


def vaso():
    img = nova(16, 26)
    _sombra(img, 8, 24, 6, 1.6, 90)
    for y in range(15, 23):
        w = 5 if y < 17 else 4
        for x in range(8 - w, 8 + w):
            put(img, x, y, cor("telhado", 4 if x < 7 else 3) if y > 15 else cor("telhado", 5))
    from gerar_arte import copa
    folhas = nova(16, 26)
    copa(folhas, [(8, 9, 5), (4.5, 11, 3.2), (11.5, 11, 3.2), (8, 5, 3.5)], semente=17)
    m = folhas[:, :, 3] > 0
    m[15:, :] = False
    img[m] = folhas[m]
    contornar(img, ESCURO)
    return img


def gerar():
    salvar(fundo_casa(), caminho("interiores", "casa.png"))
    salvar(fundo_casa_noite(), caminho("interiores", "casa_noite.png"))
    salvar(cama(), caminho("objetos", "cama.png"))
    salvar(estante(), caminho("objetos", "estante.png"))
    salvar(mesa(), caminho("objetos", "mesa.png"))
    salvar(cadeira(), caminho("objetos", "cadeira.png"))
    salvar(vaso(), caminho("objetos", "vaso.png"))
