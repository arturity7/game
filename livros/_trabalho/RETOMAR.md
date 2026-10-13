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
   **Feito em 12/10/2026**: `livros/_MUNDO.md` criado (D-068), ligações "a confirmar" revisadas, lugares "a definir" resolvidos, GDD §9 atualizado. Q4b respondida (D-069: sem objetivo final por enquanto) e Q45 respondida (D-070: pode nadar; barco é mais rápido). Próxima etapa depois disso: fase de código (`docs/tecnico.md`), quando o dono der o sinal.
