#!/bin/bash
# Gera o executável do Windows em game/build/LeafAndLore.exe (e um .zip com ele).
# Precisa dos modelos de exportação do Godot 4.3 em ~/.local/share/godot/export_templates/4.3.stable/
# uso: bash ferramentas/exportar_windows.sh [caminho_do_godot]
set -e
G="${1:-/home/claude/godot/Godot_v4.3-stable_linux.x86_64}"
cd "$(dirname "$0")/../game"
mkdir -p build
timeout 300 "$G" --headless --path . --export-release "Windows Desktop" build/LeafAndLore.exe >/dev/null 2>&1
cd build && rm -f LeafAndLore.zip && python3 -c "import zipfile;z=zipfile.ZipFile('LeafAndLore.zip','w',zipfile.ZIP_DEFLATED);z.write('LeafAndLore.exe');z.close()"
ls -la LeafAndLore.exe LeafAndLore.zip
