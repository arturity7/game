#!/bin/bash
# uso: fechar_livro.sh <slug> "<trecho do título na lista>" "<título para o commit>"
set -e
SLUG="$1"; TRECHO="$2"; TITULO="$3"
cd /home/claude/jogo-livros
python3 - "$TRECHO" <<'PY'
import sys
trecho=sys.argv[1]; p="docs/livros-recebidos.md"; linhas=open(p).read().split("\n"); n=0
for i,l in enumerate(linhas):
    if l.startswith("| ") and trecho in l and l.rstrip().endswith("📥 |"):
        linhas[i]=l.rstrip()[:-3].rstrip()+" 📝 |"; n+=1
open(p,"w").write("\n".join(linhas)); print("status atualizado:",n)
PY
python3 - "$SLUG" <<'PY'
import sys,re
slug=sys.argv[1]; p="/home/claude/textos/PROGRESSO.md"; t=open(p).read()
t=re.sub(r"\| "+re.escape(slug)+r" \| (\d+) \| \d+ \| \|", lambda m:f"| {slug} | {m.group(1)} | {m.group(1)} | ✅ |", t)
open(p,"w").write(t)
PY
bash ferramentas/salvar_trabalho.sh
git add -A
git commit -q -m "conteudo: ficha de $TITULO

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Kzt8bq9ekhbHqR45GCB41M"
timeout 120 git push -q 2>&1 | grep -v "acknowledgments\|negotiation" || true
git status -sb | head -1
