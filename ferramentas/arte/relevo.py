"""Relevo: morros (platôs) com paredão de pedra e terra, no jeito de Pokémon (GBA) e Stardew Valley.

- morro.png: grade dupla com só a beirada do platô (contorno escuro + linha clara); o topo é a
  própria grama do mapa. Na beirada de baixo não há contorno: ali começa o paredão.
- paredao.png: 6 colunas x 2 linhas de 16x16. Colunas: 0 sozinho, 1 ponta esquerda, 2 meio,
  3 ponta direita, 4 e 5 = meios variados. Linha 0 = parte de cima (grama caindo pela borda),
  linha 1 = parte de baixo (pé do paredão). O paredão ocupa as 2 células logo abaixo do platô.
"""
from pixel import RAMPAS, nova, put, cor, hash01, tiles_dual, hexc

RAMPAS["barranco"] = ["#2e211b", "#45322a", "#5d4535", "#775a43", "#927253", "#ad8c68", "#c7a57f"]
CONTORNO_MORRO = hexc("#1f2a14")


def morro():
    def pintar(img, x, y, s, wx, wy, q, m):
        if s > 0:
            return
        if s <= -2.0:
            put(img, x, y, (226, 245, 170, 26))   # topo um pouco mais claro (mais perto do sol)
            return
        abaixo_vazio = not (m & (4 if x < 8 else 8))
        if y >= 7 and abaixo_vazio:
            put(img, x, y, (226, 245, 170, 26))
            return          # beirada de baixo: o paredão continua dali
        if s > -1.0:
            put(img, x, y, CONTORNO_MORRO)
        else:
            put(img, x, y, cor("grama", 5))
    return tiles_dual(pintar, raio=2.5, ruido=0.0)


import math

LIMITES = [(10, 0.0), (17, 2.1), (24, 4.2)]   # linhas entre as camadas de rocha: (y médio, fase da onda)


def _limite(k, x):
    """y da linha k na coluna x: onda de período 16 px (casa entre tiles vizinhos de qualquer variação)."""
    y, fase = LIMITES[k]
    return y + int(round(1.3 * math.sin(2 * math.pi * x / 16.0 + fase)))


def _rachas(var):
    """Rachaduras curtas (x, y0, comprimento) por variação, longe da borda do tile."""
    r = []
    for j in range(2 + int(hash01(var, 1, 3) * 2)):
        r.append((3 + int(hash01(var, j, 4) * 10), 6 + int(hash01(var, j, 5) * 18), 2 + int(hash01(var, j, 6) * 3)))
    return r


def _rocha(img, ox, x, y, var, rachas):
    """Um pixel da face (y de 0 a 31): camadas de rocha onduladas, luz vinda de cima."""
    linhas = [_limite(k, x) for k in range(len(LIMITES))]
    if y in linhas:
        put(img, ox + x, y, cor("barranco", 0))
        return
    topo = max([l for l in linhas if l < y], default=-1)
    i = 3
    if topo >= 0 or y > 3:
        d = y - (topo if topo >= 0 else 3)
        if d == 1:
            i = 5
        elif d == 2:
            i = 4
    prox = min([l for l in linhas if l > y], default=31)
    if prox - y == 1:
        i = 1
    elif prox - y == 2:
        i = 2
    for rx, ry, n in rachas:
        if ry <= y < ry + n:
            if x == rx:
                i = 0
            elif x == rx + 1:
                i = min(6, i + 1)
    if hash01(x + var * 16, y, 6) > 0.9 and 2 <= i <= 4:
        i -= 1
    if hash01(x + var * 16, y, 7) > 0.96 and 2 <= i <= 4:
        i += 1
    if y >= 27:
        i = max(0, i - 1)
    if y >= 29:
        i = max(0, i - 1)
    put(img, ox + x, y, cor("barranco", i))


def paredao():
    atlas = nova(16 * 6, 32)
    for col in range(6):
        ox = col * 16
        esq = col in (0, 1)       # ponta esquerda aberta
        dir_ = col in (0, 3)
        var = col
        rachas = _rachas(var)
        for y in range(32):
            for x in range(16):
                wx = x + col * 5
                # grama caindo pela borda de cima (pingos irregulares)
                pingo = 3 + (1 if hash01(wx, 7, col) > 0.6 else 0) + (1 if hash01(wx, 8, col) > 0.85 else 0)
                if y < pingo:
                    c = cor("grama", 4) if y == 0 else cor("grama", 3) if y < pingo - 1 else cor("grama", 2)
                    put(atlas, ox + x, y, c)
                    continue
                if y == pingo:
                    put(atlas, ox + x, y, CONTORNO_MORRO)
                    continue
                _rocha(atlas, ox, x, y, var, rachas)
        # pé: contorno embaixo e tufos de grama na base
        for x in range(16):
            put(atlas, ox + x, 31, hexc("#1d140f"))
            if hash01(x, col, 9) > 0.7:
                put(atlas, ox + x, 30, cor("grama", 2))
                put(atlas, ox + x, 29, cor("grama", 3) if hash01(x, col, 10) > 0.5 else cor("barranco", 1))
        # pontas: borda arredondada com contorno
        for lado, ativo in ((0, esq), (15, dir_)):
            if not ativo:
                continue
            passo = 1 if lado == 0 else -1
            for y in range(32):
                recuo = 0
                if y >= 27:
                    recuo = 1
                put(atlas, ox + lado + passo * recuo, y, hexc("#1d140f"))
                for k in range(recuo):
                    atlas[y, ox + lado + passo * k] = (0, 0, 0, 0)
                # luz na quina esquerda, sombra na direita
                if 4 <= y < 27:
                    put(atlas, ox + lado + passo * (recuo + 1), y, cor("barranco", 5 if lado == 0 else 1))
    return atlas
