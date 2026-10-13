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

8. **Fase de código (desde 12/10/2026).** Protótipo 0 (andar, fome/vida, relógio, save) e protótipo 1 (inventário, barra de itens, plantação, comer, dormir; save v2) prontos e testados.
   **Passe de arte feito (13/10/2026)**, pedido do dono: "semelhança real com o estilo gráfico de Pokémon (GBA) e Stardew Valley", sem copiar arte. Detalhes em `docs/tecnico.md` §7. Resumo:
   - `ferramentas/arte/pixel.py` + `gerar_arte.py` geram toda a arte; `fonte.py` gera a fonte própria Leaf Pixel; `bash ferramentas/fotos_jogo.sh <pasta>` tira fotos para conferir.
   - Mapa: chão (`tiles.json`) + objetos (`objetos.json`), desenho em grade dupla + y-sort em `scripts/world/mundo.gd`.
   - Build nova enviada ao dono (zip do .exe).
   Próximos passos (seguir sem perguntar, pedido do dono):
   - Feito também: efeitos de ferramenta e colheita, janelas acesas à noite, sons e música gerados por código (`ferramentas/som/gerar_sons.py`).
   - Feito também: tela de abertura, pose de usar ferramenta, enfeites na grama, casa por dentro (cama), cidade com mercado (loja), clínica (desmaio) e ferreiro fechado (D-072).
   - Feito (13/10/2026): motor de conversas, perguntas, missões, diário e conquistas (`docs/tecnico.md` §9) e o primeiro livro jogável (Epicuro: Jardim ao norte da cidade, três cartas, chave de Além da Névoa).
   - Feito (13/10/2026): Seja Útil em parte (forja aberta com as sete ferramentas e ferramentas melhores; quiosque do Jornaleiro).
   - Feito (13/10/2026): pesca (D-073); Colina do Portal e Walden em parte (Thoreau, lenhador, fundo do lago, peixes) (D-074).
   - Feito (13/10/2026): Tolstói em parte (sapataria de Simon na cidade, história de Michael, casaco de lã).
   - Feito (13/10/2026): Babilônia em parte (Arkad e Mathon no Mercado: poupança, décimo, muralha, lições).
   - Feito (13/10/2026, tarde): manchas na grama, sombras sem contorno, borboletas/folhas/vaga-lumes, morros com paredão, machado e tocos, animais e menu Construir, combate (espada, inimigos, chefes), chuva/tempestade, Percy Jackson 1 em parte (portal, homem-touro, acampamento). Pedidos do dono (D-081): Opções, Shift corre, arado volta a grama, Mercado compra tudo.
   - Build: desde 13/10 o jogo sai em `.exe` (motor, igual sempre) + `.pck` (dados). Atualização = mandar só o `.pck` ao dono. Mandar o `.zip` inteiro só se o motor (versão do Godot) mudar.
   - Em andamento (não commitado): retratos dos personagens na caixa de conversa (`ferramentas/arte/retratos.py`, `game/assets/sprites/retratos/`); falta ligar na `caixa_dialogo.gd` (retrato à esquerda, acima da caixa; nome ao lado) e um mapa nome → retrato.
   - Próximo: os outros livros, um por vez, seguindo `_MUNDO.md` (lugares na cidade primeiro: Mercado com Arkad e Mathon, sapataria de Simon; depois biomas em volta da fazenda); portal na Colina do Portal; animais, machado/árvores, ferreiro, rotina de moradores.
   - Motor de diálogos e perguntas lendo `content/livros/<id>/…` a partir das fichas; depois cidade, loja, animais.
   - Se os tokens acabarem, há um envio agendado para retomar às 5h (horário de Brasília).
