# Como retomar a análise dos livros (para a IA)

> Área com spoilers. Aqui fica o estado de trabalho: progresso e notas de leitura (paráfrases, sem texto dos livros).

1. Repo em `/home/claude/jogo-livros`. Se não existir: `git clone https://github.com/arturity7/game.git /home/claude/jogo-livros`.
2. Textos dos livros ficam fora do repo, em `/home/claude/textos/`. Se a pasta sumiu (container novo):
   - `mkdir -p /home/claude/textos/notas && cp livros/_trabalho/PROGRESSO.md /home/claude/textos/ && cp livros/_trabalho/notas/*.md /home/claude/textos/notas/`
   - `pip install --break-system-packages mobi beautifulsoup4` (se faltar) e `python3 -I ferramentas/converter.py` (lê os anexos em `/root/.claude/uploads/<sessão>/`; ajustar a constante `UP` se o caminho mudou).
   - `python3 -I ferramentas/dividir.py` (gera `chunks/<slug>/NN.txt`, mesmas divisões de antes).
   - Se os anexos não estiverem mais disponíveis: avisar o dono e pedir os arquivos de novo.
3. Abrir `/home/claude/textos/PROGRESSO.md`: pegar o primeiro livro sem ✅. Ver em `notas/<slug>.md` até que parte já foi lida ("## Parte NN") e continuar da próxima.
4. Para cada parte: ler o chunk inteiro, anexar notas densas em `notas/<slug>.md`.
5. Na última parte: escrever `livros/<slug>.md` pelo `livros/_TEMPLATE.md`; rodar `bash ferramentas/fechar_livro.sh <slug> "<trecho do título em docs/livros-recebidos.md>" "<título>"` (marca 📝, salva notas no repo, commit e push).
6. Regras: sem spoiler no chat nem nos commits; citações < 15 palavras; D-066 (pessoas reais vivas não viram NPC com nome); D-067 (inverno → área fria); chat em estilo caveman.
7. Depois de todos os livros: `livros/_MUNDO.md` (mapa, biomas × dimensões, ligações, chaves, candidato a objetivo final) e revisão das fichas; depois perguntar ao dono a Q4b (objetivo final).
