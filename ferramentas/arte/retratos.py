"""Retratos 48x48 dos personagens para a caixa de conversa (como no Stardew Valley), desenho próprio.

Cada retrato sai de uma ficha simples (pele, cabelo e penteado, barba, roupa, enfeites), então
personagem novo = linha nova em RETRATOS. Saída: game/assets/sprites/retratos/<arquivo>.png.
Nenhum retrato imita uma pessoa real: são rostos genéricos no estilo do jogo (D-066).
"""
import math
from pixel import RAMPAS, nova, put, cor, hexc, contornar, hash01, salvar
import cidade  # noqa: F401  (rampas de cabelo e roupa)
import percy  # noqa: F401  (rampas de Percy Jackson)

RAMPAS.update({
    "pele_morena": ["#5a3020", "#7d4a30", "#a3663f", "#c48459", "#dba57a"],
    "pele_clara": ["#8a5a48", "#b77d63", "#dca183", "#f0c4a4", "#fbe0c8"],
    "olho_azul": ["#1d3a5a", "#3a6c9a", "#76a8d0"],
    "olho_cinza": ["#3a4048", "#6a737e", "#a4adb8"],
    "olho_castanho": ["#2a1a10", "#4e3220", "#7a5236"],
    "olho_verde": ["#1f3a24", "#3a6a40", "#6aa070"],
    "couro": ["#2e1c12", "#47301f", "#62432c", "#7d583b"],
})
CONT = hexc("#1e1420")
W = H = 48


def _elipse(c, cx, cy, rx, ry, rampa, base, forca=1.0, luz=(0.55, 0.85), so_vazio=False):
    n = len(RAMPAS[rampa])
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx = (x + 0.5 - cx) / rx
            ny = (y + 0.5 - cy) / ry
            if nx * nx + ny * ny <= 1:
                if so_vazio and c[y, x, 3] > 0:
                    continue
                v = -(nx * luz[0] + ny * luz[1])
                put(c, x, y, cor(rampa, max(0, min(n - 1, int(round(base + v * forca))))))


def _camada(desenhar):
    c = nova(W, H)
    desenhar(c)
    contornar(c, CONT)
    return c


def _sobre(img, c):
    m = c[:, :, 3] > 0
    img[m] = c[m]


def retrato(pele="pele", cabelo="cabelo", estilo="curto", barba=None, roupa="camisa", olhos="olho_castanho",
            extras=(), barba_rampa=None, fundo="#cfe3b8"):
    img = nova(W, H)
    # fundo com vinheta suave
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - 24, y - 20) / 34.0
            base = hexc(fundo)
            k = 1.0 - 0.25 * d
            img[y, x] = (int(base[0] * k), int(base[1] * k), int(base[2] * k), 255)
    br = barba_rampa or cabelo
    # cabelo de trás (longo, lenço)
    def atras(c):
        if estilo in ("longo", "longo_cacheado"):
            for y in range(12, 44):
                for x in range(10, 39):
                    lado = x < 16 or x > 32
                    if lado and y < 42 - (2 if estilo == "longo" else 0) or (15 <= x <= 33 and y < 18):
                        i = 2 if (x + y) % 5 else 1
                        if estilo == "longo_cacheado" and hash01(x // 2, y // 3, 5) > 0.6:
                            i = 3
                        put(c, x, y, cor(cabelo, i))
        if estilo == "lenco":
            _elipse(c, 24, 18, 14, 14, cabelo, 2)
            for y in range(28, 42):
                for x in range(11, 37):
                    if x < 15 or x > 33:
                        put(c, x, y, cor(cabelo, 1))
    _sobre(img, _camada(atras))
    # ombros e roupa
    def corpo(c):
        for y in range(36, H):
            meia = 15 + (y - 36) * 0.9
            for x in range(int(24 - meia), int(24 + meia) + 1):
                if 0 <= x < W:
                    i = 3 if x < 24 - meia * 0.4 else 2 if x < 24 + meia * 0.5 else 1
                    put(c, x, y, cor(roupa, i))
        for y in range(36, 41):   # gola em V com a pele
            for x in range(24 - (40 - y), 24 + (40 - y) + 1):
                put(c, x, y, cor(pele, 2))
        if "avental" in extras:
            for y in range(40, H):
                for x in range(16, 33):
                    put(c, x, y, cor("couro", 2 if x < 24 else 1))
            for y in range(36, 41):
                put(c, 17, y, cor("couro", 1)); put(c, 31, y, cor("couro", 1))
        if "gola_branca" in extras:
            for x in range(18, 31):
                put(c, x, 37, cor("camisa_branca", 3))
        if "tweed" in extras:
            for y in range(38, H, 3):
                for x in range(4, 44, 3):
                    if c[y, x, 3] > 0:
                        put(c, x, y, cor(roupa, 0))
    _sobre(img, _camada(corpo))
    # pescoço e rosto
    def rosto(c):
        for y in range(29, 38):
            for x in range(20, 29):
                put(c, x, y, cor(pele, 1 if y < 32 else 2))
        _elipse(c, 24, 21, 10.5, 12.5, pele, 3, 1.1)
        for ex in (13, 35):   # orelhas
            _elipse(c, ex, 22, 2.2, 3.2, pele, 2, 0.8)
    _sobre(img, _camada(rosto))
    # olhos, sobrancelhas, nariz, boca
    for lx in (18, 28):
        put(img, lx, 21, (250, 250, 250, 255)); put(img, lx + 1, 21, cor(olhos, 1)); put(img, lx + 2, 21, (250, 250, 250, 255))
        put(img, lx + 1, 22, cor(olhos, 0)); put(img, lx, 22, (240, 240, 240, 255)); put(img, lx + 2, 22, (235, 235, 235, 255))
        put(img, lx + 1, 21, cor(olhos, 2))
        for x in range(lx - 1, lx + 4):
            put(img, x, 20, CONT)
        for x in range(lx - 1, lx + 3):
            put(img, x, 17 if x != lx - 1 else 18, cor(br, 0))
    put(img, 24, 24, cor(pele, 1)); put(img, 25, 25, cor(pele, 1)); put(img, 24, 25, cor(pele, 2))
    for x in range(22, 27):
        put(img, x, 28, hexc("#7a3a34"))
    put(img, 21, 27, hexc("#7a3a34")); put(img, 27, 27, hexc("#7a3a34"))
    for (x, y) in ((17, 25), (16, 25), (31, 25), (32, 25)):
        put(img, x, y, (233, 140, 130, 255) if pele != "pele_morena" else (190, 100, 80, 255))
    if "cicatriz" in extras:
        for k in range(6):
            put(img, 30 + k // 2, 22 + k, hexc("#b0605a"))
    if "oculos" in extras:
        for lx in (17, 27):
            for x in range(lx, lx + 5):
                put(img, x, 19, CONT); put(img, x, 23, CONT)
            put(img, lx, 20, CONT); put(img, lx, 21, CONT); put(img, lx, 22, CONT)
            put(img, lx + 4, 20, CONT); put(img, lx + 4, 21, CONT); put(img, lx + 4, 22, CONT)
        put(img, 22, 20, CONT); put(img, 23, 20, CONT); put(img, 24, 20, CONT)
    # barba
    def barba_d(c):
        if not barba:
            return
        for y in range(22, 40 if barba == "longa" else 35):
            for x in range(12, 37):
                nx = (x + 0.5 - 24) / 11.0
                ny = (y + 0.5 - 21) / (13.0 if barba != "longa" else 17.0)
                dentro = nx * nx + ny * ny <= 1
                if barba == "cavanhaque":
                    dentro = abs(x + 0.5 - 24.5) <= 3 and 29 <= y <= 33
                if not dentro or y < 24:
                    continue
                if barba != "cavanhaque" and 20 <= x <= 28 and 26 <= y <= 29:
                    continue   # boca aparece
                if barba != "cavanhaque" and abs(nx) < 0.55 and y < 26:
                    continue
                put(c, x, y, cor(br, 2 if (x + y) % 4 else 1))
        for x in range(21, 28):   # bigode
            put(c, x, 27, cor(br, 1))
    _sobre(img, _camada(barba_d))
    # cabelo de cima
    def topo(c):
        if estilo in ("careca",):
            for x in range(13, 16):
                for y in range(18, 25):
                    put(c, x, y, cor(cabelo, 2))
            for x in range(33, 36):
                for y in range(18, 25):
                    put(c, x, y, cor(cabelo, 2))
            return
        if estilo == "lenco":
            for y in range(7, 17):
                for x in range(12, 37):
                    nx = (x + 0.5 - 24) / 12.5
                    ny = (y + 0.5 - 17) / 10.0
                    if nx * nx + ny * ny <= 1:
                        put(c, x, y, cor(cabelo, 3 if y < 11 else 2))
            for x in range(13, 36):
                put(c, x, 16, cor(cabelo, 1))
            return
        if estilo == "bone":
            for y in range(6, 15):
                for x in range(12, 37):
                    nx = (x + 0.5 - 24) / 12.5
                    ny = (y + 0.5 - 15) / 9.0
                    if nx * nx + ny * ny <= 1:
                        put(c, x, y, cor(roupa, 3 if (x // 3 + y // 3) % 2 else 2))
            for x in range(10, 38):
                put(c, x, 15, cor(roupa, 1)); put(c, x, 16, cor(roupa, 0))
            return
        cach = estilo in ("cacheado", "longo_cacheado")
        for y in range(5, 19):
            for x in range(11, 38):
                nx = (x + 0.5 - 24) / 12.8
                ny = (y + 0.5 - 16) / 11.0
                borda = nx * nx + ny * ny
                if cach:
                    borda += (hash01(x // 3, y // 3, 9) - 0.5) * 0.35
                if borda > 1:
                    continue
                franja = y >= 13 and 15 <= x <= 33 and (x + (y - 13) * 2) % 7 > 2 and not cach
                if y >= 15 and 16 <= x <= 32 and not franja:
                    continue
                i = 3 if y < 9 else 2
                if (x * 3 + y) % 7 == 0:
                    i = 1
                if cach and hash01(x // 2, y // 2, 7) > 0.65:
                    i = 3
                put(c, x, y, cor(cabelo, i))
        for (x0, x1) in ((12, 15), (34, 37)):   # costeletas
            for y in range(16, 24):
                for x in range(x0, x1):
                    put(c, x, y, cor(cabelo, 1))
        if "chifres" in extras:
            for lado in (-1, 1):
                for k in range(4):
                    put(c, 24 + lado * (6 + k // 2), 6 - k, cor("chifre_t", 2 if k < 3 else 3))
                    put(c, 24 + lado * (5 + k // 2), 6 - k, cor("chifre_t", 1))
    _sobre(img, _camada(topo))
    if "brinco" in extras:
        put(img, 12, 26, cor("bronze", 3)); put(img, 12, 27, cor("bronze", 4))
    if "faixa" in extras:   # faixa na cabeça
        for x in range(12, 37):
            put(img, x, 12, cor(roupa, 3)); put(img, x, 13, cor(roupa, 2))
    # moldura
    for x in range(W):
        for y in (0, H - 1):
            img[y, x] = CONT
    for y in range(H):
        for x in (0, W - 1):
            img[y, x] = CONT
    return img


RETRATOS = {
    "annabeth": dict(pele="pele_clara", cabelo="cabelo_loiro", estilo="longo_cacheado", roupa="camisa_laranja", olhos="olho_cinza"),
    "grover": dict(pele="pele_clara", cabelo="cabelo", estilo="cacheado", roupa="camisa_laranja", barba="cavanhaque", extras=("chifres",)),
    "luke": dict(pele="pele_clara", cabelo="cabelo_areia", estilo="curto", roupa="camisa_laranja", olhos="olho_azul", extras=("cicatriz",)),
    "quiron": dict(pele="pele", cabelo="barba_q", estilo="curto", barba="curta", roupa="tweed", extras=("tweed", "gola_branca"), fundo="#d8d0b8"),
    "epicuro": dict(pele="pele", cabelo="cabelo_grisalho", estilo="curto", barba="longa", roupa="tunica_creme", fundo="#e6dcc0"),
    "meneceu": dict(pele="pele", cabelo="cabelo", estilo="cacheado", roupa="tunica_azul", fundo="#e6dcc0"),
    "pitocles": dict(pele="pele_morena", cabelo="cabelo_preto", estilo="curto", barba="curta", roupa="tunica_roxa", fundo="#e6dcc0"),
    "herodoto": dict(pele="pele", cabelo="cabelo_loiro", estilo="curto", roupa="tunica_ocre", olhos="olho_azul", fundo="#e6dcc0"),
    "arkad": dict(pele="pele_morena", cabelo="cabelo_grisalho", estilo="curto", barba="longa", roupa="tunica_roxa", extras=("faixa",), fundo="#ead9b0"),
    "mathon": dict(pele="pele_morena", cabelo="cabelo_preto", estilo="curto", barba="curta", roupa="camisa_vinho", extras=("brinco",), fundo="#ead9b0"),
    "simon": dict(pele="pele", cabelo="cabelo", estilo="careca", barba="curta", roupa="camisa_vinho", extras=("avental",), fundo="#d9d4e6"),
    "matryona": dict(pele="pele_clara", cabelo="coracao", estilo="lenco", roupa="tunica_azul", olhos="olho_azul", fundo="#d9d4e6"),
    "michael": dict(pele="pele_clara", cabelo="cabelo_loiro", estilo="curto", roupa="camisa_branca", olhos="olho_azul", fundo="#e8eef6"),
    "thoreau": dict(pele="pele", cabelo="cabelo", estilo="curto", barba="curta", roupa="tunica_ocre", fundo="#cfe3b8"),
    "lenhador": dict(pele="pele_morena", cabelo="cabelo_preto", estilo="curto", barba="curta", roupa="camisa_vinho", fundo="#cfe3b8"),
    "ferreiro": dict(pele="pele", cabelo="cabelo_grisalho", estilo="curto", roupa="camisa_vinho", extras=("avental",), fundo="#e3cfc0"),
    "jornaleiro": dict(pele="pele", cabelo="cabelo_preto", estilo="bone", roupa="camisa_xadrez", extras=("oculos",), fundo="#e3dcc8"),
    "vendedora": dict(pele="pele_clara", cabelo="cabelo_loiro", estilo="longo", roupa="camisa_verde", olhos="olho_verde", fundo="#e3dcc8"),
    "enfermeira": dict(pele="pele_morena", cabelo="cabelo_preto", estilo="longo", roupa="camisa_branca", fundo="#e8eef6"),
}


def gerar(caminho):
    for nome, ficha in RETRATOS.items():
        salvar(retrato(**ficha), caminho("retratos", nome + ".png"))
