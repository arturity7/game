#!/bin/bash
# Gera o jogo para Windows em game/build/: LeafAndLore.exe (o motor, igual em toda build da mesma
# versão do Godot) + LeafAndLore.pck (os dados do jogo, que mudam a cada build).
# Também gera LeafAndLore.zip (exe + pck + LEIA-ME) para a primeira instalação.
# Para atualizar, basta trocar o LeafAndLore.pck ao lado do .exe (arquivo pequeno).
# Precisa dos modelos de exportação do Godot 4.3 em ~/.local/share/godot/export_templates/4.3.stable/
# uso: bash ferramentas/exportar_windows.sh [caminho_do_godot]
set -e
G="${1:-/home/claude/godot/Godot_v4.3-stable_linux.x86_64}"
cd "$(dirname "$0")/../game"
mkdir -p build
rm -f build/LeafAndLore.exe build/LeafAndLore.pck
timeout 300 "$G" --headless --path . --export-release "Windows Desktop" build/LeafAndLore.exe >/dev/null 2>&1
cat > build/LEIA-ME.txt <<'TXT'
Leaf & Lore

Para jogar: deixe LeafAndLore.exe e LeafAndLore.pck na mesma pasta e abra o LeafAndLore.exe.
Não mude o nome dos arquivos.

Atualizações: quando chegar um LeafAndLore.pck novo, troque o antigo por ele (na mesma pasta do .exe).
O save fica em outra pasta (%APPDATA%\Godot\app_userdata\Leaf & Lore) e não se perde.
TXT
cd build && rm -f LeafAndLore.zip && python3 -c "
import zipfile
z = zipfile.ZipFile('LeafAndLore.zip', 'w', zipfile.ZIP_DEFLATED, compresslevel=9)
for f in ('LeafAndLore.exe', 'LeafAndLore.pck', 'LEIA-ME.txt'):
    z.write(f)
z.close()"
ls -la LeafAndLore.exe LeafAndLore.pck LeafAndLore.zip
