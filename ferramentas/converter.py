"""Converte os livros enviados (epub, fb2, azw3, pdf) para texto puro em /home/claude/textos."""
import os, re, subprocess, shutil, sys
import mobi

UP = "/root/.claude/uploads/e32ca5e3-553f-5dba-b98e-9ebf1c0541b0"
OUT = "/home/claude/textos"
os.makedirs(OUT, exist_ok=True)

MAPA = {
    "04e211d9": "seja-util",
    "0a5b338e": "reacher-acerto-de-contas",
    "17963747": "carta-a-meneceu",
    "2378e674": "walden",
    "2dfec4e3": "cartas-de-um-diabo",
    "2ef2b26b": "dunkirk",
    "3c0029fe": "goggins-nunca-e-hora-de-parar",
    "4b0acbe9": "rickson-conforto-na-escuridao",
    "5a934617": "reacher-make-me",
    "62f34cea": "reacher-bad-luck-and-trouble",
    "79496c81": "goggins-nada-pode-me-ferir",
    "915aeb44": "homem-mais-rico-da-babilonia",
    "9542227d": "maze-runner-3-cura-mortal",
    "9b609990": "inabalavel",
    "9c58644e": "tolstoi-quanta-terra",
    "a8053f18": "reacher-dinheiro-sujo",
    "b889a468": "percy-jackson-box",
    "bb8d71b1": "maze-runner-1-correr-ou-morrer",
    "d28f6c4b": "rickson-respire",
    "f6ed0641": "maze-runner-2-prova-de-fogo",
}

def pandoc(src, fmt=None):
    cmd = ["pandoc", src, "-t", "plain", "--wrap=none"]
    if fmt:
        cmd[2:2] = ["-f", fmt]
    return subprocess.run(cmd, capture_output=True, text=True, timeout=600).stdout

def limpar(t):
    t = re.sub(r"\[\]\{[^}]*\}", "", t)          # âncoras vazias do pandoc
    t = re.sub(r"\n{3,}", "\n\n", t)
    return t.strip() + "\n"

for f in sorted(os.listdir(UP)):
    pref = f.split("-")[0]
    slug = MAPA.get(pref)
    if not slug:
        continue
    src = os.path.join(UP, f)
    ext = f.rsplit(".", 1)[-1].lower()
    try:
        if ext == "pdf":
            txt = subprocess.run(["pdftotext", src, "-"], capture_output=True, text=True, timeout=600).stdout
        elif ext == "epub":
            txt = pandoc(src)
        elif ext == "fb2":
            txt = pandoc(src, "fb2")
        elif ext == "azw3":
            tmpdir, extracted = mobi.extract(src)
            fmt = None
            txt = pandoc(extracted) if extracted.endswith(".epub") else pandoc(extracted, "html")
            shutil.rmtree(tmpdir, ignore_errors=True)
        else:
            print("??", f); continue
        txt = limpar(txt)
        open(os.path.join(OUT, slug + ".txt"), "w").write(txt)
        print(f"{slug:36s} {ext:5s} {len(txt.split()):>8d} palavras {txt.count(chr(10)):>7d} linhas")
    except Exception as e:
        print("ERRO", slug, e, file=sys.stderr)
