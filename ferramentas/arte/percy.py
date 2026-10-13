"""Arte de Percy Jackson e o Ladrão de Raios (dimensão Além da Névoa), desenho próprio.

Personagens com a mesma base do jogador (16x32) recoloridos; Quíron e o homem-touro em quadros maiores.
Folhas de inimigos em game/assets/sprites/inimigos/ (linhas: baixo, cima, esquerda, direita;
colunas: parado, passo 1, passo 2, preparo).
"""
import math
from pixel import RAMPAS, nova, put, cor, hexc, contornar, hash01, retangulo, salvar
import gerar_arte as GA
from gerar_arte import caminho, _sombra, copa
from animais import elipse_luz, camada, sobrepor, espelhar
from cidade import _recolorir
from livros import personagem

RAMPAS.update({
    "touro":      ["#24140d", "#3a2216", "#56331f", "#73472b", "#916039", "#ad7c4f"],
    "focinho_t":  ["#6b4a3a", "#93705a", "#b8957b", "#d5b59a"],
    "chifre_t":   ["#8c8068", "#bdb294", "#e2d9bd", "#f6f1dd"],
    "bronze":     ["#5e3a12", "#8e5e1e", "#c08a32", "#e8b955", "#f8dd8a"],
    "cueca":      ["#9ea3ad", "#c6cad2", "#e6e8ec", "#ffffff"],
    "camisa_laranja": ["#6e2c0c", "#9a4314", "#c85d1c", "#e9802e", "#f6a95a"],
    "pelo_bode":  ["#543821", "#6e4a2c", "#8c6239", "#a87b4c"],
    "cabelo_areia": ["#5e4220", "#85602f", "#a98142", "#c6a05c", "#dcbd80"],
    "casco_b":    ["#1e1612", "#2e221b", "#433229"],
    "cavalo":     ["#9b958c", "#c3bdb2", "#e2ddd3", "#f6f3ec", "#ffffff"],
    "tweed":      ["#3a2c22", "#54402f", "#70573f", "#8c7052", "#a88a68"],
    "barba_q":    ["#3a2416", "#563620", "#72492b", "#8e5f39"],
    "asfalto":    ["#1f1f25", "#2a2a31", "#36363e", "#44444c", "#55555e"],
    "palha":      ["#6e5320", "#97752f", "#bf9a44", "#dcbd62", "#efd88e"],
    "areia":      ["#8c7348", "#a98c5a", "#c4a771", "#d9be88", "#ead3a2"],
    "azul_ceu":   ["#2c4f78", "#3f6b9a", "#5689ba", "#79a8d3", "#a6c9e8"],
    "morango":    ["#6e1018", "#a11c26", "#d33036", "#f0605a", "#fb9a8a"],
})
CONT = hexc("#1e1420")


def cabelo_comprido(folha, rampa, n=5):
    """Estica o cabelo (cor da 'rampa') para baixo nos lados (frente), atrás da cabeça (costas)
    e na nuca (de lado), em cada quadro 16x32 da folha do jogador. Contorna só o cabelo novo."""
    import numpy as np
    out = folha.copy()
    cores = [hexc(h)[:3] for h in RAMPAS[rampa]]
    linhas = folha.shape[0] // 32
    colunas = folha.shape[1] // 16
    for r in range(linhas):
        for q in range(colunas):
            y0, x0 = r * 32, q * 16
            f = out[y0:y0 + 32, x0:x0 + 16]
            cab = np.zeros((32, 16), dtype=bool)
            for c in cores:
                cab |= (f[:, :, 0] == c[0]) & (f[:, :, 1] == c[1]) & (f[:, :, 2] == c[2])
            ys, xs = np.nonzero(cab)
            if len(xs) == 0:
                continue
            minx, maxx = xs.min(), xs.max()
            if r == 0:
                cols = [minx, minx + 1, maxx - 1, maxx]
            elif r == 1:
                cols = list(range(minx + 1, maxx))
            elif r == 2:
                cols = [maxx - 2, maxx - 1, maxx]
            else:
                cols = [minx, minx + 1, minx + 2]
            novos = []
            for x in cols:
                col = np.nonzero(cab[:, x])[0]
                if len(col) == 0:
                    continue
                yb = col.max()
                for k in range(1, n + 1):
                    y = yb + k
                    if y >= 31:
                        break
                    i = 2 if k < n - 1 else 1
                    if x in (minx, maxx):
                        i = 1
                    f[y, x] = hexc(RAMPAS[rampa][i])
                    novos.append((x, y))
            ocupado = set(novos)
            for (x, y) in novos:
                for dx, dy in ((1, 0), (-1, 0), (0, 1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < 16 and 0 <= yy < 32 and (xx, yy) not in ocupado and f[yy, xx, 3] == 0:
                        f[yy, xx] = CONT
    return out


# ------------------------------------------------------------------ homem-touro (32x40)
def homem_touro(direcao, quadro):
    W, H = 32, 40
    img = nova(W, H)
    for x in range(7, 26):
        put(img, x, 39, (10, 12, 20, 90))
        if 9 <= x <= 23:
            put(img, x, 38, (10, 12, 20, 60))
    passo = quadro in (1, 2)
    perna = 1 if quadro == 1 else -1
    preparo = quadro == 3
    baixa = 3 if preparo else 0
    if direcao in ("baixo", "cima"):
        frente = direcao == "baixo"
        def pernas(c):
            for i, x0 in enumerate((10, 17)):
                ergue = 1 if passo and ((perna == 1) == (i == 0)) else 0
                for y in range(28, 36 - ergue):
                    for x in range(x0, x0 + 5):
                        put(c, x, y, cor("touro", 4 if x == x0 else 3 if x < x0 + 4 else 2))
                for y in range(36 - ergue, 38 - ergue):
                    for x in range(x0, x0 + 5):
                        put(c, x, y, cor("casco_b", 1 if y == 36 - ergue else 0))
        def corpo(c):
            elipse_luz(c, 16, 21, 10.5, 8.5, "touro", 3, 1.1)
            for y in range(25, 29):   # cueca branca (o livro conta)
                for x in range(10, 22):
                    put(c, x, y, cor("cueca", 2 if y < 27 else 1))
            if frente:
                elipse_luz(c, 16, 19, 5.0, 3.5, "touro", 4, 0.8)   # peito mais claro
            for lado in (-1, 1):   # braços grossos
                bx = 16 + lado * 11
                for y in range(15, 30 if not preparo else 27):
                    for x in (bx - 2, bx - 1, bx, bx + 1):
                        put(c, x, y, cor("touro", 3 if (x - bx) * lado < 0 else 2))
                for x in (bx - 2, bx - 1, bx, bx + 1):
                    put(c, x, 30 if not preparo else 27, cor("touro", 1))
        def cabeca(c):
            hy = 9 + baixa
            elipse_luz(c, 16, hy, 6.0, 6.0, "touro", 3, 1.0)
            for lado in (-1, 1):   # chifres para os lados e para cima
                for k in range(5):
                    put(c, 16 + lado * (6 + k), hy - 3 - (k // 2), cor("chifre_t", 2 if k < 3 else 3))
                    put(c, 16 + lado * (6 + k), hy - 2 - (k // 2), cor("chifre_t", 1))
                put(c, 16 + lado * 6, hy - 1, cor("touro", 2))   # orelha
                put(c, 16 + lado * 7, hy, cor("touro", 2))
            if frente:
                for y in range(hy + 1, hy + 6):   # focinho
                    for x in range(12, 21):
                        if abs(x + 0.5 - 16.5) <= 4 - (1 if y == hy + 5 else 0):
                            put(c, x, y, cor("focinho_t", 2 if y < hy + 3 else 1))
                put(c, 14, hy + 3, cor("focinho_t", 0)); put(c, 18, hy + 3, cor("focinho_t", 0))
                for x in range(14, 19):   # argola de bronze
                    put(c, x, hy + 6, cor("bronze", 3 if x != 16 else 4))
                put(c, 13, hy - 2, (210, 40, 40, 255)); put(c, 19, hy - 2, (210, 40, 40, 255))
        sobrepor(img, camada(W, H, pernas))
        if frente:
            sobrepor(img, camada(W, H, corpo))
            sobrepor(img, camada(W, H, cabeca))
        else:
            sobrepor(img, camada(W, H, cabeca))
            sobrepor(img, camada(W, H, corpo))
        return img
    # de lado (esquerda; direita = espelho)
    def perna_tras(c):
        d = 2 * perna if passo else 0
        for y in range(28, 36):
            for x in range(15 + d, 19 + d):
                put(c, x, y, cor("touro", 2))
        for y in (36, 37):
            for x in range(15 + d, 19 + d):
                put(c, x, y, cor("casco_b", 0))
    def perna_frente(c):
        d = -2 * perna if passo else 0
        for y in range(28, 36):
            for x in range(13 + d, 17 + d):
                put(c, x, y, cor("touro", 3 if x < 15 + d else 2))
        for y in (36, 37):
            for x in range(13 + d, 17 + d):
                put(c, x, y, cor("casco_b", 1))
    def corpo(c):
        elipse_luz(c, 17, 21, 7.5, 8.5, "touro", 3, 1.1)
        for y in range(25, 29):
            for x in range(11, 23):
                if abs(x + 0.5 - 17) <= 6:
                    put(c, x, y, cor("cueca", 2 if y < 27 else 1))
    def braco(c):
        d = -perna * 2 if passo else 0
        if preparo:
            for x in range(9, 17):   # braços para a frente, baixos
                for y in (22, 23, 24):
                    put(c, x, y, cor("touro", 3 if y == 22 else 2))
            return
        for y in range(15, 29):
            k = (y - 15) / 14.0
            x0 = int(round(16 + d * k))
            for x in (x0, x0 + 1, x0 + 2):
                put(c, x, y, cor("touro", 3 if x == x0 else 2))
    def cabeca(c):
        hx, hy = (9, 9 + baixa) if not preparo else (8, 14)
        elipse_luz(c, hx + 3, hy, 5.0, 5.5, "touro", 3, 1.0)
        for y in range(hy, hy + 5):   # focinho para a esquerda
            for x in range(hx - 3, hx + 2):
                put(c, x, y, cor("focinho_t", 2 if y < hy + 2 else 1))
        put(c, hx - 3, hy + 2, cor("focinho_t", 0))
        put(c, hx - 2, hy + 5, cor("bronze", 3)); put(c, hx - 3, hy + 5, cor("bronze", 4)); put(c, hx - 1, hy + 5, cor("bronze", 2))
        put(c, hx + 1, hy - 2, (210, 40, 40, 255))
        for k in range(6):   # chifre para a frente e para cima
            put(c, hx + 3 - k, hy - 4 - (2 if k > 3 else 1 if k > 1 else 0), cor("chifre_t", 2 if k < 4 else 3))
        put(c, hx + 6, hy - 2, cor("touro", 2)); put(c, hx + 7, hy - 1, cor("touro", 1))
    sobrepor(img, camada(W, H, perna_tras))
    sobrepor(img, camada(W, H, perna_frente))
    sobrepor(img, camada(W, H, corpo))
    sobrepor(img, camada(W, H, braco))
    sobrepor(img, camada(W, H, cabeca))
    return espelhar(img) if direcao == "direita" else img


def boneco_palha(direcao, quadro):
    """Boneco de treino de palha num poste (16x32); o quadro 3 balança."""
    img = nova(16, 32)
    _sombra(img, 8, 30, 4.5, 1.5, 80)
    inc = 1 if quadro == 3 else 0
    def poste(c):
        for y in range(22, 30):
            put(c, 7, y, cor("madeira", 4)); put(c, 8, y, cor("madeira", 2))
    def corpo(c):
        elipse_luz(c, 8 + inc, 17, 4.2, 5.5, "palha", 3, 1.2)
        for y in range(12, 23):   # cordas amarrando
            if y in (14, 19):
                for x in range(4 + inc, 13 + inc):
                    put(c, x, y, cor("madeira", 1))
        for x in range(2 + inc, 15 + inc):   # braços em cruz
            put(c, x, 15, cor("palha", 3)); put(c, x, 16, cor("palha", 2))
        elipse_luz(c, 8 + inc * 2, 8, 3.2, 3.2, "palha", 3, 1.2)
        for (x, y) in ((7, 4), (9, 4), (8, 3), (6, 5), (10, 5)):
            put(c, x + inc * 2, y, cor("palha", 4))
    sobrepor(img, camada(16, 32, poste))
    sobrepor(img, camada(16, 32, corpo))
    if direcao == "direita":
        return espelhar(img)
    return img


def folha(fn, w, h):
    img = nova(w * 4, h * 4)
    for r, d in enumerate(["baixo", "cima", "esquerda", "direita"]):
        for q in range(4):
            img[r * h:(r + 1) * h, q * w:(q + 1) * w] = fn(d, q)
    return img


# ------------------------------------------------------------------ Quíron (32x40, centauro)
def quiron(direcao):
    W, H = 32, 40
    img = nova(W, H)
    for x in range(3, 30):
        put(img, x, 39, (10, 12, 20, 80))
    lado = direcao in ("esquerda", "direita")
    def cavalo(c):
        if lado:
            elipse_luz(c, 18, 26, 11.0, 6.0, "cavalo", 3, 1.0)
            for x0 in (9, 12, 23, 26):   # pernas
                for y in range(29, 37):
                    put(c, x0, y, cor("cavalo", 2)); put(c, x0 + 1, y, cor("cavalo", 1))
                for y in (37, 38):
                    put(c, x0, y, cor("casco_b", 1)); put(c, x0 + 1, y, cor("casco_b", 0))
            for y in range(23, 34):   # rabo
                put(c, 29 + (y - 23) // 5, y, cor("cabelo_grisalho", 2))
                put(c, 30 + (y - 23) // 5, y, cor("cabelo_grisalho", 1))
        else:
            elipse_luz(c, 16, 27, 8.5, 7.0, "cavalo", 3, 1.0)
            for x0 in (10, 20):
                for y in range(31, 37):
                    put(c, x0, y, cor("cavalo", 2)); put(c, x0 + 1, y, cor("cavalo", 1))
                for y in (37, 38):
                    put(c, x0, y, cor("casco_b", 1)); put(c, x0 + 1, y, cor("casco_b", 0))
    def torso(c):
        tx = 10 if direcao == "esquerda" else 21 if direcao == "direita" else 16
        larg = 4 if lado else 5
        for y in range(13, 24):   # paletó de tweed
            for x in range(tx - larg, tx + larg):
                put(c, x, y, cor("tweed", 3 if x < tx - 1 else 2 if x < tx + 2 else 1))
        if not lado:
            for y in range(13, 16):
                put(c, tx, y, cor("camisa_branca", 3))
        for y in range(14, 22):   # braços
            for x in (tx - larg - 1, tx + larg):
                put(c, x, y, cor("tweed", 2))
        put(c, tx - larg - 1, 22, cor("pele", 3)); put(c, tx + larg, 22, cor("pele", 2))
        # cabeça com barba castanha e cabelo
        elipse_luz(c, tx, 8, 3.6, 4.0, "pele", 3, 0.8)
        for y in range(9, 14):
            for x in range(tx - 3, tx + 4):
                if abs(x + 0.5 - (tx + 0.5)) <= 3.5 - (y - 9) * 0.6:
                    put(c, x, y, cor("barba_q", 2 if y < 12 else 1))
        for x in range(tx - 3, tx + 4):
            put(c, x, 4, cor("barba_q", 2)); put(c, x, 5, cor("barba_q", 3))
        if direcao == "cima":
            for y in range(4, 11):
                for x in range(tx - 3, tx + 4):
                    put(c, x, y, cor("barba_q", 2 if y < 8 else 1))
        elif direcao == "baixo":
            put(c, tx - 2, 8, (20, 14, 16, 255)); put(c, tx + 2, 8, (20, 14, 16, 255))
        else:
            put(c, tx - 2 if direcao == "esquerda" else tx + 2, 8, (20, 14, 16, 255))
    if direcao == "cima":
        sobrepor(img, camada(W, H, cavalo))
        sobrepor(img, camada(W, H, torso))
    elif lado:
        sobrepor(img, camada(W, H, cavalo))
        sobrepor(img, camada(W, H, torso))
    else:
        sobrepor(img, camada(W, H, cavalo))
        sobrepor(img, camada(W, H, torso))
    return img


def folha_parada(fn, w, h):
    """Folha de NPC parado: uma coluna, 4 linhas (baixo, cima, esquerda, direita)."""
    img = nova(w, h * 4)
    for r, d in enumerate(["baixo", "cima", "esquerda", "direita"]):
        img[r * h:(r + 1) * h, 0:w] = fn(d)
    return img


# ------------------------------------------------------------------ objetos
def pinheiro_thalia():
    """O pinheiro alto no topo da colina, fronteira do vale (48x88)."""
    img = nova(48, 88)
    _sombra(img, 24, 84, 18, 4, 90)
    for y in range(62, 85):
        for x in range(21, 28):
            put(img, x, y, cor("tronco", 3 if x < 23 else 2 if x < 26 else 1))
    camadas = [(10, 9), (22, 13), (35, 17), (48, 20), (61, 22)]
    for k, (topo, meia) in enumerate(camadas):
        alt = 18
        for y in range(topo, topo + alt):
            larg = 2 + (y - topo) / alt * meia
            for x in range(int(24 - larg), int(24 + larg) + 1):
                v = -((x - 24) / max(1, larg)) * 0.7 - (y - topo) / alt * 0.6
                i = int(round(3 + v * 2))
                if (y - topo) > alt - 3 and hash01(x, y, k) > 0.4:
                    i -= 1
                put(img, x, y, cor("folha", max(0, min(5, i))))
    for y in range(4, 12):
        for x in range(23 - (y - 4) // 3, 26 + (y - 4) // 3):
            put(img, x, y, cor("folha", 4))
    contornar(img, hexc("#0f1d10"))
    return img


def carro_vala():
    """Carro parado torto na vala da estrada, com os faróis acesos (48x32)."""
    img = nova(48, 32)
    _sombra(img, 24, 28, 22, 4, 90)
    def corpo(c):
        for y in range(12, 26):
            for x in range(3, 45):
                inc = (x - 3) // 14   # inclinado (uma roda na vala)
                if y - inc < 12 or y - inc > 25:
                    continue
                i = 3 if y < 16 else 2 if y < 22 else 1
                put(c, x, y + inc - 1, cor("azul_ceu", i))
        for y in range(6, 13):   # cabine
            for x in range(12, 34):
                if abs(x - 23) <= 10 - max(0, 9 - y):
                    put(c, x, y, cor("azul_ceu", 3))
        for y in range(8, 12):
            for x in range(14, 32):
                if abs(x - 23) <= 8 - max(0, 10 - y) and x != 23:
                    put(c, x, y, cor("vidro", 2 if y < 10 else 1))
        for (wx, wy) in ((10, 25), (37, 28)):   # rodas
            for y in range(wy - 2, wy + 3):
                for x in range(wx - 3, wx + 4):
                    if (x - wx) ** 2 + (y - wy) ** 2 <= 9:
                        put(c, x, y, cor("asfalto", 1 if (x - wx) ** 2 + (y - wy) ** 2 > 2 else 3))
        for y in (15, 16):   # farol aceso
            put(c, 3, y, (255, 240, 170, 255)); put(c, 4, y, (255, 240, 170, 255))
    sobrepor(img, camada(48, 32, corpo))
    return img


def estrada():
    """Tile 16x16 de estrada de asfalto molhado, com a faixa amarela no meio (na horizontal)."""
    img = nova(16, 16)
    for y in range(16):
        for x in range(16):
            i = 2
            if hash01(x, y, 91) > 0.85:
                i = 1
            elif hash01(x, y, 92) > 0.93:
                i = 3
            if y in (0, 15):
                i = 1
            put(img, x, y, cor("asfalto", i))
    for x in range(2, 10):
        put(img, x, 7, cor("milho", 2)); put(img, x, 8, cor("milho", 1))
    for x in range(10, 14):   # reflexo de chuva
        put(img, x, 12, cor("asfalto", 4))
    return img


def casa_grande():
    """A Casa Grande: quatro andares azul-céu e branco, varanda em volta e cata-vento de águia.
    112x128 (pegada 7x3; porta no meio, embaixo)."""
    W, H = 112, 128
    img = nova(W, H)
    _sombra(img, W / 2, H - 4, W / 2, 6, 90)
    base = H - 16
    def paredes(c):
        andares = 4
        alt = 18
        topo = base - andares * alt
        for k in range(andares):
            y0 = base - (k + 1) * alt
            recuo = k * 3
            for y in range(y0, y0 + alt):
                for x in range(6 + recuo, W - 6 - recuo):
                    tabua = (y - y0) % 4 == 0
                    i = 2 if tabua else 3
                    if x < 9 + recuo:
                        i = 4
                    if x > W - 10 - recuo:
                        i = 1
                    put(c, x, y, cor("azul_ceu", i))
            for x in range(6 + recuo, W - 6 - recuo):   # friso branco entre andares
                put(c, x, y0, cor("camisa_branca", 3)); put(c, x, y0 + 1, cor("camisa_branca", 2))
            # janelas brancas com vidro
            for jx in range(14 + recuo, W - 18 - recuo, 14):
                if k == 0 and abs(jx + 4 - W // 2) < 10:
                    continue
                for y in range(y0 + 5, y0 + 14):
                    for x in range(jx, jx + 8):
                        borda = x in (jx, jx + 7) or y in (y0 + 5, y0 + 13)
                        put(c, x, y, cor("camisa_branca", 3) if borda else cor("vidro", 2 if y < y0 + 9 else 1))
                put(c, jx + 3, y0 + 9, cor("camisa_branca", 3)); put(c, jx + 4, y0 + 9, cor("camisa_branca", 3))
        # telhado
        for y in range(topo - 10, topo + 1):
            meia = 30 + (y - (topo - 10)) * 2
            for x in range(W // 2 - meia, W // 2 + meia):
                put(c, x, y, cor("telhado_azul", 2 if (x + y) % 5 else 1))
        # cata-vento de águia
        for y in range(topo - 22, topo - 10):
            put(c, W // 2, y, cor("metal", 2))
        for (x, y) in ((-3, -20), (-2, -21), (-1, -21), (0, -22), (1, -21), (2, -21), (3, -20), (0, -19), (1, -18)):
            put(c, W // 2 + x, topo + y, cor("bronze", 3))
        # varanda com colunas brancas e teto
        for y in range(base - 14, base):
            for x in range(2, W - 2):
                if y < base - 12:
                    put(c, x, y, cor("camisa_branca", 3 if y == base - 14 else 2))
                elif (x - 2) % 12 in (0, 1):
                    put(c, x, y, cor("camisa_branca", 4 if (x - 2) % 12 == 0 else 2))
        for y in range(base - 4, base):
            for x in range(2, W - 2):
                if (x - 2) % 12 not in (0, 1) and y == base - 4:
                    put(c, x, y, cor("camisa_branca", 2))
        for y in range(base, base + 4):   # piso da varanda
            for x in range(1, W - 1):
                put(c, x, y, cor("madeira", 4 if y == base else 3))
        # porta
        for y in range(base - 11, base):
            for x in range(W // 2 - 5, W // 2 + 5):
                put(c, x, y, cor("madeira", 2 if x < W // 2 else 1))
        put(c, W // 2 + 3, base - 6, cor("bronze", 3))
        # degraus
        for y in range(base + 4, base + 10):
            for x in range(W // 2 - 8, W // 2 + 8):
                put(c, x, y, cor("madeira", 4 if (y - base) % 2 == 0 else 3))
    sobrepor(img, camada(W, H, paredes))
    return img


def casa_grande_janelas():
    """As janelas acesas da Casa Grande (por cima, à noite)."""
    W, H = 112, 128
    img = nova(W, H)
    base = H - 16
    for k in range(4):
        y0 = base - (k + 1) * 18
        recuo = k * 3
        for jx in range(14 + recuo, W - 18 - recuo, 14):
            if k == 0 and abs(jx + 4 - W // 2) < 10:
                continue
            for y in range(y0 + 6, y0 + 13):
                for x in range(jx + 1, jx + 7):
                    if not ((x in (jx + 3, jx + 4)) and y == y0 + 9):
                        put(img, x, y, (255, 214, 120, 255) if y < y0 + 10 else (240, 170, 80, 255))
    return img


def morangueiro():
    """Pé de morango 16x16 (não bloqueia), com frutinhas vermelhas."""
    img = nova(16, 16)
    def pe(c):
        for (cx, cy, r) in ((5, 10, 3.2), (10, 10, 3.2), (8, 7, 3.0)):
            elipse_luz(c, cx, cy, r, r * 0.8, "folha", 4, 1.2)
    sobrepor(img, camada(16, 16, pe, hexc("#13230f")))
    for (x, y) in ((4, 12), (11, 12), (8, 11)):
        put(img, x, y, cor("morango", 2)); put(img, x + 1, y, cor("morango", 3)); put(img, x, y + 1, cor("morango", 1))
        put(img, x, y - 1, cor("folha", 5))
    return img


def estante_armas():
    """Suporte de madeira com espadas de bronze da arena (32x32, pegada 2x1)."""
    img = nova(32, 32)
    _sombra(img, 16, 29, 14, 2.5, 80)
    def suporte(c):
        for y in range(10, 29):
            for x in (3, 4, 27, 28):
                put(c, x, y, cor("madeira", 4 if x in (3, 27) else 2))
        for x in range(3, 29):
            for y in (12, 13, 24, 25):
                put(c, x, y, cor("madeira", 5 if y in (12, 24) else 3))
    def espadas(c):
        for k, x in enumerate((8, 13, 18, 23)):
            for y in range(6, 22):
                put(c, x, y, cor("bronze", 4 if y < 8 else 3)); put(c, x + 1, y, cor("bronze", 2))
            for xx in range(x - 2, x + 4):
                put(c, xx, 22, cor("bronze", 1))
            for y in range(23, 27):
                put(c, x, y, cor("tronco", 2)); put(c, x + 1, y, cor("tronco", 1))
    sobrepor(img, camada(32, 32, suporte))
    sobrepor(img, camada(32, 32, espadas))
    return img


def areia_terreno():
    """Areia da arena em grade dupla (bordas arredondadas sobre a grama)."""
    from pixel import tiles_dual, valor_suave
    def pintar(img, x, y, s, wx, wy, q, m):
        if s <= 0:
            n = valor_suave(wx, wy, 4, 31)
            c = cor("areia", 3 if n > 0.45 else 2)
            if hash01(wx, wy, 32) > 0.93:
                c = cor("areia", 4)
            if hash01(wx, wy, 33) > 0.96:
                c = cor("areia", 1)
            if s > -1.0:
                c = cor("areia", 1)
            put(img, x, y, c)
        elif s <= 1.0:
            put(img, x, y, cor("grama", 1, 160))
    return tiles_dual(pintar, variantes=2, raio=5.0, ruido=0.6, semente=13)


# ------------------------------------------------------------------ itens
def icone_espada(c):
    for k in range(10):
        put(c, 4 + k, 11 - k, cor("bronze", 4)); put(c, 5 + k, 11 - k, cor("bronze", 2))
    put(c, 14, 1, cor("bronze", 4))
    for k in range(5):
        put(c, 2 + k, 9 + k - 4 + 4, cor("bronze", 1))
    for (x, y) in ((2, 13), (3, 12), (1, 14)):
        put(c, x, y, cor("tronco", 2))


def icone_chifre(c):
    for k in range(11):
        r = 2.4 - k * 0.2
        cx, cy = 3 + k * 0.9, 12 - k * 0.6 - (k * k) * 0.04
        for y in range(16):
            for x in range(16):
                if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= max(0.6, r):
                    put(c, x, y, cor("chifre_t", 3 if y + 0.5 < cy else 2))


def icone_dracma(c):
    for y in range(16):
        for x in range(16):
            d = math.hypot(x + 0.5 - 8, y + 0.5 - 8)
            if d <= 5.6:
                v = -((x - 8) * 0.6 + (y - 8) * 0.8) / 5.6
                put(c, x, y, cor("bronze", max(1, min(4, int(round(2.6 + v * 1.4))))))
    for (x, y) in ((7, 5), (8, 5), (6, 6), (9, 6), (7, 7), (8, 7), (7, 8), (7, 9), (7, 10), (8, 10)):
        put(c, x, y, cor("bronze", 1))   # um perfil gravado (desenho simples)


def gerar():
    salvar(folha(homem_touro, 32, 40), caminho("inimigos", "homem_touro.png"))
    salvar(folha(boneco_palha, 16, 32), caminho("inimigos", "boneco_palha.png"))
    salvar(folha_parada(quiron, 32, 40), caminho("personagens", "quiron.png"))
    salvar(personagem("cabelo", "camisa_laranja", "pelo_bode"), caminho("personagens", "grover.png"))
    salvar(cabelo_comprido(personagem("cabelo_loiro", "camisa_laranja", "calca"), "cabelo_loiro"), caminho("personagens", "annabeth.png"))
    salvar(personagem("cabelo_areia", "camisa_laranja", "calca"), caminho("personagens", "luke.png"))
    salvar(pinheiro_thalia(), caminho("objetos", "pinheiro_thalia.png"))
    salvar(carro_vala(), caminho("objetos", "carro_vala.png"))
    salvar(estrada(), caminho("terreno", "estrada.png"))
    salvar(casa_grande(), caminho("objetos", "casa_grande.png"))
    salvar(casa_grande_janelas(), caminho("objetos", "casa_grande_janelas.png"))
    salvar(morangueiro(), caminho("objetos", "morangueiro.png"))
    salvar(estante_armas(), caminho("objetos", "estante_armas.png"))
    salvar(areia_terreno(), caminho("terreno", "areia.png"))
