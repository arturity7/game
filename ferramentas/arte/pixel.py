"""Biblioteca de pixel art do Leaf & Lore: paleta, contorno, ruído e terrenos com bordas suaves.

Toda a arte do jogo é desenhada por código com estas funções (tecnico.md §7).
A paleta é própria do projeto; nada é copiado de outro jogo.
"""
import math
import random
import numpy as np
from PIL import Image

# ---------- paleta (rampas do escuro ao claro) ----------
def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

RAMPAS = {
    "grama":    ["#2f5b2a", "#3e7530", "#4f8f36", "#63a63d", "#7fbd4a", "#a2d465"],
    "terra":    ["#4a2f1f", "#61402a", "#7a5235", "#936641", "#ad7d52", "#c79766"],
    "arado":    ["#3b2416", "#4e311f", "#61402a", "#755034", "#8a6040"],
    "molhado":  ["#24160e", "#311f14", "#3f291b", "#4f3424", "#5f402e"],
    "caminho":  ["#6e5a43", "#88714f", "#a38a62", "#bca37a", "#d3bd93", "#e6d4ad"],
    "agua":     ["#173d63", "#1f5383", "#2a6ca3", "#3a88bf", "#5aa7d6", "#8fcbea", "#d4f0fb"],
    "madeira":  ["#3a2214", "#552f1a", "#734225", "#915733", "#ad7044", "#c98c58", "#e0ab76"],
    "telhado":  ["#3d1518", "#5c2023", "#7d2d2c", "#9e3c35", "#bb5240", "#d46f4f"],
    "pedra":    ["#3a3a42", "#4f505a", "#686a74", "#83868f", "#a3a6ad", "#c4c6ca"],
    "folha":    ["#1b3520", "#24492a", "#2f5f31", "#3e7838", "#529242", "#6dab4f", "#8fc45e"],
    "tronco":   ["#2c1a10", "#432818", "#5c3722", "#784a2e", "#93603c"],
    "pele":     ["#7a4430", "#a5603f", "#cf855a", "#eaa97c", "#f6cba0"],
    "cabelo":   ["#2b1810", "#432616", "#5e3720", "#7b4b2b", "#9a6438"],
    "camisa":   ["#1c3d45", "#255563", "#2f6e7e", "#3f8c9b", "#5aa9b5"],
    "calca":    ["#1f2338", "#2b3150", "#3a4369", "#4e5a85"],
    "sapato":   ["#2a1a12", "#3f281b", "#56382a"],
    "vidro":    ["#24435a", "#35607c", "#4f84a2", "#86b8d0", "#cbe7f2"],
    "flor_am":  ["#c48a1c", "#e8b934", "#f6dd6a"],
    "flor_rs":  ["#a83a5a", "#d8607e", "#f29bb0"],
    "flor_br":  ["#b8b8c8", "#e6e6ee", "#ffffff"],
    "flor_li":  ["#5e4a9e", "#8a72d0", "#b8a6ef"],
    "cenoura":  ["#9a4512", "#d0661c", "#f08b33", "#f9b064"],
    "milho":    ["#9a7a16", "#d2ad2a", "#efd24d", "#f9e98a"],
    "batata":   ["#6e4e2c", "#946c41", "#b88d5a", "#d6ae7a"],
    "feijao":   ["#5a1e1e", "#7f2c2a", "#a33f37", "#c45b4b"],
    "metal":    ["#3d4048", "#5b6070", "#7f8596", "#a8aebb", "#d2d6de"],
    "papel":    ["#8f7a52", "#b9a374", "#d8c697", "#efe3bd"],
    "ui_mad":   ["#2a170d", "#4a2a16", "#6e4022", "#94592f", "#b9773f", "#d99a58", "#f0c27f"],
    "coracao":  ["#6e1620", "#a8222f", "#d6383f", "#f07a74"],
}
CONTORNO = hexc("#21140d")
TRANSP = (0, 0, 0, 0)

def cor(rampa, i, a=255):
    r = RAMPAS[rampa]
    i = max(0, min(len(r) - 1, i))
    return hexc(r[i], a)

# ---------- ruído determinístico ----------
def hash01(*v):
    h = 2166136261
    for x in v:
        h = ((h ^ (int(x) & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
    h ^= h >> 13
    h = (h * 1274126177) & 0xFFFFFFFF
    return (h & 0xFFFFFF) / float(0x1000000)

def valor_suave(x, y, escala, semente=0):
    """Ruído de valor interpolado (0..1), periódico em 16 px para casar tiles vizinhos."""
    gx, gy = x / escala, y / escala
    x0, y0 = int(math.floor(gx)), int(math.floor(gy))
    fx, fy = gx - x0, gy - y0
    per = max(1, int(round(16 / escala)))
    def g(a, b):
        return hash01(a % per, b % per, semente)
    sx = fx * fx * (3 - 2 * fx)
    sy = fy * fy * (3 - 2 * fy)
    top = g(x0, y0) * (1 - sx) + g(x0 + 1, y0) * sx
    bot = g(x0, y0 + 1) * (1 - sx) + g(x0 + 1, y0 + 1) * sx
    return top * (1 - sy) + bot * sy

# ---------- imagem como matriz ----------
def nova(w, h):
    return np.zeros((h, w, 4), dtype=np.uint8)

def put(img, x, y, c):
    h, w = img.shape[:2]
    if 0 <= x < w and 0 <= y < h:
        if len(c) == 4 and c[3] < 255 and img[y, x, 3] > 0:
            a = c[3] / 255.0
            base = img[y, x].astype(float)
            img[y, x, :3] = (base[:3] * (1 - a) + np.array(c[:3]) * a).astype(np.uint8)
            img[y, x, 3] = max(img[y, x, 3], c[3])
        else:
            img[y, x] = c

def get(img, x, y):
    h, w = img.shape[:2]
    if 0 <= x < w and 0 <= y < h:
        return tuple(img[y, x])
    return TRANSP

def contornar(img, c=CONTORNO, diagonais=False):
    """Põe contorno de 1 px em volta de tudo que é opaco."""
    h, w = img.shape[:2]
    alfa = img[:, :, 3] > 0
    viz = np.zeros_like(alfa)
    viz[1:, :] |= alfa[:-1, :]
    viz[:-1, :] |= alfa[1:, :]
    viz[:, 1:] |= alfa[:, :-1]
    viz[:, :-1] |= alfa[:, 1:]
    if diagonais:
        viz[1:, 1:] |= alfa[:-1, :-1]
        viz[:-1, :-1] |= alfa[1:, 1:]
        viz[1:, :-1] |= alfa[:-1, 1:]
        viz[:-1, 1:] |= alfa[1:, :-1]
    borda = viz & ~alfa
    img[borda] = c
    return img

def elipse(img, cx, cy, rx, ry, c):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                put(img, x, y, c)

def retangulo(img, x0, y0, x1, y1, c):
    for y in range(y0, y1):
        for x in range(x0, x1):
            put(img, x, y, c)

def salvar(img, caminho):
    Image.fromarray(img, "RGBA").save(caminho)

def colar(dest, src, ox, oy):
    h, w = src.shape[:2]
    for y in range(h):
        for x in range(w):
            if src[y, x, 3] > 0:
                put(dest, ox + x, oy + y, tuple(src[y, x]))

# ---------- terreno em grade dupla ("dual grid") ----------
# Cada tile de exibição fica deslocado meio tile e olha as 4 células do mundo nos seus cantos.
# Máscara: TL=1, TR=2, BL=4, BR=8 (a mesma usada em game/scripts/world/mundo.gd).
CANTOS = [(0, 0, 1), (16, 0, 2), (0, 16, 4), (16, 16, 8)]

def _smin(a, b, k):
    h = max(k - abs(a - b), 0.0) / k
    return min(a, b) - h * h * k * 0.25

def sdf_dual(mascara, x, y, raio=8.0, p=4.0, suavizar=4.0, ruido=0.0, semente=0):
    """Distância com sinal da forma (negativo = dentro) no pixel (x, y) do tile de exibição."""
    px, py = x + 0.5, y + 0.5
    d = 99.0
    for cx, cy, bit in CANTOS:
        if mascara & bit:
            dx, dy = abs(px - cx), abs(py - cy)
            di = (dx ** p + dy ** p) ** (1.0 / p) - raio
            d = di if d == 99.0 else _smin(d, di, suavizar)
    if ruido:
        wx, wy = (x + 8) % 16, (y + 8) % 16
        d += (valor_suave(wx, wy, 4, semente) - 0.5) * 2 * ruido
    return d

def tiles_dual(pintar, n_quadros=1, **kw):
    """Gera o atlas 16 máscaras (colunas) × n_quadros (linhas).
    pintar(img, x, y, sdf, wx, wy, quadro, mascara) desenha um pixel."""
    atlas = nova(16 * 16, 16 * n_quadros)
    for q in range(n_quadros):
        for m in range(16):
            tile = nova(16, 16)
            if m:
                for y in range(16):
                    for x in range(16):
                        s = sdf_dual(m, x, y, **kw)
                        pintar(tile, x, y, s, (x + 8) % 16, (y + 8) % 16, q, m)
            atlas[q * 16:(q + 1) * 16, m * 16:(m + 1) * 16] = tile
    return atlas
