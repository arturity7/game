"""Divide cada /home/claude/textos/<slug>.txt em partes de ~9000 palavras em /home/claude/textos/chunks/<slug>/NN.txt.
Uso: python3 -I ferramentas/dividir.py [slug ...]   (sem argumentos = todos)"""
import os, sys
BASE = "/home/claude/textos"
def dividir(t, alvo=9000):
    linhas = t.split("\n"); partes = []; atual = []; n = 0
    for l in linhas:
        atual.append(l); n += len(l.split())
        if n >= alvo:
            partes.append("\n".join(atual)); atual = []; n = 0
    if atual: partes.append("\n".join(atual))
    return partes
slugs = sys.argv[1:] or [f[:-4] for f in os.listdir(BASE) if f.endswith(".txt")]
for s in slugs:
    ps = dividir(open(f"{BASE}/{s}.txt").read())
    d = f"{BASE}/chunks/{s}"; os.makedirs(d, exist_ok=True)
    for i, p in enumerate(ps, 1):
        open(f"{d}/{i:02d}.txt", "w").write(p)
    print(s, len(ps), "partes")
