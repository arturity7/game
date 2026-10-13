#!/bin/bash
# Tira fotos da cena (480x270) e faz cópias ampliadas 3x, para conferir a arte.
# uso: bash ferramentas/fotos_jogo.sh <pasta> [caminho_do_godot]
set -e
P="$(realpath -m "${1:?pasta}")"; mkdir -p "$P"
G="${2:-/home/claude/godot/Godot_v4.3-stable_linux.x86_64}"
cd "$(dirname "$0")/../game"
rm -f "$HOME/.local/share/godot/app_userdata/Leaf & Lore/save.json"
timeout 120 xvfb-run -a -s "-screen 0 1440x810x24" "$G" --path . --rendering-driver opengl3 -- --fotos="$P" 2>&1 | grep -E "ERROR|SCRIPT" || true
python3 -c "
import sys,glob
from PIL import Image
for f in glob.glob(sys.argv[1]+'/[0-9]_*.png'):
    if f.endswith('_3x.png'): continue
    im=Image.open(f); im.resize((im.width*3,im.height*3),Image.NEAREST).save(f[:-4]+'_3x.png')
" "$P"
ls "$P"
