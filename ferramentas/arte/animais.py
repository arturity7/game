"""Animais da fazenda (GDD §4: galinha, vaca, porco, ovelha), desenho próprio no estilo do jogo.

Cada espécie vira uma folha <especie>.png em game/assets/sprites/animais/:
linhas = direções (0 baixo, 1 cima, 2 esquerda, 3 direita); colunas = quadros
(0 parado, 1 passo, 2 comendo grama). Os pés ficam no rodapé do quadro.
Filhotes ficam em <especie>_filhote.png, no mesmo formato e menores.
A ovelha tosquiada fica em ovelha_tosquiada.png.
"""
import math
from pixel import RAMPAS, nova, put, cor, hexc, contornar, hash01

RAMPAS.update({
    "pena":    ["#7d7a8c", "#a9a7b8", "#d2d2de", "#ececf3", "#ffffff"],
    "crista":  ["#8a1a22", "#c7303a", "#ec5a5a"],
    "bico":    ["#b36a12", "#e3a228", "#f7d25a"],
    "pinto":   ["#b58a1a", "#e2bc33", "#f5dc62", "#fbefa0"],
    "vaca":    ["#9b968f", "#c9c4bb", "#e8e4dc", "#faf8f2"],
    "malha":   ["#1f1a1c", "#332b2d", "#4a3f41"],
    "focinho": ["#a5606a", "#d88a92", "#f2b1b5"],
    "chifre":  ["#a89a76", "#d8cda8", "#f1ead0"],
    "casco":   ["#2a1f1a", "#3f2f27"],
    "la":      ["#a89e8a", "#cfc6b0", "#e9e2cf", "#f8f4e8", "#ffffff"],
    "cara_ov": ["#2a2629", "#3d383c", "#565055", "#6f686d"],
    "pele_ov": ["#8f7d78", "#b8a39c", "#d6c3ba", "#ecdcd2"],
    "porco":   ["#a2525e", "#cf7782", "#ec9ea5", "#f8c3c3", "#ffe0dc"],
})
CONT = hexc("#24171a")
DIRS = ["baixo", "cima", "esquerda", "direita"]


def elipse_luz(img, cx, cy, rx, ry, rampa, base, forca=1.2):
    """Elipse cheia com luz vindo de cima à esquerda."""
    n = len(RAMPAS[rampa])
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx = (x + 0.5 - cx) / rx
            ny = (y + 0.5 - cy) / ry
            if nx * nx + ny * ny <= 1:
                v = -(nx * 0.55 + ny * 0.85)
                i = int(round(base + v * forca))
                put(img, x, y, cor(rampa, max(0, min(n - 1, i))))


def camada(w, h, desenhar, contorno=CONT):
    c = nova(w, h)
    desenhar(c)
    contornar(c, contorno)
    return c


def sobrepor(img, c):
    m = c[:, :, 3] > 0
    img[m] = c[m]


def espelhar(img):
    return img[:, ::-1].copy()


# ------------------------------------------------------------------ galinha (16x16)
def galinha(direcao, quadro, filhote=False):
    W = H = 16
    img = nova(W, H)
    if filhote:
        return pintinho(direcao, quadro)
    passo = quadro == 1
    come = quadro == 2
    # sombra
    for x in range(4, 13):
        put(img, x, 15, (20, 30, 12, 70))
    if direcao in ("esquerda", "direita"):
        def corpo(c):
            elipse_luz(c, 9, 10, 4.8, 3.6, "pena", 3)
            for (x, y) in ((12, 6), (13, 6), (13, 7), (12, 7), (13, 8), (14, 7)):   # rabo
                put(c, x, y, cor("pena", 3 if y < 7 else 2))
            for x in range(8, 12):   # asa
                put(c, x, 10, cor("pena", 1))
            put(c, 8, 9, cor("pena", 2)); put(c, 11, 11, cor("pena", 1))
        def pernas(c):
            for lx in ((7, 10) if not passo else (6, 11)):
                put(c, lx, 13, cor("bico", 1)); put(c, lx, 14, cor("bico", 1))
        def cabeca(c):
            hx, hy = (4, 6) if not come else (4, 11)
            elipse_luz(c, hx + 0.5, hy + 0.5, 2.4, 2.4, "pena", 3)
            put(c, hx - 2, hy + 1, cor("bico", 2)); put(c, hx - 3, hy + 1, cor("bico", 1))
            put(c, hx - 1, hy + 2, cor("crista", 1))
            put(c, hx, hy - 2, cor("crista", 1)); put(c, hx + 1, hy - 2, cor("crista", 2)); put(c, hx, hy - 3, cor("crista", 2))
            put(c, hx - 1, hy, (20, 14, 16, 255))
            if not come:
                put(c, hx + 2, hy + 3, cor("pena", 3)); put(c, hx + 1, hy + 3, cor("pena", 3))
        sobrepor(img, camada(W, H, pernas))
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
        return espelhar(img) if direcao == "direita" else img
    frente = direcao == "baixo"
    def pernas(c):
        a, b = (6, 9) if not passo else (6, 10)
        for lx in (a, b):
            put(c, lx, 13, cor("bico", 1)); put(c, lx, 14, cor("bico", 1))
        if passo:
            put(c, 10, 14, (0, 0, 0, 0))
    def corpo(c):
        elipse_luz(c, 8, 10.2, 4.4, 3.6, "pena", 3)
        put(c, 4, 10, cor("pena", 2)); put(c, 12, 10, cor("pena", 1))
        if not frente:   # rabo pra cima, visto de trás
            for (x, y) in ((7, 6), (8, 6), (9, 6), (8, 5), (7, 7), (9, 7)):
                put(c, x, y, cor("pena", 3))
    def cabeca(c):
        hy = 5 if not come else 9
        if frente:
            elipse_luz(c, 8, hy + 0.5, 2.5, 2.4, "pena", 3)
            put(c, 7, hy - 2, cor("crista", 1)); put(c, 8, hy - 2, cor("crista", 2)); put(c, 8, hy - 3, cor("crista", 2))
            put(c, 7, hy, (20, 14, 16, 255)); put(c, 9, hy, (20, 14, 16, 255))
            put(c, 8, hy + 1, cor("bico", 2)); put(c, 8, hy + 2, cor("crista", 1))
        else:
            elipse_luz(c, 8, hy - 0.5, 2.4, 2.2, "pena", 3)
            put(c, 8, hy - 3, cor("crista", 1)); put(c, 7, hy - 3, cor("crista", 2))
    sobrepor(img, camada(W, H, pernas))
    if frente:
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
    else:
        sobrepor(img, camada(W, H, cabeca))
        sobrepor(img, camada(W, H, corpo))
    return img


def pintinho(direcao, quadro):
    W = H = 16
    img = nova(W, H)
    for x in range(5, 11):
        put(img, x, 15, (20, 30, 12, 60))
    come = quadro == 2
    passo = quadro == 1
    def corpo(c):
        elipse_luz(c, 8, 12, 3.0, 2.6, "pinto", 2)
        hx, hy = (8, 9) if direcao in ("baixo", "cima") else (6, 9)
        if come:
            hy += 2
        elipse_luz(c, hx, hy, 2.0, 2.0, "pinto", 2)
        for lx in ((7, 9) if not passo else (6, 10)):
            put(c, lx, 14, cor("bico", 1))
    sobrepor(img, camada(W, H, corpo))
    hx, hy = (8, 9) if direcao in ("baixo", "cima") else (6, 9)
    if come:
        hy += 2
    if direcao == "baixo":
        put(img, hx - 1, hy - 1, (20, 14, 16, 255)); put(img, hx + 1, hy - 1, (20, 14, 16, 255)); put(img, hx, hy, cor("bico", 1))
    elif direcao in ("esquerda", "direita"):
        put(img, hx - 1, hy - 1, (20, 14, 16, 255)); put(img, hx - 2, hy, cor("bico", 1))
    return espelhar(img) if direcao == "direita" else img


# ------------------------------------------------------------------ quadrúpedes
def _pernas_lado(c, xs, y0, y1, rampa, passo, casco=True):
    for k, x in enumerate(xs):
        dy = 0
        if passo and k % 2 == 0:
            dy = -1
        for y in range(y0 + dy, y1 + dy):
            put(c, x, y, cor(rampa, 1))
            put(c, x + 1, y, cor(rampa, 0))
        if casco:
            put(c, x, y1 + dy - 1, cor("casco", 1)); put(c, x + 1, y1 + dy - 1, cor("casco", 0))


def _malhas(c, x0, y0, x1, y1, semente, dens=0.62):
    """Manchas pretas da vaca (só por cima do corpo já pintado)."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            if c[y, x, 3] == 0:
                continue
            n = 0.0
            for k in range(3):
                cx = x0 + hash01(semente, k, 1) * (x1 - x0)
                cy = y0 + hash01(semente, k, 2) * (y1 - y0)
                r = 4.0 + hash01(semente, k, 3) * 3.5
                n = max(n, 1 - math.hypot(x - cx, (y - cy) * 1.3) / r)
            if n > 0.24:
                put(c, x, y, cor("malha", 1 if y > (y0 + y1) / 2 else 2))


def vaca(direcao, quadro, filhote=False):
    W, H = 32, 32
    img = nova(W, H)
    passo = quadro == 1
    come = quadro == 2
    e = 0.7 if filhote else 1.0     # escala do filhote
    def S(v, base):   # escala em volta da base (pés no rodapé, centro x=16)
        return base + (v - base) * e
    for x in range(int(S(7, 16)), int(S(27, 16))):
        put(img, x, 31, (20, 30, 12, 70))
        put(img, x, 30, (20, 30, 12, 40))
    if direcao in ("esquerda", "direita"):
        def pernas(c):
            xs = [int(S(x, 16)) for x in (9, 12, 21, 24)]
            _pernas_lado(c, xs, int(S(22, 31)), 31, "vaca", passo)
        def corpo(c):
            for y in range(int(S(12, 31)), int(S(24, 31))):
                for x in range(int(S(8, 16)), int(S(27, 16))):
                    nx = (x - S(17.5, 16)) / (9.5 * e)
                    ny = (y - S(17.5, 31)) / (6.2 * e)
                    if nx ** 4 + ny ** 4 <= 1:
                        v = -(nx * 0.4 + ny * 0.9)
                        put(c, x, y, cor("vaca", max(0, min(3, int(round(2 + v * 1.2))))))
            _malhas(c, int(S(8, 16)), int(S(12, 31)), int(S(27, 16)), int(S(24, 31)), 11)
            if not filhote:
                for x in range(20, 24):   # úbere
                    put(c, x, 24, cor("focinho", 2)); put(c, x, 25, cor("focinho", 1) if x in (20, 23) else (0, 0, 0, 0))
            tx = int(S(27, 16))   # rabo
            for y in range(int(S(13, 31)), int(S(21, 31))):
                put(c, tx, y, cor("vaca", 1))
            put(c, tx, int(S(21, 31)), cor("malha", 1)); put(c, tx, int(S(22, 31)), cor("malha", 0))
        def cabeca(c):
            hx, hy = S(6, 16), S(13, 31) + (6 * e if come else 0)
            for y in range(int(hy) - 4, int(hy) + 5):
                for x in range(int(hx) - 4, int(hx) + 4):
                    nx = (x + 0.5 - hx) / (4.0 * e)
                    ny = (y + 0.5 - hy) / (4.6 * e)
                    if nx * nx + ny * ny <= 1:
                        put(c, x, y, cor("vaca", 3 if ny < 0 else 2))
            sx = int(hx - 4 * e)
            for y in range(int(hy + 1 * e), int(hy + 5 * e)):   # focinho
                for x in range(sx, sx + max(2, int(4 * e))):
                    put(c, x, y, cor("focinho", 2 if y < hy + 3 * e else 1))
            put(c, sx + 1, int(hy + 3 * e), cor("focinho", 0))
            put(c, int(hx - 1), int(hy - 1), (20, 14, 16, 255))   # olho
            put(c, int(hx + 2), int(hy - 3 * e), cor("vaca", 2)); put(c, int(hx + 3), int(hy - 3 * e), cor("malha", 1))   # orelha
            if not filhote:
                put(c, int(hx), int(hy - 5), cor("chifre", 2)); put(c, int(hx), int(hy - 6), cor("chifre", 1))
            put(c, int(hx + 1), int(hy - 2), cor("malha", 2)); put(c, int(hx + 2), int(hy - 1), cor("malha", 2))
        sobrepor(img, camada(W, H, pernas))
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
        return espelhar(img) if direcao == "direita" else img
    frente = direcao == "baixo"
    def pernas(c):
        xs = [int(S(x, 16)) for x in (10, 20)] if frente else [int(S(x, 16)) for x in (10, 20)]
        _pernas_lado(c, xs, int(S(24, 31)), 31, "vaca", passo)
    def corpo(c):
        cy = S(17 if frente else 16, 31)
        for y in range(int(cy - 8 * e), int(cy + 8 * e) + 1):
            for x in range(int(S(8, 16)), int(S(24, 16)) + 1):
                nx = (x + 0.5 - 16) / (8.0 * e)
                ny = (y + 0.5 - cy) / (8.5 * e)
                if nx ** 4 + ny ** 4 <= 1:
                    v = -(nx * 0.5 + ny * 0.8)
                    put(c, x, y, cor("vaca", max(0, min(3, int(round(2 + v * 1.2))))))
        _malhas(c, int(S(8, 16)), int(cy - 8 * e), int(S(25, 16)), int(cy + 8 * e), 23 if frente else 29, 0.55)
        if not frente:
            for y in range(int(cy - 4 * e), int(cy + 6 * e)):
                put(c, 16, y, cor("vaca", 1))
            put(c, 16, int(cy + 6 * e), cor("malha", 1))
    def cabeca(c):
        hy = S(12, 31) + (5 * e if come else 0)
        for y in range(int(hy - 5 * e), int(hy + 6 * e)):
            for x in range(int(S(11, 16)), int(S(21, 16)) + 1):
                nx = (x + 0.5 - 16) / (4.6 * e)
                ny = (y + 0.5 - hy) / (5.6 * e)
                if nx * nx + ny * ny <= 1:
                    put(c, x, y, cor("vaca", 3 if ny < -0.2 else 2))
        for y in range(int(hy + 2 * e), int(hy + 6 * e)):
            for x in range(int(S(12, 16)), int(S(20, 16)) + 1):
                if abs(x + 0.5 - 16) <= 3.8 * e:
                    put(c, x, y, cor("focinho", 2 if y < hy + 4 * e else 1))
        put(c, int(16 - 2 * e), int(hy + 4 * e), cor("focinho", 0)); put(c, int(16 + 1 * e), int(hy + 4 * e), cor("focinho", 0))
        put(c, int(16 - 2.5 * e), int(hy - 1), (20, 14, 16, 255)); put(c, int(16 + 2 * e), int(hy - 1), (20, 14, 16, 255))
        for sx in (-1, 1):   # orelhas
            ox = int(16 + sx * 5.5 * e)
            put(c, ox, int(hy - 3 * e), cor("vaca", 2)); put(c, ox + sx, int(hy - 3 * e), cor("malha", 1))
            if not filhote:
                put(c, int(16 + sx * 3.5), int(hy - 6), cor("chifre", 2)); put(c, int(16 + sx * 4.5), int(hy - 7), cor("chifre", 1))
        put(c, 15, int(hy - 3 * e), cor("malha", 2)); put(c, 16, int(hy - 4 * e), cor("malha", 2))
    sobrepor(img, camada(W, H, pernas))
    if frente:
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
    else:
        sobrepor(img, camada(W, H, cabeca))
        sobrepor(img, camada(W, H, corpo))
    return img


def ovelha(direcao, quadro, filhote=False, tosquiada=False):
    W, H = 24, 24
    img = nova(W, H)
    passo = quadro == 1
    come = quadro == 2
    e = 0.72 if filhote else 1.0
    def S(v, base):
        return base + (v - base) * e
    for x in range(int(S(5, 12)), int(S(20, 12))):
        put(img, x, 23, (20, 30, 12, 70))
    rampa_corpo = "pele_ov" if tosquiada else "la"
    def nuvem(c, cx, cy, rx, ry):
        if tosquiada:
            elipse_luz(c, cx, cy, rx * 0.85, ry * 0.8, "pele_ov", 2)
            return
        for k in range(9):
            a = k / 9.0 * math.tau
            elipse_luz(c, cx + math.cos(a) * rx * 0.6, cy + math.sin(a) * ry * 0.55, rx * 0.5, ry * 0.55, "la", 3, 1.4)
        elipse_luz(c, cx, cy, rx * 0.75, ry * 0.7, "la", 3, 1.0)
    if direcao in ("esquerda", "direita"):
        def pernas(c):
            xs = [int(S(x, 12)) for x in (7, 10, 15, 17)]
            _pernas_lado(c, xs, int(S(18, 23)), 23, "cara_ov", passo, casco=False)
        def corpo(c):
            nuvem(c, S(13, 12), S(13, 23), 7.0 * e, 5.0 * e)
        def cabeca(c):
            hx, hy = S(5, 12), S(10, 23) + (5 * e if come else 0)
            elipse_luz(c, hx, hy, 2.6 * e + 0.4, 3.0 * e + 0.4, "cara_ov", 2)
            put(c, int(hx - 1), int(hy - 1), (230, 220, 200, 255))
            put(c, int(hx + 2), int(hy - 2), cor("cara_ov", 1)); put(c, int(hx + 3), int(hy - 1), cor("cara_ov", 1))
            if not tosquiada:
                put(c, int(hx + 1), int(hy - 3), cor("la", 3)); put(c, int(hx), int(hy - 3), cor("la", 4))
        sobrepor(img, camada(W, H, pernas))
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
        return espelhar(img) if direcao == "direita" else img
    frente = direcao == "baixo"
    def pernas(c):
        xs = [int(S(x, 12)) for x in (8, 14)]
        _pernas_lado(c, xs, int(S(19, 23)), 23, "cara_ov", passo, casco=False)
    def corpo(c):
        nuvem(c, 12, S(13, 23), 6.0 * e, 6.2 * e)
    def cabeca(c):
        hy = S(9, 23) + (4 * e if come else 0)
        if frente:
            elipse_luz(c, 12, hy, 2.8 * e + 0.3, 3.2 * e + 0.3, "cara_ov", 2)
            put(c, int(12 - 1.5 * e), int(hy - 1), (230, 220, 200, 255)); put(c, int(12 + 1 * e), int(hy - 1), (230, 220, 200, 255))
            for sx in (-1, 1):
                put(c, int(12 + sx * 3.5 * e), int(hy - 2), cor("cara_ov", 1))
            if not tosquiada:
                for x in range(int(12 - 2 * e), int(12 + 2 * e) + 1):
                    put(c, x, int(hy - 3.2 * e), cor("la", 4))
        else:
            elipse_luz(c, 12, hy - 1, 2.6 * e + 0.3, 2.6 * e + 0.3, "cara_ov" if tosquiada else "la", 2)
    sobrepor(img, camada(W, H, pernas))
    if frente:
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
    else:
        sobrepor(img, camada(W, H, cabeca))
        sobrepor(img, camada(W, H, corpo))
    return img


def porco(direcao, quadro, filhote=False):
    W, H = 24, 24
    img = nova(W, H)
    passo = quadro == 1
    come = quadro == 2
    e = 0.7 if filhote else 1.0
    def S(v, base):
        return base + (v - base) * e
    for x in range(int(S(5, 12)), int(S(20, 12))):
        put(img, x, 23, (20, 30, 12, 70))
    if direcao in ("esquerda", "direita"):
        def pernas(c):
            xs = [int(S(x, 12)) for x in (7, 10, 15, 17)]
            _pernas_lado(c, xs, int(S(19, 23)), 23, "porco", passo, casco=False)
        def corpo(c):
            elipse_luz(c, S(13, 12), S(15, 23), 7.0 * e, 4.6 * e, "porco", 3)
            tx, ty = int(S(20, 12)), int(S(13, 23))   # rabinho enrolado
            for (dx, dy) in ((0, 0), (1, -1), (2, 0), (1, 1)):
                put(c, tx + dx, ty + dy, cor("porco", 2))
        def cabeca(c):
            hx, hy = S(6, 12), S(13, 23) + (4 * e if come else 0)
            elipse_luz(c, hx, hy, 3.4 * e + 0.3, 3.2 * e + 0.3, "porco", 3)
            sx = int(hx - 3.6 * e)
            for y in range(int(hy), int(hy + 3)):
                put(c, sx, y, cor("porco", 2)); put(c, sx - 1, y, cor("porco", 2))
            put(c, sx - 1, int(hy + 1), cor("porco", 0))
            put(c, int(hx - 1), int(hy - 1), (20, 14, 16, 255))
            put(c, int(hx + 1), int(hy - 3 * e - 1), cor("porco", 2)); put(c, int(hx + 2), int(hy - 3 * e - 1), cor("porco", 1))
        sobrepor(img, camada(W, H, pernas))
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
        return espelhar(img) if direcao == "direita" else img
    frente = direcao == "baixo"
    def pernas(c):
        xs = [int(S(x, 12)) for x in (8, 14)]
        _pernas_lado(c, xs, int(S(19, 23)), 23, "porco", passo, casco=False)
    def corpo(c):
        elipse_luz(c, 12, S(14, 23), 6.0 * e, 6.0 * e, "porco", 3)
        if not frente:
            for (dx, dy) in ((0, 0), (1, -1), (2, 0), (1, 1)):
                put(c, 11 + dx, int(S(10, 23)) + dy, cor("porco", 2))
    def cabeca(c):
        hy = S(12, 23) + (4 * e if come else 0)
        if frente:
            elipse_luz(c, 12, hy, 3.6 * e + 0.3, 3.4 * e + 0.3, "porco", 3)
            for x in range(int(12 - 1.5 * e), int(12 + 1.5 * e) + 1):
                put(c, x, int(hy + 1), cor("porco", 2)); put(c, x, int(hy + 2), cor("porco", 2))
            put(c, int(12 - 1 * e), int(hy + 1), cor("porco", 0)); put(c, int(12 + 1 * e), int(hy + 1), cor("porco", 0))
            put(c, int(12 - 2 * e), int(hy - 1), (20, 14, 16, 255)); put(c, int(12 + 2 * e), int(hy - 1), (20, 14, 16, 255))
            for sx in (-1, 1):
                put(c, int(12 + sx * 3 * e), int(hy - 3.5 * e), cor("porco", 2))
        else:
            for sx in (-1, 1):
                put(c, int(12 + sx * 3 * e), int(hy - 3.5 * e - 2), cor("porco", 2))
    sobrepor(img, camada(W, H, pernas))
    if frente:
        sobrepor(img, camada(W, H, corpo))
        sobrepor(img, camada(W, H, cabeca))
    else:
        sobrepor(img, camada(W, H, cabeca))
        sobrepor(img, camada(W, H, corpo))
    return img


def folha(fn, w, h, **kw):
    img = nova(w * 3, h * 4)
    for r, d in enumerate(DIRS):
        for q in range(3):
            img[r * h:(r + 1) * h, q * w:(q + 1) * w] = fn(d, q, **kw)
    return img


def gerar(caminho, salvar):
    salvar(folha(galinha, 16, 16), caminho("animais", "galinha.png"))
    salvar(folha(galinha, 16, 16, filhote=True), caminho("animais", "galinha_filhote.png"))
    salvar(folha(vaca, 32, 32), caminho("animais", "vaca.png"))
    salvar(folha(vaca, 32, 32, filhote=True), caminho("animais", "vaca_filhote.png"))
    salvar(folha(ovelha, 24, 24), caminho("animais", "ovelha.png"))
    salvar(folha(ovelha, 24, 24, tosquiada=True), caminho("animais", "ovelha_tosquiada.png"))
    salvar(folha(ovelha, 24, 24, filhote=True), caminho("animais", "ovelha_filhote.png"))
    salvar(folha(porco, 24, 24), caminho("animais", "porco.png"))
    salvar(folha(porco, 24, 24, filhote=True), caminho("animais", "porco_filhote.png"))


def icone(especie):
    """Ícone 16x16 do animal para a loja e o inventário (filhote de frente; a galinha adulta)."""
    import numpy as np
    fn = {"galinha": galinha, "vaca": vaca, "ovelha": ovelha, "porco": porco}[especie]
    im = fn("baixo", 0) if especie == "galinha" else fn("baixo", 0, filhote=True)
    a = im[:, :, 3] > 100   # sem a sombra
    ys, xs = np.nonzero(a)
    y0, x0 = ys.min(), xs.min()
    y1, x1 = min(ys.max() + 1, y0 + 16), min(xs.max() + 1, x0 + 16)
    rec = im[y0:y1, x0:x1]
    c = nova(16, 16)
    oy = 16 - rec.shape[0]
    ox = (16 - rec.shape[1]) // 2
    c[oy:oy + rec.shape[0], ox:ox + rec.shape[1]] = rec
    return c
