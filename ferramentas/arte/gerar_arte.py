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
    for jx in (14, 66):
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
        for x in range(40, 56):
            put(img, x, y, cor("madeira", 1))
    for y in range(68, 98):
        for x in range(42, 54):
            i = 3 if (x - 42) % 4 == 0 else 2
            if y in (75, 87):
                i = 1
            put(img, x, y, cor("madeira", i))
    put(img, 51, 83, cor("flor_am", 2)); put(img, 51, 84, cor("flor_am", 0))
    for x in range(38, 58):  # degrau
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


def gerar_objetos():
    for v in range(3):
        salvar(arvore(v), caminho("objetos", "arvore_%d.png" % v))
    for v in range(2):
        salvar(arvore_grande(v), caminho("objetos", "arvore_grande_%d.png" % v))
        salvar(arbusto(v), caminho("objetos", "arbusto_%d.png" % v))
        salvar(pedra(v), caminho("objetos", "pedra_%d.png" % v))
    salvar(cercas(), caminho("objetos", "cerca.png"))
    salvar(casa(), caminho("objetos", "casa.png"))


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
    salvar(terra_campo(), caminho("terreno", "terra.png"))
    salvar(caminho_terra(), caminho("terreno", "caminho.png"))
    salvar(agua(), caminho("terreno", "agua.png"))
    salvar(solo(False), caminho("terreno", "arado.png"))
    salvar(solo(True), caminho("terreno", "molhado.png"))


if __name__ == "__main__":
    gerar_terreno()
    gerar_objetos()
    if len(sys.argv) > 1 and sys.argv[1] == "--previa":
        previa_terreno(os.path.join(RAIZ, "..", "..", "content", "mapas", "fazenda.json"), sys.argv[2])
    print("ok")
