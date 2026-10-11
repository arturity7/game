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

## 3. O que o jogo é / não é

**É:**
- Jogo para PC ✅
- Projeto pessoal, sem publicação nem venda ✅
- Pixel art no estilo do Stardew Valley ✅
- Um jogo com casa e fazenda próprias, animais, plantação, fome e descanso ✅
- Um jogo cujo progresso principal vem de conteúdo baseado em livros ✅

**Não é:**
- Um jogo focado em fazenda. A fazenda existe por causa da fome, não como objetivo principal ✅

## 4. Sistemas

### 4.1 Sistemas de suporte (vida no campo)

| Sistema | O que já se sabe | Status | Pendências |
|---|---|---|---|
| Casa própria | Existe. Tem um local para dormir e descansar. | ✅ existe | ❓ upgrades, móveis, outros usos |
| Fazenda / plantação | Existe. Serve para produzir comida. | ✅ existe | ❓ regras de plantio, estações, ferramentas |
| Animais | Existem. Servem para produzir comida. | ✅ existe | ❓ quais animais, cuidados, produtos |
| Fome | Existe. É a razão de ter fazenda e animais. | ✅ existe | ❓ como cai, o que acontece com fome zero, como comer |
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
| Fases | O dono usou a expressão "passar de fase". | ❓ o que é uma fase |

Detalhes do processo em [`conteudo-dos-livros.md`](conteudo-dos-livros.md).

## 5. Loop de jogo

❓ **Em aberto.** O que já se sabe:
- O jogador precisa se manter vivo/alimentado e descansado usando casa, fazenda e animais.
- O jogador avança resolvendo conteúdo baseado nos livros.

Como essas duas partes se encaixam no dia a dia do jogador (ordem, tempo gasto, recompensas) ainda não foi definido.

## 6. Mundo e história

| Tema | Status |
|---|---|
| Os livros ficam em regiões separadas ou num mundo único misturado? | ❓ |
| Existe uma história principal que amarra os livros? | ❓ |
| Quem é o protagonista e por que está ali? | ❓ |
| Existe cidade / NPCs fora do conteúdo dos livros? | ❓ |
| Tempo, calendário e estações como no Stardew? | ❓ |

## 7. Arte e som

| Tema | Status |
|---|---|
| Pixel art no estilo do Stardew Valley | ✅ |
| Arte original (não é permitido usar arte do Stardew Valley) | ✅ obrigatório por direitos autorais |
| Quem produz a arte | ❓ |
| Música e efeitos sonoros | ❓ |

## 8. Plataforma e tecnologia

| Tema | Status |
|---|---|
| PC | ✅ |
| Linguagem/engine: escolha delegada à IA | ✅ delegado · 🔵 proposta: Godot 4 + GDScript ([`tecnico.md`](tecnico.md)) |
| Só Windows ou também Linux/Mac | ❓ |
| Controles (teclado/mouse, controle) | ❓ |

## 9. Livros do jogo

| Livro | Autor | Ficha | Status |
|---|---|---|---|
| — | — | — | Aguardando os PDFs |
