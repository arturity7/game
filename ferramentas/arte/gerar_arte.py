"""Gera toda a arte do Leaf & Lore em game/assets/sprites/ (tecnico.md §7).

Uso: python3 ferramentas/arte/gerar_arte.py
Estilo: top-down de pixel art com cores vivas e contorno escuro quente, na linha de
Pokémon (GBA) e Stardew Valley, com desenho e paleta próprios.
"""
import os
import sys
import math
sys.path.insert(0, os.path.dirname(__file__))
from pixel import *  # noqa: E402,F401,F403

RAIZ = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "sprites")

def caminho(*partes):
    p = os.path.join(RAIZ, *partes)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


# =============================== TERRENO ===============================

def grama():
    """8 variações de grama 16x16: lisas, com tufos e com flores. Base quase lisa (estilo GBA)."""
    atlas = nova(16 * 8, 16)
    for v in range(8):
        t = nova(16, 16)
        for y in range(16):
            for x in range(16):
                h = hash01(v, x, y, 7)
                c = cor("grama", 3)
                if h > 0.94:
                    c = cor("grama", 4)
                elif h < 0.05:
                    c = cor("grama", 2)
                put(t, x, y, c)
        n_tufos = [1, 2, 2, 3, 4, 3, 2, 2][v]
        for k in range(n_tufos):
            tx = 2 + int(hash01(v, k, 1) * 11)
            ty = 3 + int(hash01(v, k, 2) * 10)
            # tufo em "v": duas folhinhas claras com sombra embaixo
            put(t, tx, ty, cor("grama", 5))
            put(t, tx + 3, ty, cor("grama", 5))
            put(t, tx + 1, ty + 1, cor("grama", 4))
            put(t, tx + 2, ty + 1, cor("grama", 4))
            put(t, tx, ty + 1, cor("grama", 2))
            put(t, tx + 3, ty + 1, cor("grama", 2))
            put(t, tx + 1, ty + 2, cor("grama", 2))
            put(t, tx + 2, ty + 2, cor("grama", 2))
        if v in (6, 7):
            for k in range(2 if v == 6 else 3):
                rampa = "flor_am" if v == 6 else ["flor_rs", "flor_br", "flor_li"][k % 3]
                fx = 3 + int(hash01(v, k, 3) * 9)
                fy = 3 + int(hash01(v, k, 4) * 9)
                put(t, fx, fy - 1, cor(rampa, 2))
                put(t, fx - 1, fy, cor(rampa, 2))
                put(t, fx + 1, fy, cor(rampa, 1))
                put(t, fx, fy + 1, cor(rampa, 1))
                put(t, fx, fy, cor("flor_am", 2) if rampa != "flor_am" else cor("flor_am", 0))
                put(t, fx + 1, fy + 1, cor("grama", 1))
        atlas[:, v * 16:(v + 1) * 16] = t
    return atlas


def grama_tom(escura=True):
    """Manchas grandes de grama mais escura ou mais clara (grade dupla), por baixo de tudo.
    Quebram o verde liso como no chão do Stardew; a borda é pontilhada para sumir aos poucos."""
    base = hexc("#599c3a") if escura else hexc("#71b444")
    risco = cor("grama", 2) if escura else cor("grama", 4)
    brilho = cor("grama", 4) if escura else cor("grama", 5)
    def pintar(img, x, y, s, wx, wy, q, m):
        if s > 0:
            return
        if s > -1.6 and (wx + wy) % 2 == 0:
            return            # borda pontilhada
        if s > -3.0 and (wx + wy) % 4 == 1 and wy % 2 == 1:
            return
        c = base
        h = hash01(wx, wy, 61 if escura else 62)
        if h > 0.93:
            c = risco
        elif h < 0.03:
            c = brilho
        put(img, x, y, c)
        # folhinhas: risco curto de 2 px
        if hash01(wx, wy, 63 if escura else 64) > 0.95 and y > 0:
            put(img, x, y, risco)
            put(img, x, y - 1, risco)
    return tiles_dual(pintar, variantes=2, raio=6.0, ruido=1.4, semente=17 if escura else 19)


def terra_campo():
    def pintar(img, x, y, s, wx, wy, q, m):
        if s <= 0:
            n = valor_suave(wx, wy, 3, 11)
            c = cor("terra", 3)
            if n > 0.7:
                c = cor("terra", 4)
            elif n < 0.28:
                c = cor("terra", 2)
            if hash01(wx, wy, 12) > 0.97:
                c = cor("terra", 5)
            if s > -1.1:
                c = cor("terra", 1)
            elif s > -2.2:
                c = cor("terra", 2)
            put(img, x, y, c)
        elif s <= 1.0 and hash01(wx, wy, 13) > 0.45:
            put(img, x, y, cor("grama", 2))
    return tiles_dual(pintar, variantes=3, raio=6.0, ruido=0.8, semente=3)


def caminho_terra():
    def pintar(img, x, y, s, wx, wy, q, m):
        if s <= 0:
            n = valor_suave(wx, wy, 4, 21)
            c = cor("caminho", 3) if n > 0.4 else cor("caminho", 2)
            h = hash01(wx // 3, wy // 3, 22)
            if h > 0.8 and wx % 3 != 2 and wy % 3 != 2:   # pedrinhas
                c = cor("caminho", 4) if wy % 3 == 0 else cor("caminho", 1)
            if s > -1.0:
                c = cor("caminho", 1)
            put(img, x, y, c)
        elif s <= 1.0:
            put(img, x, y, cor("grama", 1, 170))
    return tiles_dual(pintar, variantes=3, raio=5.0, ruido=0.5, semente=5)


def agua():
    def pintar(img, x, y, s, wx, wy, q, m):
        if s <= 0:
            if s > -1.0:
                c = cor("agua", 6) if hash01(wx, wy, q, 31) > 0.3 else cor("agua", 5)
            elif s > -2.2:
                c = cor("agua", 4)
            elif s > -4.0:
                c = cor("agua", 3)
            else:
                c = cor("agua", 2)
            # brilhos curtos que andam com o quadro da animação
            bx = (wx + q * 3) % 16
            if s < -3.0 and wy in (3, 11) and 2 <= (bx + (5 if wy == 11 else 0)) % 16 <= 4:
                c = cor("agua", 4)
            if s < -3.0 and wy in (4, 12) and 3 <= (bx + (5 if wy == 12 else 0)) % 16 <= 5:
                c = cor("agua", 5)
            put(img, x, y, c)
        elif s <= 1.0:
            put(img, x, y, cor("terra", 2))
        elif s <= 2.0:
            put(img, x, y, cor("grama", 1, 150))
    return tiles_dual(pintar, n_quadros=3, variantes=2, raio=7.0, ruido=0.9, semente=9)


def solo(molhado=False):
    r = "molhado" if molhado else "arado"
    def pintar(img, x, y, s, wx, wy, q, m):
        if s <= 0:
            linha = wy % 4
            c = cor(r, 2)
            if linha == 0:
                c = cor(r, 1)
            elif linha == 1:
                c = cor(r, 3)
            if hash01(wx, wy, 41) > 0.9:
                c = cor(r, 4 if linha == 1 else 0)
            if s > -1.0:
                c = cor(r, 0)
            put(img, x, y, c)
        elif s <= 1.0 and not molhado:
            put(img, x, y, (20, 12, 8, 110))
    return tiles_dual(pintar, raio=4.0, ruido=0.0)


# =============================== OBJETOS ===============================

def _sombra(img, cx, cy, rx, ry, alfa=80):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1 and get(img, x, y)[3] == 0:
                put(img, x, y, (18, 30, 12, alfa))


def copa(img, circulos, luz=(-0.55, -0.8), semente=0, rampa="folha", deslocar=0):
    """Copa de árvore: união de círculos com tufos de folhas sombreados (luz de cima à esquerda)."""
    xs = [c[0] for c in circulos]; ys = [c[1] for c in circulos]
    cx0 = sum(xs) / len(xs); cy0 = sum(ys) / len(ys)
    raio_total = max(math.hypot(c[0] - cx0, c[1] - cy0) + c[2] for c in circulos)
    h, w = img.shape[:2]
    # tufos: pequenos círculos espalhados dentro da copa
    tufos = []
    for k in range(140):
        tx = cx0 + (hash01(semente, k, 1) * 2 - 1) * raio_total
        ty = cy0 + (hash01(semente, k, 2) * 2 - 1) * raio_total
        if any(math.hypot(tx - c[0], ty - c[1]) < c[2] - 2 for c in circulos):
            tufos.append((tx, ty, 3.0 + hash01(semente, k, 3) * 2.5))
    tufos.sort(key=lambda t: t[1])
    for y in range(h):
        for x in range(w):
            px, py = x + 0.5, y + 0.5
            dentro = any(math.hypot(px - c[0], py - c[1]) <= c[2] for c in circulos)
            if not dentro:
                continue
            # luz geral: posição na copa
            nx = (px - cx0) / raio_total; ny = (py - cy0) / raio_total
            geral = -(nx * luz[0] + ny * luz[1]) * 0.9 - ny * 0.25
            # luz do tufo mais à frente (o de maior y que contém o pixel)
            loc = -0.15
            for tx, ty, tr in reversed(tufos):
                dx, dy = px - tx, py - ty
                if dx * dx + dy * dy <= tr * tr:
                    loc = -(dx * luz[0] + dy * luz[1]) / tr * 0.9
                    if dx * dx + dy * dy > (tr - 1.0) ** 2 and dy > 0:
                        loc -= 0.6  # borda de baixo do tufo, sombra
                    break
            v = geral + loc * 0.8
            i = int(round(3.1 + v * 2.2)) + deslocar
            put(img, x, y, cor(rampa, max(0, min(6, i))))


def tronco(img, x0, x1, y0, y1, raizes=True):
    for y in range(y0, y1):
        for x in range(x0, x1):
            f = (x - x0) / max(1, (x1 - x0 - 1))
            i = 3 if f < 0.3 else 2 if f < 0.7 else 1
            if hash01(x, y // 2, 5) > 0.82:
                i = max(0, i - 1)
            put(img, x, y, cor("tronco", i))
    if raizes:
        for k, dx in enumerate((-2, -1, x1 - x0, x1 - x0 + 1)):
            for y in range(y1 - 2 + (1 if abs(dx) > 1 and dx < 0 or dx > x1 - x0 else 0), y1):
                put(img, x0 + dx, y, cor("tronco", 2 if dx < 0 else 1))


def arvore(variante=0):
    """Árvore redonda 32x48 (base no rodapé; colisão de 1 tile no tronco)."""
    img = nova(32, 48)
    _sombra(img, 16, 44, 12, 3.5)
    tronco(img, 13, 19, 30, 45)
    s = 100 + variante
    j = lambda k: (hash01(s, k) - 0.5) * 2
    circ = [(16, 16, 12.5), (9 + j(1), 20, 7.5), (23 + j(2), 20, 7.5), (16, 8 + j(3), 8.5),
            (11, 25, 6.5), (21, 25, 6.5), (16, 26, 7)]
    copa(img, circ, semente=s, deslocar=0 if variante % 2 == 0 else -1)
    contornar(img, hexc("#13230f"))
    return img


def arvore_grande(variante=0):
    """Árvore alta 48x72 (carvalho)."""
    img = nova(48, 72)
    _sombra(img, 24, 67, 17, 4.5)
    tronco(img, 20, 28, 44, 68)
    s = 200 + variante
    j = lambda k: (hash01(s, k) - 0.5) * 3
    circ = [(24, 22, 16), (12 + j(1), 28, 10), (36 + j(2), 28, 10), (24, 11 + j(3), 11),
            (14, 16, 8), (34, 16, 8), (17, 36, 9), (31, 36, 9), (24, 38, 9)]
    copa(img, circ, semente=s)
    contornar(img, hexc("#13230f"))
    return img


def arbusto(variante=0):
    img = nova(16, 16)
    _sombra(img, 8, 13.5, 7, 2.2)
    s = 300 + variante
    copa(img, [(8, 9, 6), (4.5, 10.5, 3.8), (11.5, 10.5, 3.8), (8, 6, 4)], semente=s)
    if variante == 1:
        for k in range(4):
            bx = 4 + int(hash01(s, k, 9) * 8); by = 5 + int(hash01(s, k, 8) * 6)
            put(img, bx, by, cor("flor_rs", 1)); put(img, bx, by - 1, cor("flor_rs", 2))
    contornar(img, hexc("#13230f"))
    return img


def toco():
    """Toco de árvore cortada (16x16): anéis no topo, raízes e sombra."""
    img = nova(16, 16)
    _sombra(img, 8, 13.5, 7, 2.2)
    for y in range(7, 14):
        for x in range(3, 13):
            f = (x - 3) / 9.0
            put(img, x, y, cor("tronco", 3 if f < 0.3 else 2 if f < 0.75 else 1))
    for (x, y) in ((2, 12), (2, 13), (13, 12), (13, 13), (5, 14), (11, 14)):
        put(img, x, y, cor("tronco", 2))
    for y in range(4, 9):   # topo cortado (elipse) com anéis
        for x in range(3, 13):
            dx, dy = (x + 0.5 - 8) / 5.0, (y + 0.5 - 6.8) / 2.2
            r = dx * dx + dy * dy
            if r <= 1:
                put(img, x, y, cor("madeira", 4 if r > 0.55 else 5 if r > 0.2 else 4))
    put(img, 8, 6, cor("madeira", 2)); put(img, 7, 6, cor("madeira", 3))
    contornar(img, hexc("#21140d"))
    return img


def pedra(variante=0):
    img = nova(16, 16)
    _sombra(img, 8, 13, 6.5, 2)
    for y in range(16):
        for x in range(16):
            dx, dy = (x + 0.5 - 8) / 5.8, (y + 0.5 - 10) / 4.2
            if dx * dx + dy * dy <= 1:
                v = -(dx * -0.6 + dy * -0.8)
                i = int(round(2.5 + v * 1.6))
                if hash01(x, y, variante, 4) > 0.9:
                    i -= 1
                put(img, x, y, cor("pedra", max(0, min(5, i))))
    contornar(img, hexc("#1d1d22"))
    return img


def cercas():
    """16 tiles de cerca conforme os vizinhos (N=1, L=2, S=4, O=8). O poste fica no centro."""
    atlas = nova(16 * 16, 32)
    for m in range(16):
        t = nova(16, 32)
        n, l, s, o = m & 1, m & 2, m & 4, m & 8
        _sombra(t, 8, 30, 5, 1.6, 70)
        def ripa(x0, x1, y0, y1):
            for y in range(y0, y1):
                for x in range(x0, x1):
                    put(t, x, y, cor("madeira", 5 if y == y0 else 3 if y < y1 - 1 else 2))
        if o:
            ripa(0, 7, 20, 23); ripa(0, 7, 25, 28)
        if l:
            ripa(9, 16, 20, 23); ripa(9, 16, 25, 28)
        if n:
            for y in range(0, 18):
                for x in (7, 8):
                    put(t, x, y, cor("madeira", 4 if x == 7 else 2))
        if s:
            for y in range(28, 32):
                for x in (7, 8):
                    put(t, x, y, cor("madeira", 4 if x == 7 else 2))
        for y in range(16, 30):  # poste
            for x in range(6, 10):
                i = 5 if x == 6 else 4 if x == 7 else 3 if x == 8 else 2
                if y == 16:
                    i = 6
                put(t, x, y, cor("madeira", i))
        contornar(t, hexc("#26150c"))
        atlas[:, m * 16:(m + 1) * 16] = t
    return atlas


def casa():
    """Casa da fazenda 96x112: telhado de telhas, paredes de tábuas, porta, janelas e chaminé.
    Pegada de colisão: 6x3 tiles no rodapé (as paredes)."""
    W, H = 96, 112
    img = nova(W, H)
    _sombra(img, 48, 108, 50, 5, 90)
    # fundação de pedra
    for y in range(98, 106):
        for x in range(2, 94):
            bloco = ((x + (4 if (y - 98) // 4 % 2 else 0)) // 8)
            i = 3 if (y - 98) % 4 == 0 else 2
            if (x + (4 if (y - 98) // 4 % 2 else 0)) % 8 == 0:
                i = 1
            if hash01(bloco, (y - 98) // 4, 61) > 0.7 and i == 2:
                i = 3
            put(img, x, y, cor("pedra", i))
    # paredes de tábuas horizontais
    for y in range(52, 98):
        for x in range(4, 92):
            tab = (y - 52) // 5
            i = 4
            if (y - 52) % 5 == 4:
                i = 2
            elif (y - 52) % 5 == 0:
                i = 5
            if hash01(x // 11 + tab * 3, tab, 62) > 0.8 and i == 4:
                i = 3
            put(img, x, y, cor("madeira", i))
    for y in range(52, 98):  # cantos
        for x in list(range(4, 8)) + list(range(88, 92)):
            put(img, x, y, cor("madeira", 2 if x in (7, 91) else 3 if x in (6, 90) else 4))
    # sombra do beiral sobre a parede
    for y in range(52, 56):
        for x in range(4, 92):
            put(img, x, y, (30, 15, 8, 120 - (y - 52) * 25))
    # janelas
    for jx in (12, 70):
        for y in range(62, 80):
            for x in range(jx, jx + 16):
                put(img, x, y, cor("madeira", 1))
        for y in range(64, 78):
            for x in range(jx + 2, jx + 14):
                v = (x - jx) + (y - 64)
                i = 1 if y > 72 else 2
                if 4 <= v <= 6 or 9 <= v <= 10:
                    i = 4
                put(img, x, y, cor("vidro", i))
        for y in range(64, 78):
            put(img, jx + 7, y, cor("madeira", 1)); put(img, jx + 8, y, cor("madeira", 3))
        for x in range(jx + 2, jx + 14):
            put(img, x, 70, cor("madeira", 1)); put(img, x, 71, cor("madeira", 3))
        for x in range(jx - 1, jx + 17):  # jardineira com flores
            for y in range(80, 84):
                put(img, x, y, cor("madeira", 2 if y == 83 else 3))
        for k in range(8):
            fx = jx + 1 + k * 2
            put(img, fx, 79, cor("flor_rs" if k % 2 else "flor_am", 2))
            put(img, fx, 78, cor("folha", 4))
    # porta
    for y in range(66, 98):
        for x in range(48, 64):
            put(img, x, y, cor("madeira", 1))
    for y in range(68, 98):
        for x in range(50, 62):
            i = 3 if (x - 50) % 4 == 0 else 2
            if y in (75, 87):
                i = 1
            put(img, x, y, cor("madeira", i))
    put(img, 59, 83, cor("flor_am", 2)); put(img, 59, 84, cor("flor_am", 0))
    for x in range(46, 66):  # degrau
        for y in range(98, 102):
            put(img, x, y, cor("pedra", 4 if y == 98 else 3))
    # telhado (visto de frente, inclinado para trás)
    for y in range(6, 54):
        k = (y - 6) / 48.0
        x0 = int(round(12 - 12 * k)); x1 = W - x0
        for x in range(x0, x1):
            fileira = (y - 6) // 6
            desloc = 4 if fileira % 2 else 0
            yy = (y - 6) % 6
            i = 4
            if yy == 5:
                i = 1
            elif yy == 4:
                i = 2
            elif yy == 0:
                i = 5
            if (x + desloc) % 8 == 0 and yy < 5:
                i = 2
            if hash01((x + desloc) // 8, fileira, 63) > 0.85 and i == 4:
                i = 3
            if x - x0 < 2 or x1 - x < 3:
                i = min(i, 2)
            put(img, x, y, cor("telhado", i))
    for x in range(12, 84):  # cumeeira
        for y in range(3, 7):
            put(img, x, y, cor("telhado", 2 if y == 6 else 3 if y > 3 else 5))
    for x in range(0, W):  # beiral
        for y in range(52, 55):
            if get(img, x, y)[3] == 0 or y < 54:
                put(img, x, y, cor("telhado", 1 if y == 54 else 2))
    # chaminé de pedra
    for y in range(0, 24):
        for x in range(68, 78):
            i = 3 if (y + (2 if (x // 5) % 2 else 0)) % 5 else 1
            if x == 68:
                i = 4
            put(img, x, y, cor("pedra", i))
    for x in range(67, 79):
        put(img, x, 0, cor("pedra", 5))
    contornar(img, hexc("#21140d"))
    return img


def casa_janelas():
    """Vidros acesos da casa (mesmo tamanho de casa.png), mostrados à noite por cima da casa."""
    img = nova(96, 112)
    for jx in (12, 70):
        for y in range(64, 78):
            for x in range(jx + 2, jx + 14):
                if x in (jx + 7, jx + 8) or y in (70, 71):
                    continue
                v = (x - jx) + (y - 64)
                c = hexc("#ffe7a3") if 4 <= v <= 7 else hexc("#ffc861") if y < 72 else hexc("#f3a447")
                put(img, x, y, c)
    return img


def enfeite(tipo, variante=0):
    """Enfeites pequenos (16x16) que não bloqueiam: mato alto, flores, cogumelo, pedrinhas."""
    c = nova(16, 16)
    s = 400 + variante * 7 + len(tipo)
    if tipo == "mato":
        _sombra(c, 8, 13.5, 5, 1.4, 60)
        for k in range(7):
            x0 = 4 + int(hash01(s, k, 1) * 8)
            h = 5 + int(hash01(s, k, 2) * 5)
            inc = -1 if hash01(s, k, 3) < 0.5 else 1
            for j in range(h):
                x = x0 + (inc if j > h * 0.6 else 0)
                put(c, x, 13 - j, cor("grama", 5 if j > h - 3 else 4 if j > h // 2 else 2))
        contornar(c, hexc("#1d3a1a"))
    elif tipo == "flores":
        rampa = ["flor_am", "flor_li", "flor_rs", "flor_br"][variante % 4]
        for k, (fx, fy) in enumerate(((5, 7), (10, 6), (8, 10), (4, 11), (11, 10))):
            for j in range(13 - fy):
                put(c, fx, fy + 1 + j, cor("folha", 4))
            put(c, fx - 1, fy + 3, cor("folha", 5)); put(c, fx + 1, fy + 4, cor("folha", 5))
        contornar(c, hexc("#1d3a1a"))
        for k, (fx, fy) in enumerate(((5, 7), (10, 6), (8, 10), (4, 11), (11, 10))):
            for (dx, dy) in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                put(c, fx + dx, fy + dy, cor(rampa, 2 if dy < 0 or dx < 0 else 1))
            put(c, fx, fy, cor("flor_am", 0) if rampa != "flor_am" else cor("tronco", 3))
    elif tipo == "cogumelo":
        _sombra(c, 8, 13.5, 4.5, 1.3, 70)
        for (cx, cy, r) in ((7, 9, 3.2), (11, 11, 2.2)):
            for y in range(int(cy), 14):
                put(c, int(cx), y, cor("papel", 3)); put(c, int(cx) - 1, y, cor("papel", 2)) if r > 3 else None
            for y in range(16):
                for x in range(16):
                    dx, dy = (x + 0.5 - cx) / r, (y + 0.5 - cy) / (r * 0.75)
                    if dx * dx + dy * dy <= 1 and y + 0.5 <= cy + 0.3:
                        put(c, x, y, cor("coracao", 3 if dy < -0.4 and dx < 0.2 else 2 if dx < 0.4 else 1))
            put(c, int(cx) - 1, int(cy) - 2, cor("flor_br", 2)); put(c, int(cx) + 1, int(cy) - 1, cor("flor_br", 1))
        contornar(c, hexc("#2a1414"))
    elif tipo == "pedrinhas":
        for (cx, cy, rx, ry) in ((6, 11, 2.6, 1.8), (10.5, 12, 1.8, 1.3), (8.5, 8.5, 1.4, 1.1)):
            for y in range(16):
                for x in range(16):
                    dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
                    if dx * dx + dy * dy <= 1:
                        put(c, x, y, cor("pedra", 4 if dy < -0.2 else 3 if dx < 0.3 else 2))
        contornar(c, hexc("#25252b"))
    return c


def gerar_objetos():
    for v in range(3):
        salvar(arvore(v), caminho("objetos", "arvore_%d.png" % v))
    for v in range(2):
        salvar(arvore_grande(v), caminho("objetos", "arvore_grande_%d.png" % v))
        salvar(arbusto(v), caminho("objetos", "arbusto_%d.png" % v))
        salvar(pedra(v), caminho("objetos", "pedra_%d.png" % v))
    salvar(cercas(), caminho("objetos", "cerca.png"))
    salvar(toco(), caminho("objetos", "toco.png"))
    for nome, tipo, v in (("mato_0", "mato", 0), ("mato_1", "mato", 1), ("mato_2", "mato", 2),
                          ("flores_0", "flores", 0), ("flores_1", "flores", 1), ("flores_2", "flores", 2),
                          ("flores_3", "flores", 3), ("cogumelo", "cogumelo", 0), ("pedrinhas", "pedrinhas", 0)):
        salvar(enfeite(tipo, v), caminho("objetos", "enfeite_%s.png" % nome))
    salvar(casa(), caminho("objetos", "casa.png"))
    salvar(casa_janelas(), caminho("objetos", "casa_janelas.png"))



# =============================== PERSONAGEM ===============================
# Cabeças desenhadas à mão (12 linhas x 16 colunas). Corpo desenhado por código.
CHAVES = {
    "o": hexc("#1e1420"), "h": cor("cabelo", 1), "H": cor("cabelo", 3), "j": cor("cabelo", 4),
    "k": cor("pele", 3), "K": cor("pele", 4), "S": cor("pele", 2), "s": cor("pele", 1),
    "e": hexc("#241826"), "w": hexc("#f4f0e8"), "r": hexc("#ec8f78"),
}
CABECA = {
    "baixo": [
        ".....oooooo.....",
        "...ooHHHHHHoo...",
        "..oHHjjHHHHHHo..",
        ".oHHjjHHHHHHHHo.",
        ".oHHHHHHHHHHHHo.",
        ".ohHHhhHHhhHHho.",
        ".ohhkkhkkhkkhho.",
        ".ohkkkkkkkkkkho.",
        ".ohkkekkkkekkho.",
        ".ohkkekkkkekkho.",
        "..oSrkkkkkkrSo..",
        "...oosSSSSsoo...",
    ],
    "cima": [
        ".....oooooo.....",
        "...ooHHHHHHoo...",
        "..oHHjjHHHHHHo..",
        ".oHHjjHHHHHHHHo.",
        ".oHHHHHHHHHHHHo.",
        ".ohHHHHHHHHHHho.",
        ".ohhHHHHHHHHhho.",
        ".ohhhHHHHHHhhho.",
        ".ohhhhhhhhhhhho.",
        ".ohhhhhhhhhhhho.",
        "..ohhhhhhhhhho..",
        "...oosSSSSsoo...",
    ],
    "esquerda": [
        ".....oooooo.....",
        "...ooHHHHHHoo...",
        "..oHHjjHHHHHHo..",
        ".oHHjjHHHHHHHHo.",
        ".oHHHHHHHHHHHHo.",
        ".ohHHHHHHHHHHho.",
        ".ohhhhhHHHHHhho.",
        ".okkkkhhhHHhhho.",
        ".okekkkhhhhhhho.",
        ".okekkkkShhhhho.",
        "..oSrkkkSShhho..",
        "...oosSSSsooo...",
    ],
}


def _molde(img, linhas, ox, oy, espelhar=False):
    for y, linha in enumerate(linhas):
        for x, ch in enumerate(linha):
            if ch == ".":
                continue
            xx = (15 - x) if espelhar else x
            put(img, ox + xx, oy + y, CHAVES[ch])


def _parte(img, desenhar, contorno=hexc("#1e1420")):
    """Desenha uma parte numa camada própria, contorna e cola por cima (gera linhas internas)."""
    camada = nova(img.shape[1], img.shape[0])
    desenhar(camada)
    contornar(camada, contorno)
    m = camada[:, :, 3] > 0
    img[m] = camada[m]


def _bloco(c, x0, y0, x1, y1, rampa, base, luz_esq=True):
    """Retângulo com luz da esquerda: coluna esquerda mais clara, direita mais escura."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            i = base
            if x == x0 and luz_esq:
                i += 1
            if x == x1:
                i -= 1
            if y == y1:
                i -= 1
            put(c, x, y, cor(rampa, i))


def quadro_jogador(direcao, passo):
    """Um quadro 16x32. passo: 0 parado, 1 passo com a perna esquerda, -1 com a direita,
    2 usando ferramenta (mãos juntas à frente). Pés no y=29 (contorno no 30)."""
    img = nova(16, 32)
    _sombra(img, 8, 30, 5.5, 1.8, 90)
    lado = direcao in ("esquerda", "direita")
    esp = direcao == "direita"
    def X(x):  # espelha para a direita
        return 15 - x if esp else x
    usar = passo == 2
    if usar:
        passo = 0
    cab_y = 6 - (1 if passo == 0 and not usar else 0) + 1
    if not lado:
        # pernas (frente/costas)
        def pernas(c):
            for i, (x0, x1, bx0, bx1) in enumerate(((5, 6, 4, 6), (9, 10, 9, 11))):
                ergue = 1 if (passo == 1 and i == 1) or (passo == -1 and i == 0) else 0
                _bloco(c, x0, 24, x1, 27 - ergue, "calca", 2)
                _bloco(c, bx0, 28 - ergue, bx1, 29 - ergue, "sapato", 2)
            _bloco(c, 5, 23, 10, 24, "calca", 2)
        _parte(img, pernas)
        # tronco + braços numa parte só
        def corpo(c):
            _bloco(c, 5, 18, 10, 23, "camisa", 2)
            for x in (6, 7, 8, 9):
                put(c, x, 18, cor("camisa", 4 if direcao == "baixo" else 3))
            if direcao == "baixo":
                put(c, 7, 19, cor("camisa", 1)); put(c, 8, 19, cor("camisa", 1))  # gola
            for i, x0 in enumerate((3, 11)):
                if usar:  # braços dobrados para a frente, mãos juntas no meio
                    dentro = 1 if i == 0 else -1
                    for y in (18, 19):
                        for x in (x0, x0 + 1):
                            put(c, x, y, cor("camisa", 3 if x == x0 and i == 0 else 2 if x == x0 else 1))
                    for x in (x0 + dentro, x0 + 1 + dentro):
                        put(c, x, 20, cor("camisa", 2))
                    for x in (x0 + 2 * dentro, x0 + 1 + 2 * dentro):
                        put(c, x, 21, cor("pele", 3 if i == 0 else 2))
                    continue
                sobe = 1 if (passo == 1 and i == 0) or (passo == -1 and i == 1) else 0
                fim = 22 - sobe
                for y in range(18, fim + 1):
                    for x in (x0, x0 + 1):
                        if y <= 20:
                            put(c, x, y, cor("camisa", 3 if x == x0 and i == 0 else 2 if x == x0 else 1))
                        else:
                            put(c, x, y, cor("pele", 3 if x == x0 else 2))
                put(c, x0 + (1 if i == 0 else 0), 18, cor("camisa", 1))
                for y in range(19, 21):
                    put(c, 5 if i == 0 else 10, y, cor("camisa", 1))
            for x in range(5, 11):  # cinto
                put(c, x, 23, cor("madeira", 1))
            if direcao == "baixo":
                put(c, 7, 23, cor("flor_am", 1))
        _parte(img, corpo)
        _molde(img, CABECA[direcao], 0, cab_y)
    else:
        def P(c, x0, y0, x1, y1, rampa, base):
            a, b = sorted((X(x0), X(x1)))
            _bloco(c, a, y0, b, y1, rampa, base)
        # perna de trás (mais escura) e da frente
        def perna_tras(c):
            if passo != 0:
                d = 2 if passo == 1 else -2
                P(c, 7 + d, 24, 8 + d, 27, "calca", 1)
                P(c, 7 + d - (1 if True else 0), 28, 8 + d, 29, "sapato", 1)
        def perna_frente(c):
            d = -2 if passo == 1 else 2 if passo == -1 else 0
            P(c, 7 + d, 24, 8 + d, 27, "calca", 2)
            P(c, 6 + d, 28, 8 + d, 29, "sapato", 2)
            P(c, 6, 23, 9, 24, "calca", 2)
        if passo != 0:
            _parte(img, perna_tras)
        _parte(img, perna_frente)
        def tronco_lado(c):
            P(c, 5, 18, 9, 23, "camisa", 2)
            for x in range(5, 10):
                put(c, X(x), 23, cor("madeira", 1))
        _parte(img, tronco_lado)
        def braco(c):
            if usar:  # braço esticado para a frente
                for x in range(3, 8):
                    for y in (19, 20):
                        if x >= 5:
                            put(c, X(x), y, cor("camisa", 3 if y == 19 else 2))
                        else:
                            put(c, X(x), y, cor("pele", 3 if y == 19 else 2))
                return
            d = (-1 if passo == -1 else 1 if passo == 1 else 0)
            for y in range(18, 23):
                for x in (6 + d, 7 + d):
                    if y <= 20:
                        put(c, X(x), y, cor("camisa", 3 if x == 6 + d else 2))
                    else:
                        put(c, X(x), y, cor("pele", 3 if x == 6 + d else 2))
        _parte(img, braco)
        _molde(img, CABECA["esquerda"], 0, cab_y, espelhar=esp)
    return img


def jogador():
    """Folha 80x128: linhas baixo, cima, esquerda, direita; colunas parado, passo, parado, passo, usando."""
    folha = nova(80, 128)
    for li, d in enumerate(("baixo", "cima", "esquerda", "direita")):
        for co, p in enumerate((0, 1, 0, -1, 2)):
            folha[li * 32:(li + 1) * 32, co * 16:(co + 1) * 16] = quadro_jogador(d, p)
    return folha


def ondas():
    """Ondinhas em volta do jogador nadando: 2 quadros 20x8."""
    folha = nova(40, 8)
    for q in range(2):
        t = nova(20, 8)
        for y in range(8):
            for x in range(20):
                dx, dy = (x + 0.5 - 10) / (9 - q), (y + 0.5 - 4) / (3 - q * 0.4)
                r = dx * dx + dy * dy
                if 0.62 <= r <= 1.0 and y >= 3:
                    put(t, x, y, cor("agua", 6))
                elif 0.62 <= r <= 1.0 and hash01(x, q, 3) > 0.5:
                    put(t, x, y, cor("agua", 5))
        folha[:, q * 20:(q + 1) * 20] = t
    return folha


def gerar_personagens():
    salvar(jogador(), caminho("personagens", "jogador.png"))
    salvar(ondas(), caminho("personagens", "ondas.png"))



# =============================== PLANTAÇÃO ===============================
# Atlas 64x160: colunas = estágios 0..3 (3 = pronta); linha = "linha" em culturas.json (0 fica vazia).
# Cada quadro tem 16x32; a célula do chão é a metade de baixo (a planta nasce em y≈26).

def _haste(c, x, y0, y1, i=3):
    for y in range(y1, y0 + 1):
        put(c, x, y, cor("folha", i))


def _folhinha(c, x, y, lado, tam=2, i=5):
    """Folha pequena saindo para o lado (lado=-1 esquerda, 1 direita)."""
    for k in range(tam + 1):
        put(c, x + lado * k, y - (k + 1) // 2, cor("folha", i if k < tam else i + 1))
        if k > 0 and tam > 1:
            put(c, x + lado * k, y - (k + 1) // 2 + 1, cor("folha", i - 2))


def broto(c, cx=8, base=26, estagio=0):
    if estagio == 0:
        _haste(c, cx, base, base - 1)
        _folhinha(c, cx - 1, base - 2, -1, 1); _folhinha(c, cx + 1, base - 2, 1, 1)
    else:
        _haste(c, cx, base, base - 4)
        _folhinha(c, cx - 1, base - 2, -1, 2, 4); _folhinha(c, cx + 1, base - 3, 1, 2, 4)
        _folhinha(c, cx - 1, base - 5, -1, 1); _folhinha(c, cx + 1, base - 5, 1, 1)


def _moita(c, circ, s, deslocar=0):
    camada = nova(c.shape[1], c.shape[0])
    copa(camada, circ, semente=s, deslocar=deslocar)
    m = camada[:, :, 3] > 0
    c[m] = camada[m]


def cultura(nome, estagio):
    c = nova(16, 32)
    if estagio <= 1:
        broto(c, estagio=estagio)
        if nome == "milho" and estagio == 1:
            _haste(c, 8, 22, 19, 4)
        contornar(c, hexc("#13230f"))
        return c
    s = {"feijao": 11, "cenoura": 12, "batata": 13, "milho": 14}[nome]
    pronta = estagio == 3
    if nome == "feijao":
        for y in range(8, 28):  # estaca
            put(c, 7, y, cor("madeira", 4)); put(c, 8, y, cor("madeira", 2))
        folhas = [(6, 24, 3), (10, 21, 3), (5, 18, 3), (10, 15, 3), (6, 12, 2.8)]
        if pronta:
            folhas.append((9, 10, 2.6))
        _moita(c, folhas if pronta else folhas[:4], s)
        if pronta:
            for (x, y) in ((4, 20), (11, 17), (5, 14), (11, 24)):
                for k in range(3):
                    put(c, x, y + k, cor("feijao", 2 if k == 0 else 1))
                put(c, x, y, cor("feijao", 3))
    elif nome == "cenoura":
        if pronta:
            for y in range(24, 28):
                for x in range(6, 11):
                    if (x - 8) ** 2 / 6.5 + (y - 26.5) ** 2 / 3.0 <= 1:
                        put(c, x, y, cor("cenoura", 3 if x < 8 else 2))
        alt = 9 if pronta else 6
        for k, (dx, h) in enumerate(((-3, alt - 2), (-1, alt), (1, alt + 1), (3, alt - 1), (0, alt - 3))):
            for j in range(h):
                x = 8 + int(round(dx * j / h))
                put(c, x, 25 - j, cor("folha", 4 if j > h // 2 else 3))
            put(c, 8 + dx - (1 if dx < 0 else -1 if dx > 0 else 0), 25 - h, cor("folha", 6))
            put(c, 8 + dx, 25 - h + 1, cor("folha", 5))
    elif nome == "batata":
        circ = [(8, 22, 5.2), (4.5, 23.5, 3.2), (11.5, 23.5, 3.2), (8, 18.5, 3.6)] if pronta else \
               [(8, 23, 4.2), (5, 24, 2.6), (11, 24, 2.6)]
        _moita(c, circ, s)
        if pronta:
            for (x, y, f) in ((6, 18, "flor_br"), (10, 19, "flor_li"), (8, 16, "flor_br"), (12, 22, "flor_li")):
                put(c, x, y, cor(f, 1)); put(c, x - 1, y, cor(f, 2)); put(c, x + 1, y, cor(f, 2))
                put(c, x, y - 1, cor(f, 2)); put(c, x, y + 1, cor(f, 2)); put(c, x, y, cor("flor_am", 1))
            for (x, y) in ((4, 27), (11, 27)):
                put(c, x, y, cor("batata", 3)); put(c, x + 1, y, cor("batata", 2))
    elif nome == "milho":
        topo = 6 if pronta else 12
        for y in range(topo, 28):
            put(c, 7, y, cor("folha", 4)); put(c, 8, y, cor("folha", 2))
        for (y, lado, n) in ((24, -1, 5), (21, 1, 5), (17, -1, 5), (14, 1, 4)) + (((10, -1, 4),) if pronta else ()):
            if y < topo + 2:
                continue
            for k in range(n):
                x = (7 - 1 - k) if lado < 0 else (8 + 1 + k)
                yy = y - (1 if k < 2 else 0) + (1 if k >= n - 1 else 0)
                put(c, x, yy, cor("folha", 5 if k < n - 2 else 4))
                put(c, x, yy + 1, cor("folha", 3))
        if pronta:
            for y in range(13, 20):  # espiga
                put(c, 9, y, cor("milho", 3 if y < 16 else 2)); put(c, 10, y, cor("milho", 2 if y < 17 else 1))
            put(c, 9, 20, cor("folha", 4)); put(c, 10, 20, cor("folha", 3)); put(c, 10, 12, cor("folha", 5))
            for (x, y) in ((6, 5), (8, 4), (9, 5), (7, 3)):  # pendão
                put(c, x, y, cor("milho", 3))
    contornar(c, hexc("#13230f"))
    return c


def plantacao():
    atlas = nova(64, 160)
    for linha, nome in ((1, "feijao"), (2, "cenoura"), (3, "batata"), (4, "milho")):
        for e in range(4):
            atlas[linha * 32:(linha + 1) * 32, e * 16:(e + 1) * 16] = cultura(nome, e)
    return atlas


# =============================== ITENS ===============================

def _icone(desenhar):
    c = nova(16, 16)
    desenhar(c)
    contornar(c, hexc("#1e1420"))
    return c


def _pacote(cor_semente):
    def d(c):
        for y in range(3, 15):
            for x in range(3, 13):
                i = 3 if x < 6 else 2 if x < 11 else 1
                if y == 3:
                    i = 1
                put(c, x, y, cor("papel", i))
        for x in range(3, 13):  # dobra de cima
            put(c, x, 4, cor("papel", 0)); put(c, x, 2, cor("papel", 2))
        for y in range(7, 12):  # desenho da cultura
            for x in range(5, 11):
                if (x - 7.5) ** 2 / 6 + (y - 9.5) ** 2 / 4 <= 1:
                    put(c, x, y, cor(cor_semente[0], cor_semente[1] + (1 if x < 7 else 0)))
        put(c, 7, 6, cor("folha", 4)); put(c, 8, 6, cor("folha", 5))
    return _icone(d)


def icones_itens():
    def enxada(c):
        for k in range(10):  # cabo na diagonal
            put(c, 4 + k, 13 - k, cor("madeira", 4)); put(c, 5 + k, 13 - k, cor("madeira", 2))
        for y in range(2, 7):  # lâmina
            for x in range(9, 15):
                if y - 2 <= (x - 9) + 1:
                    put(c, x, y, cor("metal", 4 if y == 2 else 3 if x < 12 else 2))
        put(c, 12, 4, cor("madeira", 1))
    def regador(c):
        for y in range(6, 14):
            for x in range(4, 12):
                put(c, x, y, cor("camisa", 4 if x < 6 else 3 if x < 10 else 2))
        for x in range(4, 12):
            put(c, x, 6, cor("camisa", 4)); put(c, x, 13, cor("camisa", 1))
        for k in range(4):  # bico
            put(c, 12 + k, 9 - k, cor("metal", 3)); put(c, 12 + k, 10 - k, cor("metal", 2))
        put(c, 15, 5, cor("metal", 4)); put(c, 14, 5, cor("metal", 4))
        for x in range(5, 10):  # alça
            put(c, x, 3, cor("metal", 3))
        put(c, 4, 4, cor("metal", 3)); put(c, 4, 5, cor("metal", 3)); put(c, 10, 4, cor("metal", 3)); put(c, 10, 5, cor("metal", 3))
    def feijao(c):
        for (cx, cy) in ((5.5, 7.5), (10.5, 8), (8, 12)):
            def um(cc, cx=cx, cy=cy):
                for y in range(16):
                    for x in range(16):
                        if ((x + 0.5 - cx) / 2.7) ** 2 + ((y + 0.5 - cy) / 2.0) ** 2 <= 1:
                            put(cc, x, y, cor("feijao", 2 if y + 0.5 < cy else 1))
                put(cc, int(cx) - 1, int(cy) - 1, cor("feijao", 3))
                put(cc, int(cx), int(cy) - 1, cor("papel", 3))
            _parte(c, um)
    def cenoura(c):
        for k in range(9):
            r = 2.4 - k * 0.24
            cx, cy = 5 + k * 0.85, 11 - k * 0.85
            for y in range(16):
                for x in range(16):
                    if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= max(0.6, r):
                        put(c, x, y, cor("cenoura", 3 if x + y < cx + cy - 1 else 2))
        for (x, y) in ((3, 12), (4, 13), (5, 11)):
            put(c, x, y, cor("cenoura", 1))
        for (x, y, i) in ((3, 6, 4), (4, 7, 5), (2, 5, 5), (5, 5, 4), (5, 4, 5), (2, 8, 4), (1, 8, 5), (4, 8, 3)):
            put(c, x, y, cor("folha", i))
    def batata(c):
        for y in range(16):
            for x in range(16):
                if ((x + 0.5 - 8) / 5.5) ** 2 + ((y + 0.5 - 9) / 4.2) ** 2 <= 1:
                    v = -((x - 8) * -0.6 + (y - 9) * -0.8) / 5
                    put(c, x, y, cor("batata", max(0, min(3, int(round(2 + v * 1.5))))))
        for (x, y) in ((6, 8), (10, 10), (8, 11)):
            put(c, x, y, cor("batata", 0))
    def milho(c):
        for k in range(10):
            cx, cy = 5.5 + k * 0.6, 12.5 - k * 0.95
            for y in range(16):
                for x in range(16):
                    if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= 2.3 - k * 0.08:
                        put(c, x, y, cor("milho", 3 if (x + y) % 2 == 0 else 2))
        for (x, y, i) in ((3, 13, 4), (4, 13, 3), (4, 12, 4), (2, 12, 5), (6, 14, 3), (7, 14, 4), (8, 13, 5), (3, 11, 5)):
            put(c, x, y, cor("folha", i))
    def carta(c):
        for y in range(3, 13):  # pergaminho enrolado nas pontas
            for x in range(3, 13):
                put(c, x, y, cor("papel", 3 if x < 10 else 2))
        for y in range(2, 14):
            put(c, 2, y, cor("papel", 1)); put(c, 3, y, cor("papel", 2))
            put(c, 12, y, cor("papel", 1)); put(c, 13, y, cor("papel", 0))
        for k, y in enumerate((5, 7, 9)):
            for x in range(5, 11 - (k == 2) * 2):
                put(c, x, y, cor("madeira", 2))
        for (x, y) in ((9, 10), (10, 10), (9, 11), (10, 11), (11, 11), (10, 12)):  # selo
            put(c, x, y, cor("coracao", 2 if y < 12 else 1))
        put(c, 9, 10, cor("coracao", 3))
    def bolo(c):
        for y in range(16):
            for x in range(16):
                d = ((x + 0.5 - 8) / 6) ** 2 + ((y + 0.5 - 9) / 4.5) ** 2
                if d <= 1:
                    i = 3 if y < 8 else 2 if y < 11 else 1
                    put(c, x, y, cor("cevada", i))
        for x in range(4, 13):
            put(c, x, 9, cor("cevada", 0)) if x % 2 == 0 else None
        for y in range(6, 12):
            put(c, 8, y, cor("cevada", 0)) if y % 2 == 0 else None
        put(c, 5, 6, cor("cevada", 4)); put(c, 6, 6, cor("cevada", 4))
    def chave(c):
        for y in range(16):
            for x in range(16):
                if 2.2 <= math.hypot(x + 0.5 - 5, y + 0.5 - 5) <= 3.6:
                    put(c, x, y, cor("milho", 3 if y < 5 else 2))
        put(c, 5, 5, cor("vidro", 3)); put(c, 4, 5, cor("vidro", 4)); put(c, 5, 4, cor("vidro", 4)); put(c, 4, 4, cor("vidro", 4))
        for k in range(8):
            put(c, 7 + k, 7 + k, cor("milho", 2)); put(c, 8 + k, 7 + k, cor("milho", 1))
        for (x, y) in ((12, 14), (13, 13), (10, 12), (11, 11)):
            put(c, x, y, cor("milho", 2))
    def casaco(c):
        """Casaco de pele de carneiro: corpo marrom, mangas abertas e lã branca na gola e nos punhos."""
        for y in range(4, 15):
            for x in range(5, 11):
                put(c, x, y, cor("madeira", 4 if x < 8 else 3))
        for k in range(7):  # mangas
            for w in range(3):
                put(c, 4 - k // 2 - w + 1, 4 + k, cor("madeira", 4))
                put(c, 11 + k // 2 + w - 1, 4 + k, cor("madeira", 3))
        for (x, y) in ((1, 10), (2, 10), (3, 10), (12, 10), (13, 10), (14, 10)):  # punhos de lã
            put(c, x, y, cor("flor_br", 2))
        for y in range(4, 15):  # abertura e botões
            put(c, 8, y, cor("madeira", 1))
        for y in (7, 10, 13):
            put(c, 7, y, cor("milho", 2))
        for (x, y) in ((5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (6, 4), (9, 4), (7, 5)):  # gola
            put(c, x, y, cor("flor_br", 2 if y < 4 else 1))
        for x in range(5, 11):
            put(c, x, 14, cor("flor_br", 1))
    def vara(c):
        for k in range(12):  # vara na diagonal
            put(c, 2 + k, 14 - k, cor("madeira", 4 if k > 3 else 2))
            if k < 4:
                put(c, 3 + k, 14 - k, cor("madeira", 1))
        for y in range(3, 12):  # linha
            put(c, 14, y, cor("flor_br", 1))
        put(c, 13, 12, cor("coracao", 2)); put(c, 14, 12, cor("coracao", 2)); put(c, 14, 13, cor("flor_br", 2))
        put(c, 4, 11, cor("metal", 3)); put(c, 5, 11, cor("metal", 2))  # molinete
    def peixe_icone(rampa, comprido=0, listras=False, bigode=False, brilho=None):
        """Peixe deitado olhando para a esquerda: corpo oval, cauda em leque, olho e barbatana."""
        def d(c):
            rx = 4.6 + comprido * 0.5
            ry = 3.0 if comprido < 4 else 1.8
            cx, cy = 7.0 - comprido * 0.2, 8.0
            for y in range(16):
                for x in range(16):
                    dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
                    if dx * dx + dy * dy <= 1:
                        i = 3 if dy < -0.35 else 2 if dy < 0.45 else 1
                        if listras and int(x) % 3 == 0 and dy < 0.5:
                            i = max(0, i - 1)
                        put(c, x, y, cor(rampa, i))
            cauda = int(cx + rx)
            if comprido < 4:
                for k in range(4):
                    for y in range(int(cy) - 1 - k, int(cy) + 1 + k):
                        put(c, cauda + k, y, cor(rampa, 2 if y < cy else 1))
            put(c, int(cx) - 1, int(cy) - 4 + (1 if comprido >= 4 else 0), cor(rampa, 3))  # barbatana
            put(c, int(cx), int(cy) - 4 + (1 if comprido >= 4 else 0), cor(rampa, 2))
            ox = int(cx - rx) + 2
            put(c, ox, int(cy) - 1, cor("flor_br", 2)); put(c, ox, int(cy), hexc("#1e1420"))
            if bigode:
                put(c, ox - 2, int(cy) + 1, cor("pedra", 1)); put(c, ox - 3, int(cy) + 2, cor("pedra", 1))
            if brilho:
                for x in range(int(cx - rx) + 4, int(cx + rx) - 1, 2):
                    put(c, x, int(cy) - 2, cor(brilho, 4))
        return d
    def sonda(c):
        """Linha de pesca enrolada numa pedra (para medir o fundo)."""
        for y in range(16):
            for x in range(16):
                if math.hypot(x + 0.5 - 8, (y + 0.5 - 11) * 1.2) <= 4:
                    put(c, x, y, cor("pedra", 4 if y < 10 else 3 if x < 9 else 2))
        for y in range(1, 8):
            put(c, 8, y, cor("flor_br", 2))
        for x in range(4, 13):
            put(c, x, 10, cor("flor_br", 1)) if x % 2 else None
        put(c, 7, 1, cor("flor_br", 2)); put(c, 9, 2, cor("flor_br", 2))
    def arca(c):
        """Arca de ferro pequena, com rebites."""
        for y in range(5, 14):
            for x in range(2, 14):
                put(c, x, y, cor("metal", 3 if y < 9 else 2))
        for x in range(2, 14):
            put(c, x, 9, cor("metal", 1)); put(c, x, 5, cor("metal", 4))
        for (x, y) in ((3, 7), (12, 7), (3, 12), (12, 12)):
            put(c, x, y, cor("metal", 4))
        for y in range(8, 11):
            put(c, 8, y, cor("milho", 2)); put(c, 7, y, cor("milho", 3))
    def enxada_larga(c):
        enxada(c)
        for y in range(1, 8):
            for x in range(8, 16):
                if y - 1 <= (x - 8) + 2:
                    put(c, x, y, cor("milho", 3 if y == 1 else 2 if x < 12 else 1))
        put(c, 12, 4, cor("madeira", 1))
    def regador_grande(c):
        regador(c)
        for x in range(4, 12):
            put(c, x, 9, cor("milho", 2)); put(c, x, 10, cor("milho", 1))
        for y in range(5, 14):
            put(c, 3, y, cor("camisa", 4))
    def machado(c):
        for k in range(11):  # cabo na diagonal
            put(c, 3 + k, 14 - k, cor("madeira", 4)); put(c, 4 + k, 14 - k, cor("madeira", 2))
        for y in range(1, 9):  # lâmina em leque
            for x in range(8, 15):
                dx, dy = x - 11, y - 4.5
                if dx * dx / 10.0 + dy * dy / 14.0 <= 1 and x - 8 >= abs(dy) * 0.4:
                    put(c, x, y, cor("metal", 4 if x >= 13 else 3 if y < 5 else 2))
        put(c, 14, 2, cor("metal", 4)); put(c, 14, 7, cor("metal", 2))
        put(c, 10, 5, cor("madeira", 1)); put(c, 11, 4, cor("madeira", 1))
    def madeira(c):
        for (x0, y0) in ((2, 8), (5, 4), (8, 9)):
            for y in range(4):
                for x in range(7):
                    put(c, x0 + x, y0 + y, cor("tronco", 3 if y == 0 else 2 if y < 3 else 1))
            for y in range(4):   # ponta cortada com anéis
                put(c, x0 + 6, y0 + y, cor("madeira", 5 if 0 < y < 3 else 4))
            put(c, x0 + 6, y0 + 1, cor("madeira", 6)); put(c, x0 + 6, y0 + 2, cor("madeira", 4))
            put(c, x0 + 2, y0 + 1, cor("tronco", 1))
    lista = [_icone(enxada), _icone(regador), _pacote(("feijao", 1)), _icone(feijao),
             _pacote(("cenoura", 2)), _icone(cenoura), _pacote(("batata", 1)), _icone(batata),
             _pacote(("milho", 2)), _icone(milho), _icone(carta), _icone(bolo), _icone(chave), _icone(casaco),
             _icone(vara), _icone(peixe_icone("milho", listras=True)), _icone(peixe_icone("batata")), _icone(peixe_icone("pedra", bigode=True)),
             _icone(peixe_icone("oliva", comprido=3, listras=True)), _icone(peixe_icone("cevada", comprido=3, brilho="folha")),
             _icone(peixe_icone("metal", comprido=-2)), _icone(peixe_icone("calca", comprido=5)),
             _icone(sonda), _icone(arca), _icone(enxada_larga), _icone(regador_grande),
             _icone(machado), _icone(madeira)]
    atlas = nova(16 * len(lista), 16)
    for i, ic in enumerate(lista):
        atlas[:, i * 16:(i + 1) * 16] = ic
    return atlas


# =============================== INTERFACE ===============================

def painel():
    """Painel de madeira 24x24 para 9-patch (margens de 7 px). Moldura de madeira e fundo de pergaminho."""
    c = nova(24, 24)
    for y in range(24):
        for x in range(24):
            borda = min(x, y, 23 - x, 23 - y)
            if borda == 0:
                if (x in (0, 23)) and (y in (0, 23)):
                    continue
                put(c, x, y, cor("ui_mad", 0))
            elif borda <= 5:
                i = 4
                if borda == 1:
                    i = 5 if (x < 12 and y < 12) else 3
                elif borda == 5:
                    i = 2
                elif borda == 4:
                    i = 3
                put(c, x, y, cor("ui_mad", i))
            else:
                put(c, x, y, hexc("#f2dfb0"))
    # pregos
    for (x, y) in ((3, 3), (20, 3), (3, 20), (20, 20)):
        put(c, x, y, cor("metal", 4)); put(c, x + 1, y + 1, cor("metal", 1))
    return c


def slot(selecionado=False):
    c = nova(20, 20)
    for y in range(20):
        for x in range(20):
            b = min(x, y, 19 - x, 19 - y)
            if b == 0:
                put(c, x, y, cor("ui_mad", 6 if selecionado else 1))
            elif b == 1:
                put(c, x, y, cor("ui_mad", 5 if selecionado else 2) if not selecionado else hexc("#f6e27a"))
            else:
                i = hexc("#e3c48c") if (x + y) % 2 == 0 or y > 2 else hexc("#d4b177")
                if y == 2 or x == 2:
                    i = hexc("#c9a46a")
                put(c, x, y, i)
    if selecionado:
        for y in range(20):
            for x in range(20):
                if min(x, y, 19 - x, 19 - y) == 0:
                    put(c, x, y, hexc("#d6383f"))
    return c


def icones_hud():
    """Ícones 10x10: coração (vida), maçã (fome), sol, lua, moeda."""
    def coracao(c):
        for y in range(10):
            for x in range(10):
                px, py = x + 0.5, y + 0.5
                d1 = math.hypot(px - 3.2, py - 3.6); d2 = math.hypot(px - 6.8, py - 3.6)
                tri = py > 3.5 and abs(px - 5) < (9.2 - py) * 0.95
                if d1 <= 2.4 or d2 <= 2.4 or tri:
                    put(c, x, y, cor("coracao", 2))
        put(c, 2, 2, cor("coracao", 3)); put(c, 3, 2, cor("coracao", 3)); put(c, 2, 3, cor("coracao", 3))
        for (x, y) in ((6, 6), (5, 7), (7, 5), (8, 4)):
            put(c, x, y, cor("coracao", 1))
    def maca(c):
        for y in range(10):
            for x in range(10):
                if math.hypot(x + 0.5 - 5, y + 0.5 - 5.8) <= 3.8:
                    put(c, x, y, cor("coracao", 3 if x < 4 and y < 5 else 2 if x < 7 else 1))
        put(c, 5, 1, cor("tronco", 2)); put(c, 5, 2, cor("tronco", 2)); put(c, 6, 1, cor("folha", 5)); put(c, 7, 1, cor("folha", 4))
        put(c, 3, 4, cor("papel", 3))
    def sol(c):
        for y in range(10):
            for x in range(10):
                d = math.hypot(x + 0.5 - 5, y + 0.5 - 5)
                if d <= 2.6:
                    put(c, x, y, cor("flor_am", 2 if d < 1.5 else 1))
        for (x, y) in ((5, 0), (4, 0), (5, 9), (4, 9), (0, 5), (0, 4), (9, 4), (9, 5), (1, 1), (8, 1), (1, 8), (8, 8)):
            put(c, x, y, cor("flor_am", 1))
    def lua(c):
        for y in range(10):
            for x in range(10):
                if math.hypot(x + 0.5 - 5, y + 0.5 - 5) <= 3.6 and math.hypot(x + 0.5 - 6.8, y + 0.5 - 3.8) > 3.0:
                    put(c, x, y, cor("flor_br", 1 if x > 3 else 2))
    def moeda(c):
        for y in range(10):
            for x in range(10):
                d = math.hypot(x + 0.5 - 5, y + 0.5 - 5)
                if d <= 3.8:
                    put(c, x, y, cor("milho", 3 if d < 2.2 and x < 5 else 2 if d < 3 else 1))
        for y in range(3, 7):
            put(c, 5, y, cor("milho", 0))
    def medalha(c):
        for (x, y, i) in ((3, 0, 1), (4, 1, 1), (6, 0, 2), (5, 1, 2), (4, 2, 1), (5, 2, 2)):
            put(c, x, y, cor("camisa" if i == 1 else "coracao", 3))
        for y in range(10):
            for x in range(10):
                d = math.hypot(x + 0.5 - 5, y + 0.5 - 6.2)
                if d <= 3.4:
                    put(c, x, y, cor("milho", 3 if d < 1.8 and x < 5 else 2 if d < 2.7 else 1))
        put(c, 4, 5, cor("flor_br", 2))
    atlas = nova(60, 10)
    for i, f in enumerate((coracao, maca, sol, lua, moeda, medalha)):
        c = nova(10, 10)
        f(c)
        atlas[:, i * 10:(i + 1) * 10] = c
    # contorno por ícone
    for i in range(6):
        sub = nova(12, 12)
        sub[1:11, 1:11] = atlas[:, i * 10:(i + 1) * 10]
        contornar(sub, hexc("#1e1420"))
        out2 = sub
        if i == 0:
            final = nova(12 * 6, 12)
        final[:, i * 12:(i + 1) * 12] = out2
    return final


def gerar_interface():
    salvar(plantacao(), caminho("plantacao", "culturas.png"))
    salvar(icones_itens(), caminho("itens", "itens.png"))
    salvar(painel(), caminho("ui", "painel.png"))
    salvar(slot(False), caminho("ui", "slot.png"))
    salvar(slot(True), caminho("ui", "slot_sel.png"))
    salvar(icones_hud(), caminho("ui", "icones_hud.png"))



# =============================== LOGO ===============================

def logo():
    """'Leaf & Lore' com a fonte Leaf Pixel em negrito, ampliada 3x: 'Leaf' verde, '&' creme,
    'Lore' dourado; contorno escuro duplo, sombra e uma folha sobre o 'L'."""
    import fonte as F
    texto = "Leaf & Lore"
    esc = 3
    glifos = []
    for ch in texto:
        m = F.bitmap(ch)
        w = len(m[0]) + 1  # negrito: soma o glifo deslocado 1 px para a direita
        b = [[0] * w for _ in range(F.ALTURA)]
        for yy, linha in enumerate(m):
            for xx, v in enumerate(linha):
                if v:
                    b[yy][xx] = 1
                    b[yy][xx + 1] = 1
        glifos.append((ch, b))
    larg = sum(len(b[0]) + 1 for _, b in glifos) - 1
    W, H = larg * esc + 16, (F.ALTURA - F.TOPO) * esc + 16
    img = nova(W, H)
    x = 8
    for k, (ch, b) in enumerate(glifos):
        rampa = "folha" if k < 4 else ("papel" if ch == "&" else "milho")
        for yy, linha in enumerate(b):
            for xx, v in enumerate(linha):
                if not v:
                    continue
                rel = (yy - F.TOPO) / 7.0
                for dy in range(esc):
                    for dx in range(esc):
                        r = rel + dy / (7.0 * esc)
                        if rampa == "folha":
                            i = 6 if r < 0.2 else 5 if r < 0.5 else 4 if r < 0.8 else 3
                        elif rampa == "papel":
                            i = 3 if r < 0.5 else 2
                        else:
                            i = 3 if r < 0.3 else 2 if r < 0.75 else 1
                        topo = yy == 0 or not b[yy - 1][xx]
                        if topo and dy == 0:
                            i = min(len(RAMPAS[rampa]) - 1, i + 1)
                        put(img, x + xx * esc + dx, 8 + (yy - F.TOPO) * esc + dy, cor(rampa, i))
        x += (len(b[0]) + 1) * esc
    contornar(img, hexc("#1e1420"), diagonais=True)
    contornar(img, hexc("#1e1420"), diagonais=False)
    a = img[:, :, 3] > 0
    final = nova(W + 3, H + 3)
    final[3:, 3:][a] = (30, 20, 32, 150)
    final[:H, :W][a] = img[a]
    # folha grande inclinada sobre o 'L'
    folha = nova(16, 14)
    for y in range(14):
        for xx in range(16):
            u, v = (xx + 0.5 - 8) / 7.0, (y + 0.5 - 7) / 4.2
            # elipse girada 30 graus
            c, s = math.cos(-0.55), math.sin(-0.55)
            ru, rv = u * c - v * s * 0.6, u * s / 0.6 + v * c
            if ru * ru + rv * rv <= 1:
                i = 5 if rv < -0.2 else 4 if rv < 0.3 else 3
                if abs(rv - ru * 0.15) < 0.12:
                    i = 6  # nervura
                put(folha, xx, y, cor("folha", i))
    put(folha, 2, 12, cor("tronco", 3)); put(folha, 1, 13, cor("tronco", 3)); put(folha, 3, 11, cor("tronco", 3))
    contornar(folha, hexc("#1e1420"))
    colar(final, folha, 1, 0)
    return final


def gerar_logo():
    salvar(logo(), caminho("ui", "logo.png"))


# =============================== PRÉVIA ===============================

def previa_terreno(mapa_json, saida, escala=3):
    """Monta o chão como o jogo monta (grade dupla) para conferir a arte sem abrir o Godot."""
    import json
    m = json.load(open(mapa_json))
    leg = m["legenda"]
    grade = [[leg.get(c, "grama") for c in linha] for linha in m["linhas"]]
    H, W = len(grade), len(grade[0])
    img = nova(W * 16, H * 16)
    gr = grama()
    for y in range(H):
        for x in range(W):
            h = hash01(x, y, 99)
            v = 0 if h < 0.35 else 1 if h < 0.6 else 2 if h < 0.75 else 3 if h < 0.85 else 4 if h < 0.92 else 5 if h < 0.96 else 6 if h < 0.98 else 7
            img[y * 16:(y + 1) * 16, x * 16:(x + 1) * 16] = gr[:, v * 16:(v + 1) * 16]
    def camada(atlas, tipos):
        def tem(cx, cy):
            return 0 <= cx < W and 0 <= cy < H and grade[cy][cx] in tipos
        for dy in range(H + 1):
            for dx in range(W + 1):
                mask = (1 if tem(dx - 1, dy - 1) else 0) | (2 if tem(dx, dy - 1) else 0) | \
                       (4 if tem(dx - 1, dy) else 0) | (8 if tem(dx, dy) else 0)
                if mask:
                    col = mask
                    extra = atlas.shape[1] // 16 - 16
                    if mask == 15 and extra > 0:
                        hv = hash01(dx, dy, 77)
                        if hv > 0.55:
                            col = 16 + int((hv - 0.55) / 0.45 * extra) % extra
                    colar(img, atlas[0:16, col * 16:(col + 1) * 16], dx * 16 - 8, dy * 16 - 8)
    camada(terra_campo(), {"terra"})
    camada(caminho_terra(), {"caminho"})
    camada(agua(), {"agua"})
    salvar(img, saida)
    Image.open(saida).resize((W * 16 * escala, H * 16 * escala), Image.NEAREST).save(saida)


def gerar_terreno():
    salvar(grama(), caminho("terreno", "grama.png"))
    salvar(grama_tom(True), caminho("terreno", "grama_escura.png"))
    salvar(grama_tom(False), caminho("terreno", "grama_clara.png"))
    salvar(terra_campo(), caminho("terreno", "terra.png"))
    salvar(caminho_terra(), caminho("terreno", "caminho.png"))
    salvar(agua(), caminho("terreno", "agua.png"))
    salvar(solo(False), caminho("terreno", "arado.png"))
    salvar(solo(True), caminho("terreno", "molhado.png"))
    import relevo
    salvar(relevo.morro(), caminho("terreno", "morro.png"))
    salvar(relevo.paredao(), caminho("terreno", "paredao.png"))


if __name__ == "__main__":
    gerar_terreno()
    gerar_objetos()
    gerar_personagens()
    gerar_interface()
    gerar_logo()
    import interiores
    interiores.gerar()
    import cidade
    cidade.gerar()
    import livros
    livros.gerar()
    if len(sys.argv) > 1 and sys.argv[1] == "--previa":
        previa_terreno(os.path.join(RAIZ, "..", "..", "content", "mapas", "fazenda.json"), sys.argv[2])
    print("ok")
