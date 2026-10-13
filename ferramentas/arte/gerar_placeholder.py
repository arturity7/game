"""Gera a arte provisória do protótipo (tiles 16x16 e jogador 16x32).

Uso: python3 ferramentas/arte/gerar_placeholder.py
Saída: game/assets/sprites/placeholder/
Tudo é desenhado pixel a pixel com a paleta abaixo (tecnico.md §7).
"""
import os, random
from PIL import Image

PALETA = {
    "grama": (106, 168, 79), "grama_esc": (78, 133, 61), "grama_clara": (147, 196, 105),
    "terra": (153, 102, 61), "terra_esc": (115, 74, 44), "terra_clara": (181, 132, 86),
    "agua": (64, 128, 196), "agua_esc": (44, 96, 156), "agua_clara": (128, 180, 230),
    "madeira": (140, 92, 52), "madeira_esc": (96, 60, 33),
    "folha": (52, 110, 58), "folha_esc": (34, 78, 40), "tronco": (110, 72, 40),
    "telhado": (176, 64, 56), "telhado_esc": (128, 44, 40), "parede": (222, 196, 150), "porta": (96, 60, 33),
    "caminho": (196, 170, 120), "caminho_esc": (166, 142, 98),
    "pele": (236, 188, 150), "cabelo": (92, 58, 36), "camisa": (60, 110, 170), "calca": (66, 66, 90),
    "contorno": (40, 32, 36),
    "metal": (170, 176, 186), "metal_esc": (110, 116, 128), "verde_broto": (120, 190, 80),
    "feijao": (150, 70, 60), "cenoura": (236, 128, 40), "batata": (196, 156, 96), "milho": (240, 210, 70),
    "papel": (226, 214, 180), "papel_esc": (180, 160, 120),
}
CULTURAS = ["feijao", "cenoura", "batata", "milho"]  # ordem = linha no atlas (content/config/culturas.json)
SAIDA = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "sprites", "placeholder")

def ruido(img, x0, base, pontos, seed):
    rnd = random.Random(seed)
    for y in range(16):
        for x in range(16):
            img.putpixel((x0 + x, y), PALETA[base])
    for cor, n in pontos:
        for _ in range(n):
            img.putpixel((x0 + rnd.randrange(16), rnd.randrange(16)), PALETA[cor])

def tiles():
    # ordem = índice no atlas (content/config/tiles.json)
    nomes = ["grama", "terra", "agua", "cerca", "arvore", "casa", "caminho"]
    img = Image.new("RGBA", (16 * len(nomes), 16), (0, 0, 0, 0))
    ruido(img, 0, "grama", [("grama_esc", 22), ("grama_clara", 12)], 1)
    ruido(img, 16, "terra", [("terra_esc", 20), ("terra_clara", 10)], 2)
    ruido(img, 32, "agua", [("agua_esc", 14)], 3)
    for x in range(3, 13):  # brilho da água
        img.putpixel((32 + x, 5), PALETA["agua_clara"])
        if x % 2:
            img.putpixel((32 + x - 1, 11), PALETA["agua_clara"])
    ruido(img, 48, "grama", [("grama_esc", 18)], 4)  # cerca sobre grama
    for y in range(3, 15):
        for x in (2, 3, 12, 13):
            img.putpixel((48 + x, y), PALETA["madeira"])
    for x in range(16):
        for y in (6, 7, 11, 12):
            img.putpixel((48 + x, y), PALETA["madeira_esc"] if y in (7, 12) else PALETA["madeira"])
    ruido(img, 64, "grama", [("grama_esc", 18)], 5)  # árvore
    for y in range(10, 16):
        for x in range(6, 10):
            img.putpixel((64 + x, y), PALETA["tronco"])
    for y in range(0, 11):
        for x in range(1, 15):
            if (x - 7.5) ** 2 / 49 + (y - 5) ** 2 / 30 <= 1:
                img.putpixel((64 + x, y), PALETA["folha_esc"] if (x + y) % 5 == 0 else PALETA["folha"])
    for y in range(16):  # casa (bloco de parede com telhado)
        for x in range(16):
            cor = "telhado" if y < 6 else "parede"
            if y < 6 and (x + y) % 4 == 0:
                cor = "telhado_esc"
            if y >= 9 and 6 <= x <= 9:
                cor = "porta"
            img.putpixel((80 + x, y), PALETA[cor])
    ruido(img, 96, "caminho", [("caminho_esc", 16)], 7)
    img.save(os.path.join(SAIDA, "tiles.png"))

def jogador():
    # 4 quadros 16x32: baixo, cima, esquerda, direita
    img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    for q in range(4):
        x0 = q * 16
        def p(x, y, c):
            img.putpixel((x0 + x, y), PALETA[c])
        for y in range(8, 18):  # cabeça
            for x in range(4, 12):
                p(x, y, "pele")
        for y in range(6, 11):
            for x in range(4, 12):
                if q == 1 or y < 9 or x in (4, 11):
                    p(x, y, "cabelo")
        if q == 0:
            p(6, 13, "contorno"); p(9, 13, "contorno")
        elif q == 2:
            p(5, 13, "contorno")
        elif q == 3:
            p(10, 13, "contorno")
        for y in range(18, 26):  # corpo
            for x in range(3, 13):
                p(x, y, "camisa")
        for y in range(26, 31):  # pernas
            for x in (5, 6, 9, 10):
                p(x, y, "calca")
        for x in (5, 6, 9, 10):
            p(x, 31, "contorno")
    img.save(os.path.join(SAIDA, "jogador.png"))

def plantacao():
    """Linha 0: solo arado seco e molhado. Linhas 1+: uma cultura por linha, 4 estágios."""
    img = Image.new("RGBA", (64, 16 * (1 + len(CULTURAS))), (0, 0, 0, 0))
    for i, (base, esc) in enumerate([("terra", "terra_esc"), ("terra_esc", "contorno")]):
        for y in range(16):
            for x in range(16):
                cor = PALETA[base]
                if y % 4 == 1 and 2 <= x <= 13:
                    cor = PALETA[esc]
                img.putpixel((i * 16 + x, y), cor)
    for linha, c in enumerate(CULTURAS, start=1):
        y0 = linha * 16
        for est in range(4):
            x0 = est * 16
            altura = [2, 5, 9, 12][est]
            for y in range(16 - altura, 15):
                img.putpixel((x0 + 7, y0 + y), PALETA["folha"])
                img.putpixel((x0 + 8, y0 + y), PALETA["folha_esc"])
            if est >= 1:
                for dx in (-2, -1, 2, 3):
                    img.putpixel((x0 + 7 + dx, y0 + 15 - altura + 2), PALETA["verde_broto"])
            if est >= 2:
                for dx in (-3, -2, 3, 4):
                    img.putpixel((x0 + 7 + dx, y0 + 15 - altura // 2), PALETA["folha"])
            if est == 3:  # pronto: o fruto aparece
                for dy in range(3):
                    for dx in range(3):
                        img.putpixel((x0 + 6 + dx, y0 + 15 - altura - 1 + dy), PALETA[c])
    img.save(os.path.join(SAIDA, "plantacao.png"))

def itens():
    """Ícones 16x16: enxada, regador, depois semente e produto de cada cultura."""
    n = 2 + 2 * len(CULTURAS)
    img = Image.new("RGBA", (16 * n, 16), (0, 0, 0, 0))
    def p(i, x, y, c):
        img.putpixel((i * 16 + x, y), PALETA[c])
    for k in range(10):  # enxada: cabo na diagonal
        p(0, 3 + k, 13 - k, "madeira")
    for x in range(10, 15):
        p(0, x, 2, "metal"); p(0, x, 3, "metal_esc")
    for y in range(6, 14):  # regador
        for x in range(3, 11):
            p(1, x, y, "metal" if y > 6 else "metal_esc")
    for k in range(5):
        p(1, 11 + k // 2, 8 - k, "metal_esc")
    for y in range(4, 7):
        p(1, 6, y, "metal_esc")
    for i, c in enumerate(CULTURAS):
        s = 2 + 2 * i
        for y in range(3, 14):  # pacote de sementes
            for x in range(4, 12):
                p(s, x, y, "papel" if y > 4 else "papel_esc")
        for y in range(7, 11):
            for x in range(6, 10):
                p(s, x, y, c)
        for y in range(5, 13):  # produto
            for x in range(4, 12):
                if (x - 7.5) ** 2 / 16 + (y - 9) ** 2 / 16 <= 1:
                    p(s + 1, x, y, c)
        p(s + 1, 7, 4, "folha"); p(s + 1, 8, 3, "folha")
    img.save(os.path.join(SAIDA, "itens.png"))

if __name__ == "__main__":
    os.makedirs(SAIDA, exist_ok=True)
    tiles()
    jogador()
    plantacao()
    itens()
    print("ok")
