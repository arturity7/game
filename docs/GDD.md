# GDD — Documento de Design do Jogo

> Versão 0.1 · 11/10/2026 · Status: rascunho inicial
> Este documento registra **somente** o que o dono do projeto definiu. Tudo que ainda não foi decidido aparece como ❓ e tem pergunta correspondente em [`perguntas-abertas.md`](perguntas-abertas.md).

---

## 1. Visão

Um jogo para PC, com o estilo e os gráficos do Stardew Valley, em que o jogador mantém a própria casa e a própria fazenda para sobreviver, mas cujo coração são desafios tirados de livros que o dono do projeto já leu: puzzles, batalhas, bosses, perguntas, diálogos e histórias paralelas.

## 2. Pilares

| # | Pilar | Status |
|---|---|---|
| P1 | **Os livros são o núcleo.** Todo desafio principal nasce de um livro lido pelo dono do projeto. | ✅ |
| P2 | **Lembrar é jogar.** Há desafios que só se resolve lembrando do livro — ou relendo-o. | ✅ |
| P3 | **A vida no campo sustenta, não protagoniza.** Casa, fazenda, animais, fome e sono existem, mas não são o foco. | ✅ |
| P4 | **Cara e sensação de Stardew Valley.** Pixel art e estilo de jogo inspirados nele. | ✅ |
| P5 | **Sem pressa.** Existe um objetivo final, mas o jogador avança no próprio ritmo e pode passar o tempo que quiser melhorando e crescendo a fazenda (como no Minecraft). | ✅ |

## 3. O que o jogo é / não é

**É:**
- Jogo para PC ✅
- Projeto pessoal, sem publicação nem venda ✅
- Pixel art no estilo do Stardew Valley ✅
- Um jogo com casa e fazenda próprias, animais, plantação, fome e descanso ✅
- Um jogo cujo progresso principal vem de conteúdo baseado em livros ✅

**Não é:**
- Um jogo focado em fazenda. A fazenda existe por causa da fome, não como objetivo principal ✅ — mas o jogador pode, se quiser, gastar o tempo que quiser melhorando e crescendo a fazenda ✅
- Um jogo com pressa ou prazo para terminar a história ✅

## 4. Sistemas

### 4.1 Sistemas de suporte (vida no campo)

| Sistema | O que já se sabe | Status | Pendências |
|---|---|---|---|
| Casa própria | Existe. Tem um local para dormir e descansar. | ✅ existe | ❓ upgrades, móveis, outros usos |
| Fazenda / plantação | Existe. Serve para produzir comida. | ✅ existe | ❓ regras de plantio, estações, ferramentas |
| Animais | Existem. Servem para produzir comida. | ✅ existe | ❓ quais animais, cuidados, produtos |
| Fome | Existe. É a razão de ter fazenda e animais. **Cai com o tempo**; esforço (trabalhar, lutar etc.) acelera um pouco a queda. **Com fome zerada, o jogador perde vida aos poucos**, como no Minecraft. | ✅ | ❓ como comer |
| Vida | Existe (é o que cai quando a fome zera). | ✅ existe | ❓ outras fontes de dano e de recuperação |
| Energia | **Não existe.** O jogador tem só duas barras: fome e vida. O esforço (usar ferramentas, lutar) pesa apenas acelerando um pouco a fome (D-024). | ✅ | — |
| Dormir / descansar | Existe. | ✅ existe | ❓ regras, horário, consequências |
| "Outras coisas" | O dono citou "e outras coisas" ao listar o que a casa/fazenda precisa ter. | ❓ | ❓ quais são |

> Observação: no Stardew Valley **não existe fome** — só energia e vida (ver [`referencia-stardew.md`](referencia-stardew.md)). A fome é uma diferença deste jogo.

### 4.2 Sistemas do núcleo (conteúdo dos livros)

| Sistema | O que já se sabe | Status |
|---|---|---|
| Puzzles | Baseados nos livros. | ✅ existe · ❓ formato |
| Batalhas | Baseadas nos livros. | ✅ existe · ❓ estilo de combate |
| Inimigos | Podem ser inimigos que aparecem nos livros. | ✅ |
| Bosses | Baseados nos livros. | ✅ existe · ❓ formato |
| Perguntas | Desafios em que, para responder, é preciso lembrar do livro ou relê-lo para passar de fase. | ✅ |
| Diálogos | Baseados nos livros; podem ser a forma de fazer as perguntas. | ✅ |
| Histórias paralelas | Baseadas nos livros. | ✅ existe · ❓ formato |
| Locais do mapa | Podem ser lugares que aparecem em livros. | ✅ |
| Progressão | Não há fases formais ("passar de fase" foi modo de dizer). Ver §5. | ✅ |
| Missões | Existem. Cumprir missões rende itens como as chaves das dimensões. | ✅ existe · ❓ formato |

Detalhes do processo em [`conteudo-dos-livros.md`](conteudo-dos-livros.md).

## 5. Loop de jogo

❓ **Em aberto.** O que já se sabe:
- O jogador precisa se manter vivo/alimentado e descansado usando casa, fazenda e animais.
- O jogador avança resolvendo conteúdo baseado nos livros.

### 5.1 Progressão ✅ (D-018)

Não existem fases formais. O jogo avança por **desbloqueio**:
- **Áreas e missões:** o mundo abre aos poucos; missões rendem itens que liberam lugares (inclusive as chaves das dimensões).
- **Desafios como bloqueio:** uma pergunta, um puzzle ou um boss pode fechar um caminho; vencê-lo libera a área seguinte.
- **Ordem da história:** dentro de cada bioma ou dimensão, o conteúdo segue a ordem da história do livro.
- **Marco de livro:** concluir todo o conteúdo de um livro completa o seu bioma ou dimensão.
- **Cruzamento entre livros:** o que se conquista em um livro pode ser necessário em outro (D-015).

### 5.2 Dia a dia

❓ Como a vida no campo e a progressão se encaixam no dia a dia do jogador (ordem, tempo gasto, recompensas) ainda não foi definido.

## 6. Mundo e história

| Tema | Status |
|---|---|
| Organização dos livros | ✅ Tudo num mesmo mundo, com **um bioma por livro** |
| Histórias que se cruzam | ✅ Desbloquear um lugar de um livro pode exigir algo de outro livro (ex.: o lugar do livro 1 só abre com algo do livro 2) |
| Dimensões | ✅ Livros **muito diferentes da vida real** (ex.: Harry Potter) ficam em uma **dimensão própria**, para onde o jogador viaja. Livros mais próximos da realidade viram bioma no mundo principal. A classificação de cada livro é feita na análise e registrada na ficha. |
| Como viajar até as dimensões | ✅ Por um **portal fixo no mundo principal**. Para entrar, é preciso um item (algo como uma **chave**) conseguido cumprindo **outras missões**. ❓ uma chave por dimensão ou uma só |
| História principal | ✅ **Leve, de fundo:** um motivo simples para o protagonista estar ali e um objetivo final. Os livros continuam sendo o foco. |
| Ritmo da história | ✅ **Sem pressa e sem prazo.** A história não empurra o jogador; ele pode crescer e melhorar a fazenda à vontade e seguir a missão final quando quiser (como no Minecraft). |
| Motivo do protagonista | ✅ **Nenhum.** É um mundo normal e o protagonista simplesmente começa a se aventurar, como no Minecraft. |
| Objetivo final | ❓ Existe, mas ainda não foi definido. A decidir depois da análise dos primeiros livros. |
| Existe cidade / NPCs fora do conteúdo dos livros? | ❓ |
| Tempo, calendário e estações como no Stardew? | ❓ |

## 7. Arte e som

| Tema | Status |
|---|---|
| Pixel art no estilo do Stardew Valley | ✅ |
| Arte original (não é permitido usar arte do Stardew Valley) | ✅ obrigatório por direitos autorais |
| Quem produz a arte | ✅ **A IA**, delegado pelo dono: busca recursos nos sites que julgar melhores e gera por código o que faltar. Detalhes em `tecnico.md` §6. |
| Música e efeitos sonoros | ❓ |

## 8. Plataforma e tecnologia

| Tema | Status |
|---|---|
| PC | ✅ |
| Linguagem/engine | ✅ Godot 4 + GDScript (escolha delegada à IA; ver [`tecnico.md`](tecnico.md)) |
| Sistema operacional | ✅ Windows (o jogo abre como `.exe`) |
| Save | ✅ O jogo salva o progresso. ❓ só ao dormir ou a qualquer momento |
| Controles (teclado/mouse, controle) | ❓ |

## 9. Livros do jogo

| Livro | Autor | Ficha | Status |
|---|---|---|---|
| — | — | — | Aguardando os PDFs |
