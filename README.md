# Leaf & Lore — jogo de livros no estilo Stardew Valley

> **Status:** fase de documentação. Nenhuma linha de código ainda.
> **Nome:** Leaf & Lore ("leaf" = folha de planta e folha de livro; "lore" = saber, história). Escolhido pelo dono (D-049).

Jogo para PC, em pixel art no estilo visual e de jogabilidade do Stardew Valley.

- **Suporte (não é o foco):** casa própria, fazenda, plantação, animais, pesca, construção, loja na cidade, fome e vida.
- **Núcleo do jogo:** puzzles, batalhas, bosses, perguntas, diálogos e histórias paralelas criados a partir de livros que o dono do projeto já leu. Cada livro vira um bioma no mundo (ou uma dimensão, se for muito fantasioso). Para avançar, o jogador precisa lembrar do livro — ou relê-lo.
- **Ritmo livre:** sem pressa e sem fim definitivo; novos livros entram a cada atualização, sem perder o save.

## Documentos

| Arquivo | O que tem |
|---|---|
| [`docs/GDD.md`](docs/GDD.md) | Documento de design: o que o jogo é, pilares, sistemas e o que está definido ou em aberto |
| [`docs/conteudo-dos-livros.md`](docs/conteudo-dos-livros.md) | Como um livro vira conteúdo de jogo (processo e tipos de conteúdo) |
| [`docs/referencia-stardew.md`](docs/referencia-stardew.md) | Estudo de como o Stardew Valley funciona por dentro |
| [`docs/tecnico.md`](docs/tecnico.md) | Proposta de engine, linguagem e arquitetura |
| [`docs/nomes.md`](docs/nomes.md) | Sugestões de nome |
| [`docs/livros-recebidos.md`](docs/livros-recebidos.md) | **Lista dos livros já enviados e status de cada um (sem spoilers)** |
| [`docs/perguntas-abertas.md`](docs/perguntas-abertas.md) | Decisões que dependem do dono do projeto |
| [`docs/decisoes.md`](docs/decisoes.md) | Registro de tudo que já foi decidido |
| [`livros/_TEMPLATE.md`](livros/_TEMPLATE.md) | Modelo de ficha de análise de cada livro |
| [`CLAUDE.md`](CLAUDE.md) | Regras de trabalho para a IA que desenvolve o projeto |

## ⚠️ Spoilers

As pastas `livros/` e `game/content/` contêm as perguntas, respostas e segredos do jogo. Abrir esses arquivos estraga a surpresa.

## Regra de ouro

Ideias de jogo vêm de duas fontes apenas: **o dono do projeto** e **os livros**.
Fora disso, a IA não inventa — registra a dúvida em `docs/perguntas-abertas.md` e pergunta.

## Legenda de status usada nos documentos

- ✅ **Definido** — decidido pelo dono do projeto
- 🔵 **Proposto** — sugestão técnica da IA (área delegada), aguardando ok
- ❓ **Em aberto** — falta decisão do dono do projeto
