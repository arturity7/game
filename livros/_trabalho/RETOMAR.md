# Como retomar a análise dos livros (para a IA)

> Área com spoilers. Aqui fica o estado de trabalho: progresso e notas de leitura (paráfrases, sem texto dos livros).

1. Repo em `/home/claude/jogo-livros`. Se não existir: `git clone https://github.com/arturity7/game.git /home/claude/jogo-livros`.
2. Textos dos livros ficam fora do repo, em `/home/claude/textos/`. Se a pasta sumiu (container novo):
   - `mkdir -p /home/claude/textos/notas && cp livros/_trabalho/PROGRESSO.md /home/claude/textos/ && cp livros/_trabalho/notas/*.md /home/claude/textos/notas/`
   - `pip install --break-system-packages mobi beautifulsoup4` (se faltar) e `python3 -I ferramentas/converter.py` (lê os anexos em `/root/.claude/uploads/<sessão>/`; ajustar a constante `UP` se o caminho mudou).
   - `python3 -I ferramentas/dividir.py` (gera `chunks/<slug>/NN.txt`, mesmas divisões de antes).
   - Se os anexos não estiverem mais disponíveis: avisar o dono e pedir os arquivos de novo.
3. **Situação em 12/10/2026: os 20 arquivos (24 livros) estão lidos e com ficha. Pular para o passo 7.** Para livros novos: abrir `/home/claude/textos/PROGRESSO.md` e pegar o primeiro livro sem ✅. Ver em `notas/<slug>.md` até que parte já foi lida ("## Parte NN") e continuar da próxima.
4. Para cada parte: ler o chunk inteiro, anexar notas densas em `notas/<slug>.md`.
5. Na última parte: escrever `livros/<slug>.md` pelo `livros/_TEMPLATE.md`; rodar `bash ferramentas/fechar_livro.sh <slug> "<trecho do título em docs/livros-recebidos.md>" "<título>"` (marca 📝, salva notas no repo, commit e push).
6. Regras: sem spoiler no chat nem nos commits; citações < 15 palavras; D-066 (pessoas reais vivas não viram NPC com nome); D-067 (inverno → área fria); chat em estilo caveman.
6a. Caixa Percy Jackson (`percy-jackson-box`, 48 chunks): **uma ficha por volume** (`livros/percy-jackson-N-<titulo>.md`, IDs `percy_N.`) e uma nota por volume (`notas/percy-N-<titulo>.md`). Os cinco volumes prontos (12/10/2026). Volume 3 (A Maldição do Titã): chunks 19 (linha ~76) a 27; volume 4 (A Batalha do Labirinto): 27 (linha 672) a 37; volume 5 (O Último Olimpiano): 37 (linha 748) a 48. Volumes 1–4: commit manual `conteudo: ficha de Percy Jackson: <título>` e atualizar a coluna "Lidas" no PROGRESSO. Só no volume 5 rodar `fechar_livro.sh percy-jackson-box "Percy Jackson" "Percy Jackson e os Olimpianos"`. Mesmo mundo: dimensão `percy_1.dimensao.alem_da_nevoa`, hub `percy_1.local.colina_meio_sangue`; reaproveitar NPCs/itens de `percy_1`/`percy_2`.
7. Depois de todos os livros: `livros/_MUNDO.md` (mapa, biomas × dimensões, ligações, chaves, candidato a objetivo final) e revisão das fichas; depois perguntar ao dono a Q4b (objetivo final).
   **Feito em 12/10/2026**: `livros/_MUNDO.md` criado (D-068), ligações "a confirmar" revisadas, lugares "a definir" resolvidos, GDD §9 atualizado. Q4b respondida (D-069: sem objetivo final por enquanto) e Q45 respondida (D-070: pode nadar; barco é mais rápido). Fase de código começou em 12/10/2026: protótipo 0 em `game/` (ver `docs/tecnico.md` §8). Testes: `bash ferramentas/testar_jogo.sh`; exe: `bash ferramentas/exportar_windows.sh` (Godot 4.3 em /home/claude/godot; se sumiu, baixar do GitHub do Godot, versão 4.3-stable, e os export templates).

8. **Fase de código (desde 12/10/2026).** Protótipo 0 (andar, fome/vida, relógio, save) e protótipo 1 (inventário, barra de itens, plantação, comer, dormir; save v2) prontos e testados. **Em andamento (13/10/2026): passe de arte** pedido pelo dono: "semelhança real com o estilo gráfico de Pokémon (GBA) e Stardew Valley", sem copiar arte. Plano:
   - `ferramentas/arte/pixel.py` (paleta própria, contorno automático, ruído, terreno em grade dupla de 16 máscaras) e `ferramentas/arte/gerar_arte.py` (gera tudo em `game/assets/sprites/`).
   - Chão: grama com variações; terra, caminho, água (animada) e solo arado com bordas suaves pela grade dupla (camadas deslocadas meio tile; máscara TL=1, TR=2, BL=4, BR=8).
   - Objetos grandes com ordenação por Y: casa inteira (não repetida), árvores altas com sombra, cercas que se ligam; mapa com lista de objetos separada do chão.
   - Personagem 4 direções × 4 quadros andando; fonte Pixelify Sans (OFL, em `game/assets/fontes/`); HUD de madeira.
   - Depois: build nova para o dono; em seguida motor de perguntas e diálogos dos livros.
   - O dono pediu para seguir sem perguntar. Se os tokens acabarem, há um envio agendado para retomar às 5h (horário de Brasília).
