"""Gera os sons e a música do Leaf & Lore por código (D-039, tecnico.md §7).

Uso: python3 ferramentas/som/gerar_sons.py
Saída: game/assets/sons/*.wav (22050 Hz, 16 bits, mono); a música vira .ogg (precisa do ffmpeg).
Estilo: sons curtos e macios; música em estilo de console portátil (ondas quadradas e
triangulares), composição própria.
"""
import os
import wave
import numpy as np

TAXA = 22050
SAIDA = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "sons")
rng = np.random.default_rng(7)


def t_(seg):
    return np.arange(int(round(TAXA * seg))) / TAXA


def env(n, ataque=0.005, queda=None, sustentar=1.0, soltar=0.03):
    """Envelope simples: subida, (queda até 'sustentar'), descida no fim."""
    e = np.ones(n)
    a = max(1, int(ataque * TAXA))
    e[:a] = np.linspace(0, 1, a)
    if queda:
        q = int(queda * TAXA)
        fim = min(n, a + q)
        e[a:fim] = np.linspace(1, sustentar, fim - a)
        e[fim:] = sustentar
    s = max(1, int(soltar * TAXA))
    if s < n:
        e[-s:] *= np.linspace(1, 0, s)
    return e


def passa_baixa(x, corte):
    """Filtro de um polo (suaviza o chiado)."""
    a = np.exp(-2 * np.pi * corte / TAXA)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def quadrada(f, seg, duty=0.25):
    fase = (t_(seg) * f) % 1.0
    return np.where(fase < duty, 1.0, -1.0)


def triangular(f, seg):
    fase = (t_(seg) * f) % 1.0
    return 4 * np.abs(fase - 0.5) - 1


def seno(f, seg):
    if callable(f):
        fs = f(t_(seg))
        return np.sin(2 * np.pi * np.cumsum(fs) / TAXA)
    return np.sin(2 * np.pi * f * t_(seg))


def ruido(seg):
    return rng.uniform(-1, 1, int(round(TAXA * seg)))


def salvar(nome, x, volume=0.8):
    x = np.asarray(x, dtype=float)
    pico = np.max(np.abs(x)) or 1.0
    x = x / pico * volume
    dados = (np.clip(x, -1, 1) * 32767).astype("<i2")
    os.makedirs(SAIDA, exist_ok=True)
    with wave.open(os.path.join(SAIDA, nome + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(TAXA)
        w.writeframes(dados.tobytes())


def para_ogg(nome):
    """Converte a música para OGG Vorbis (bem menor que WAV) com o ffmpeg, se houver; apaga o WAV."""
    import shutil
    import subprocess
    if not shutil.which("ffmpeg"):
        return
    wav = os.path.join(SAIDA, nome + ".wav")
    ogg = os.path.join(SAIDA, nome + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", ogg], check=True)
    os.remove(wav)


# ============================== EFEITOS ==============================

def passo(semente):
    global rng
    rng = np.random.default_rng(semente)
    x = passa_baixa(ruido(0.07), 900 + semente * 150)
    e = np.exp(-t_(0.07) * 60)
    return x * e


def mato():
    """Farfalhar curto de folhas (passar pelo mato)."""
    global rng
    rng = np.random.default_rng(41)
    n = ruido(0.18)
    alto = n - passa_baixa(n, 1800)          # só o chiado agudo
    e = np.exp(-((t_(0.18) - 0.05) / 0.045) ** 2)
    return passa_baixa(alto, 7000) * e


def machado():
    """Golpe seco do machado na madeira: estalo + 'toc' grave."""
    global rng
    rng = np.random.default_rng(43)
    n = ruido(0.14)
    x = passa_baixa(n, 2500) * np.exp(-t_(0.14) * 45) * 0.9
    x += seno(lambda t: 190 - 80 * t / 0.14, 0.14) * np.exp(-t_(0.14) * 30) * 1.0
    x += seno(380, 0.14) * np.exp(-t_(0.14) * 60) * 0.35
    return x


def tombar():
    """Árvore caindo: rangido que desce e a batida no chão com folhas."""
    global rng
    rng = np.random.default_rng(47)
    d = 0.9
    t = t_(d)
    range_ = seno(lambda tt: 120 + 60 * np.sin(tt * 30) - 60 * tt, d) * 0.25 * (t < 0.55)
    batida = np.zeros_like(t)
    i0 = int(0.55 * TAXA)
    m = len(t) - i0
    tb = t_(m / TAXA)
    batida[i0:] = (passa_baixa(ruido(m / TAXA), 500) * 1.4 + seno(60, m / TAXA) * 0.9) * np.exp(-tb * 9)
    folhas = ruido(d) - passa_baixa(ruido(d), 2000)
    folhas = folhas * 0.25 * np.exp(-((t - 0.65) / 0.15) ** 2)
    return range_ + batida + folhas


def espada():
    """Corte no ar: chiado que sobe e some."""
    global rng
    rng = np.random.default_rng(53)
    d = 0.18
    n = ruido(d)
    alto = n - passa_baixa(n, 2500)
    e = np.sin(np.pi * np.clip(t_(d) / d, 0, 1)) ** 2
    return alto * e + seno(lambda t: 900 + 1400 * t / d, d) * e * 0.08


def dano():
    """Levou um golpe: 'tum' curto e grave com um apito descendo."""
    global rng
    rng = np.random.default_rng(59)
    d = 0.22
    x = seno(lambda t: 320 - 600 * t, d) * np.exp(-t_(d) * 18) * 0.8
    x += passa_baixa(ruido(d), 900) * np.exp(-t_(d) * 30) * 0.6
    return x


def trovao():
    """Trovão longe: estrondo grave que rola e se apaga."""
    global rng
    rng = np.random.default_rng(61)
    d = 2.6
    t = t_(d)
    x = passa_baixa(ruido(d), 160) * 2.2
    x *= (np.exp(-t * 1.6) * (0.6 + 0.4 * np.sin(t * 9) ** 2)) * np.clip(t / 0.08, 0, 1)
    x += passa_baixa(ruido(d), 600) * np.exp(-t * 6) * 0.5 * (t < 0.6)
    return x


def chuva():
    """Chuva contínua (3 s, toca em laço): chiado médio com pingos."""
    global rng
    rng = np.random.default_rng(67)
    d = 3.0
    n = ruido(d)
    x = passa_baixa(n, 5000) - passa_baixa(n, 400)
    pingos = np.zeros_like(x)
    for i in rng.integers(0, len(x) - 400, 260):
        pingos[i:i + 300] += np.exp(-np.arange(300) / 40.0) * rng.uniform(-1, 1) * 0.6
    x = x * 0.5 + pingos
    # emenda suave para o laço
    k = 600
    x[:k] = x[:k] * np.linspace(0, 1, k) + x[-k:] * np.linspace(1, 0, k)
    return x[:-k]


def enxada():
    n = ruido(0.16)
    x = passa_baixa(n, 700) * np.exp(-t_(0.16) * 28) * 1.3
    x += seno(lambda t: 110 - 50 * t / 0.16, 0.16) * np.exp(-t_(0.16) * 22) * 0.8
    x[:60] += rng.uniform(-1, 1, 60) * 0.6  # estalo da lâmina na terra
    return x


def regar():
    seg = 0.5
    n = passa_baixa(ruido(seg), 2500) - passa_baixa(ruido(seg), 300) * 0.5
    bolhas = 0.6 + 0.4 * np.sin(2 * np.pi * 23 * t_(seg)) * rng.uniform(0.5, 1, len(n))
    return n * bolhas * env(len(n), 0.04, soltar=0.15)


def encher():
    seg = 0.55
    x = passa_baixa(ruido(seg), 1800) * np.exp(-t_(seg) * 7) * 0.8
    for k, ini in enumerate((0.05, 0.14, 0.22, 0.33)):
        d = 0.07
        b = seno(lambda t, k=k: 500 + 120 * k + 900 * t / d, d) * env(int(round(d * TAXA)), 0.003, soltar=0.03) * 0.5
        i = int(ini * TAXA)
        x[i:i + len(b)] += b
    return x


def plantar():
    d = 0.09
    x = seno(lambda t: 260 + 2600 * t, d) * env(int(round(d * TAXA)), 0.002, soltar=0.05)
    x += passa_baixa(ruido(d), 600) * np.exp(-t_(d) * 40) * 0.5
    return x


def colher():
    partes = []
    for f, d in ((784, 0.06), (1175, 0.11)):
        partes.append(quadrada(f, d, 0.25) * env(int(round(d * TAXA)), 0.002, soltar=0.04))
    return passa_baixa(np.concatenate(partes), 5000)


def comer():
    partes = []
    for k in range(3):
        d = 0.05
        partes.append(passa_baixa(ruido(d), 1500 + k * 300) * np.exp(-t_(d) * 50))
        partes.append(np.zeros(int(0.06 * TAXA)))
    return np.concatenate(partes)


def clique():
    d = 0.03
    return quadrada(880, d, 0.5) * env(int(round(d * TAXA)), 0.001, soltar=0.02) * 0.6


def selecionar():
    d = 0.025
    return passa_baixa(quadrada(1320, d, 0.25), 6000) * env(int(round(d * TAXA)), 0.001, soltar=0.015) * 0.5


def nota_hz(n):
    nomes = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
             "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}
    nome, oit = n[:-1], int(n[-1])
    m = nomes[nome] + 12 * (oit + 1)
    return 440.0 * 2 ** ((m - 69) / 12)


def arpejo(notas, d=0.09, onda="tri"):
    partes = []
    for n in notas:
        f = nota_hz(n)
        w = triangular(f, d) if onda == "tri" else quadrada(f, d, 0.125)
        partes.append(w * env(int(round(d * TAXA)), 0.003, queda=d * 0.6, sustentar=0.4, soltar=0.03))
    x = np.concatenate(partes)
    return np.concatenate([x, np.zeros(int(0.25 * TAXA))])


def eco(x, atraso=0.12, ganho=0.35, vezes=3):
    a = int(atraso * TAXA)
    y = np.concatenate([x, np.zeros(a * vezes)])
    for k in range(1, vezes + 1):
        y[a * k:a * k + len(x)] += x * ganho ** k
    return y


def dormir():
    return eco(arpejo(["G5", "E5", "C5", "G4"], 0.16))


def salvar_jogo():
    return eco(arpejo(["C5", "E5", "G5", "C6"], 0.07, "quad"), 0.09, 0.3)


# ============================== MÚSICA ==============================
# Tema da fazenda: Fá maior, 96 batidas por minuto, 4/4. Composição própria.
BPM = 96
OITAVA = 60.0 / BPM / 2  # duração de uma colcheia

ACORDES = {
    "F": ["F", "A", "C"], "Am": ["A", "C", "E"], "Bb": ["Bb", "D", "F"], "C": ["C", "E", "G"],
    "Dm": ["D", "F", "A"], "Gm": ["G", "Bb", "D"], "C7": ["C", "E", "Bb"],
}
PARTE_A = [
    ("F", [("A4", 2), ("C5", 2), ("A4", 1), ("G4", 1), ("F4", 2)]),
    ("Am", [("E4", 2), ("A4", 2), ("C5", 2), ("E5", 2)]),
    ("Bb", [("D5", 3), ("C5", 1), ("Bb4", 2), ("A4", 2)]),
    ("C", [("G4", 4), ("E4", 2), ("G4", 2)]),
    ("F", [("A4", 2), ("C5", 2), ("F5", 3), ("E5", 1)]),
    ("Am", [("E5", 2), ("C5", 2), ("A4", 2), ("C5", 2)]),
    ("Bb", [("Bb4", 2), ("D5", 2), ("C5", 2), ("Bb4", 2)]),
    ("C7", [("A4", 2), ("G4", 2), ("E4", 2), ("G4", 2)]),
]
PARTE_B = [
    ("Dm", [("F5", 3), ("E5", 1), ("D5", 2), ("A4", 2)]),
    ("Am", [("C5", 3), ("A4", 1), ("E4", 2), ("A4", 2)]),
    ("Bb", [("D5", 2), ("F5", 2), ("D5", 2), ("Bb4", 2)]),
    ("F", [("C5", 4), ("A4", 2), ("F4", 2)]),
    ("Gm", [("Bb4", 2), ("D5", 2), ("G5", 3), ("F5", 1)]),
    ("C", [("E5", 2), ("C5", 2), ("G4", 2), ("Bb4", 2)]),
    ("F", [("A4", 3), ("G4", 1), ("F4", 2), ("A4", 2)]),
    ("C7", [("G4", 2), ("A4", 2), ("Bb4", 2), ("C5", 2)]),
]


def _nota(onda, f, d, vol, ataque=0.008, queda=0.12, sustentar=0.55, soltar=0.05, vibrato=0.0):
    n = int(round(d * TAXA))
    t = np.arange(n) / TAXA
    if vibrato:
        fase = np.cumsum(f * (1 + vibrato * np.sin(2 * np.pi * 5.5 * t) * np.clip(t / 0.25, 0, 1))) / TAXA
    else:
        fase = f * t
    fase = fase % 1.0
    if onda == "quad":
        w = np.where(fase < 0.125, 1.0, -1.0) * 0.6 + np.where(fase < 0.25, 1.0, -1.0) * 0.4
    elif onda == "quad50":
        w = np.where(fase < 0.5, 1.0, -1.0)
    else:
        w = 4 * np.abs(fase - 0.5) - 1
    return w * env(n, ataque, queda, sustentar, soltar) * vol


def musica_fazenda():
    compassos = PARTE_A + PARTE_B + PARTE_A + PARTE_B
    total = len(compassos) * 8 * OITAVA
    x = np.zeros(int(total * TAXA) + TAXA)
    def somar(sinal, ini):
        i = int(ini * TAXA)
        x[i:i + len(sinal)] += sinal
    for c, (acorde, mel) in enumerate(compassos):
        ini = c * 8 * OITAVA
        notas = ACORDES[acorde]
        raiz = notas[0]
        # melodia (na repetição, uma oitava acima em parte das notas)
        p = ini
        for k, (n, d) in enumerate(mel):
            f = nota_hz(n) * (2 if c >= 16 and c % 8 in (4, 5) else 1)
            somar(_nota("quad", f, d * OITAVA * 0.95, 0.22, vibrato=0.006), p)
            p += d * OITAVA
        # baixo: tônica e quinta, uma por semínima
        quinta = notas[2] if acorde not in ("C7",) else "G"
        for b, nn in enumerate([raiz, quinta, raiz, quinta]):
            o = 2 if nn in ("C", "D", "E", "F", "G") else 2
            somar(_nota("tri", nota_hz(nn + str(o + 1)), OITAVA * 1.8, 0.35, queda=0.2, sustentar=0.7), ini + b * 2 * OITAVA)
        # arpejo baixinho em colcheias
        seq = [notas[0], notas[1], notas[2], notas[1]] * 2
        for k, nn in enumerate(seq):
            somar(_nota("quad50", nota_hz(nn + "4"), OITAVA * 0.7, 0.05, queda=0.05, sustentar=0.3), ini + k * OITAVA)
        # percussão: chimbal de leve no contratempo, bumbo macio no 1 e no 3
        for k in range(8):
            if k % 2 == 1:
                h = passa_baixa(ruido(0.04), 7000) - passa_baixa(ruido(0.04), 3000)
                somar(h * np.exp(-t_(0.04) * 90) * 0.08, ini + k * OITAVA)
            if k in (0, 4):
                somar(seno(lambda t: 120 - 60 * t / 0.12, 0.12) * np.exp(-t_(0.12) * 30) * 0.25, ini + k * OITAVA)
    x = x[:int(total * TAXA)]
    # sem estalo no ponto da volta
    x[:200] *= np.linspace(0, 1, 200)
    x[-200:] *= np.linspace(1, 0, 200)
    return passa_baixa(x, 6000)


if __name__ == "__main__":
    salvar("passo_0", passo(1), 0.5)
    salvar("passo_1", passo(2), 0.5)
    salvar("enxada", enxada(), 0.8)
    salvar("regar", regar(), 0.55)
    salvar("encher", encher(), 0.6)
    salvar("plantar", plantar(), 0.6)
    salvar("colher", colher(), 0.5)
    salvar("comer", comer(), 0.6)
    salvar("clique", clique(), 0.4)
    salvar("selecionar", selecionar(), 0.35)
    salvar("dormir", dormir(), 0.5)
    salvar("salvar", salvar_jogo(), 0.45)
    salvar("musica_fazenda", musica_fazenda(), 0.7)
    para_ogg("musica_fazenda")
    salvar("mato", mato(), 0.35)
    salvar("machado", machado(), 0.7)
    salvar("tombar", tombar(), 0.7)
    salvar("espada", espada(), 0.5)
    salvar("dano", dano(), 0.7)
    salvar("trovao", trovao(), 0.8)
    salvar("chuva", chuva(), 0.6)
    print("ok")
