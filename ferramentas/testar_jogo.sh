#!/bin/bash
# Roda os testes do jogo: unitários (sem tela) e o autoteste da cena principal (tela virtual).
# uso: bash ferramentas/testar_jogo.sh [caminho_do_godot]
set -e
G="${1:-/home/claude/godot/Godot_v4.3-stable_linux.x86_64}"
cd "$(dirname "$0")/../game"
timeout 120 "$G" --headless --path . --import >/dev/null 2>&1 || true
echo "== testes unitários"
U=$(timeout 120 "$G" --headless --path . --script res://tests/run_tests.gd 2>&1); echo "$U" | grep -E "FALHOU|verificações|SCRIPT ERROR"
echo "$U" | grep -q " 0 falha" || { echo "TESTES UNITÁRIOS FALHARAM"; exit 1; }
echo "$U" | grep -q "SCRIPT ERROR" && { echo "ERRO DE SCRIPT"; exit 1; }
echo "== autoteste da cena"
rm -f "$HOME/.local/share/godot/app_userdata/Leaf & Lore/save.json"
A=$(timeout 120 xvfb-run -a -s "-screen 0 1440x810x24" "$G" --path . --rendering-driver opengl3 -- --autoteste 2>&1); echo "$A" | grep -E "FALHOU|autoteste|SCRIPT ERROR"
echo "$A" | grep -q "autoteste: 0 falha" || { echo "AUTOTESTE FALHOU"; exit 1; }
echo "$A" | grep -q "SCRIPT ERROR" && { echo "ERRO DE SCRIPT"; exit 1; }
echo "tudo ok"
