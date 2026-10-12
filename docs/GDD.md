# Leaf & Lore — Documento de Design do Jogo (GDD)

> Versão 0.2 · 11/10/2026 · Status: rodada inicial de perguntas concluída
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
| Casa própria | Tem cama para dormir e descansar. O jogador **amplia e reforma** a casa construindo paredes e móveis (estilo The Sims 4) e cozinha num **fogão ou fogueira** que ele mesmo constrói. | ✅ | — |
| Fazenda / plantação | Serve para produzir comida. As plantas **precisam de água**: o jogador **rega**, ou **cria um pequeno lago ao lado** da plantação, que rega sozinho (como a água no Minecraft). Ferramentas: **enxada e regador**, com versões **melhores compradas na loja**. Sem estações. | ✅ | — |
| Animais | **Galinha, vaca, porco e ovelha.** **Pastam sozinhos** (não precisa alimentar). **Reproduzem como no Minecraft.** Produzem **ovo, leite, carne e lã**, que podem ser vendidos ou usados pelo jogador. | ✅ | — |
| Predadores | Existem predadores, como **lobos**. Eles **atacam só os animais**, nunca o jogador. Animais soltos ficam em perigo, então precisam ficar em **cercados**. | ✅ | — |
| Roupas e ambientes | Produtos dos animais viram itens úteis, como **roupas de lã** para **locais frios**. O jogador **pode entrar** sem a roupa adequada, mas **toma dano** enquanto estiver lá. | ✅ | — |
| Fome | Existe. É a razão de ter fazenda e animais. **Cai com o tempo**; esforço (trabalhar, lutar etc.) acelera um pouco a queda. **Com fome zerada, o jogador perde vida aos poucos**, como no Minecraft. | ✅ | — |
| Comer e cozinhar | Dá para comer **cru** (enche pouco) ou **cozinhado** (enche mais). Existe culinária, feita no fogão ou fogueira construídos pelo jogador. | ✅ | — |
| Vida | Cai com fome zerada, ataques de monstros, **veneno** e **ambientes hostis sem roupa adequada** (ex.: frio). Recupera **comendo** ou com **itens de cura comprados no hospital**. | ✅ | — |
| Vida zerada | O jogador **acorda num hospital ou clínica** (na cidade) e **perde dinheiro**. Sem game over. | ✅ | quantia a definir no balanceamento |
| Energia | **Não existe.** O jogador tem só duas barras: fome e vida. O esforço (usar ferramentas, lutar) pesa apenas acelerando um pouco a fome (D-024). | ✅ | — |
| Dormir / descansar | **Não é obrigatório** e não tem regras rígidas (sem horário limite nem desmaio). Dormir **faz a noite passar mais rápido**, o que ajuda a plantação a avançar. | ✅ | — |
| Pesca | **Simples, como no Minecraft:** joga a linha, espera e puxa na hora certa. Sem minigame. | ✅ | — |
| Árvores e construção | Cortar árvores para obter material e **construir** e **melhorar a fazenda**. Construção **por receitas pré-definidas**, como no Minecraft (ex.: cercado custa X de madeira), e **não** bloco a bloco livre. Na casa, funciona **quase como o modo construção do The Sims 4**: levantar paredes, ampliar cômodos e posicionar móveis. Itens construíveis: cercados, pequenos lagos de irrigação, galinheiro, celeiro, baús, caminhos, cercas decorativas, pontes, fogão/fogueira, paredes e móveis da casa. | ✅ | — |
| Lojas e dinheiro | **Poucas lojas** na cidade (nem uma só, nem muitas), onde o jogador **vende produtos da fazenda** e compra **sementes, animais, comida, materiais, ferramentas e equipamentos**. 🔵 Divisão proposta pela IA: **Mercado** (compra produtos da fazenda; vende sementes, animais, comida e materiais) e **Ferreiro** (ferramentas, armas e equipamentos), além do **hospital** (itens de cura). | ✅ · 🔵 divisão | — |
| Conquistas | Tela de **conquistas em forma de medalhas** (ex.: "terminou o livro X", "derrotou 100 monstros", "sobreviveu 365 dias"). É o único lugar onde a contagem de dias aparece. Cada livro novo traz suas próprias conquistas. | ✅ | — |
| Mineração | Cavernas com pedra e minérios, explorados com **picareta**. Minérios servem **principalmente para vender**, não para fabricar ferramentas. | ✅ | — |
| Máquinas | **Compradas nas lojas** (não fabricadas). Servem para **melhorar a fazenda e automatizar processos**, como transformar produtos em itens de mais valor. | ✅ | — |
| Equipamentos | Armas: **espada e arco**, em níveis cada vez melhores comprados no Ferreiro. **Sem armadura** por enquanto. **Sem magia:** o protagonista é humano. Inimigos de dimensões fantasiosas podem usar magia. | ✅ | — |

> Observação: no Stardew Valley **não existe fome** — só energia e vida (ver [`referencia-stardew.md`](referencia-stardew.md)). A fome é uma diferença deste jogo.

### 4.2 Sistemas do núcleo (conteúdo dos livros)

| Sistema | O que já se sabe | Status |
|---|---|---|
| Puzzles | Baseados nos livros. Formato decidido pela IA livro a livro (D-061). | ✅ |
| Batalhas | Baseadas nos livros. **Em tempo real**, como no Stardew e no Minecraft: o jogador enfrenta os inimigos direto no mapa. | ✅ |
| Inimigos | Podem ser inimigos que aparecem nos livros. | ✅ |
| Bosses | Baseados nos livros. Formato decidido pela IA livro a livro (D-061). | ✅ |
| Perguntas | Desafios em que, para responder, é preciso lembrar do livro ou relê-lo. Formatos: múltipla escolha e entregar o item certo; nunca digitar. Errar: pergunta simples não pune; pergunta de boss ou importante tem punição leve (perde um pouco de vida ou reabre no dia seguinte). Dica: perguntas de memória não têm; perguntas de detalhe têm dica opcional com o capítulo. | ✅ |
| Diálogos | Baseados nos livros; podem ser a forma de fazer as perguntas. | ✅ |
| Histórias paralelas | Baseadas nos livros. Formato decidido pela IA livro a livro (D-061). | ✅ |
| Locais do mapa | Podem ser lugares que aparecem em livros. | ✅ |
| Progressão | Não há fases formais ("passar de fase" foi modo de dizer). Ver §5. | ✅ |
| Missões | Cumprir missões rende itens como as chaves das dimensões. Vêm de **várias fontes**: moradores da cidade, quadro de avisos, personagens dos livros. Um **diário** reúne as missões ativas. | ✅ |

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

✅ O jogador decide (D-019): sem pressa e sem prazo, ele divide o tempo como quiser entre cuidar da fazenda e avançar nos livros. A fome garante que a fazenda nunca seja ignorada por completo.

## 6. Mundo e história

| Tema | Status |
|---|---|
| Organização dos livros | ✅ Tudo num mesmo mundo, com **um bioma por livro** |
| Histórias que se cruzam | ✅ Desbloquear um lugar de um livro pode exigir algo de outro livro (ex.: o lugar do livro 1 só abre com algo do livro 2) |
| Dimensões | ✅ Livros **muito diferentes da vida real** (ex.: Harry Potter) ficam em uma **dimensão própria**, para onde o jogador viaja. Livros mais próximos da realidade viram bioma no mundo principal. A classificação de cada livro é feita na análise e registrada na ficha. |
| Como viajar até as dimensões | ✅ Por um **portal fixo no mundo principal**. Para entrar, é preciso um item (algo como uma **chave**) conseguido cumprindo **outras missões**. **Uma chave para cada dimensão**, cada uma conquistada numa missão diferente. |
| História principal | ✅ **Leve, de fundo:** um motivo simples para o protagonista estar ali e um objetivo final. Os livros continuam sendo o foco. |
| Ritmo da história | ✅ **Sem pressa e sem prazo.** A história não empurra o jogador; ele pode crescer e melhorar a fazenda à vontade e seguir a missão final quando quiser (como no Minecraft). |
| Motivo do protagonista | ✅ **Nenhum.** É um mundo normal e o protagonista simplesmente começa a se aventurar, como no Minecraft. |
| Objetivo final | ❓ Existe, mas ainda não foi definido. A decidir depois da análise dos primeiros livros. |
| Depois do objetivo final | ✅ **O jogo continua**, como no Minecraft depois do dragão: fazenda, exploração e livros novos seguem normalmente. O jogo **nunca tem um fim definitivo**, porque sempre vão entrar livros novos. |
| Cidade | ✅ Existe, com lojas (ex.: no centro), um **hospital/clínica** e **moradores**, que podem ou não fazer parte da história. Moradores têm **rotina** como no Stardew: andam pela cidade e as lojas abrem e fecham em horários certos. |
| Personagens dos livros na cidade | ✅ Podem aparecer na cidade e **ter um papel** ali. |
| Amizade / relacionamentos | ✅ **Não existe** sistema de amizade (nada de corações). Moradores servem para **conversar e vender**; no máximo, uma conversa dá uma **pista** (ex.: como achar a chave de um portal). |
| Dia e noite | ✅ Existem. Um dia completo dura **~15 a 20 minutos reais** (valor exato ajustado nos testes). A plantação avança com a passagem do tempo; dormir acelera a noite. |
| Calendário e estações | ✅ **Sem estações** e sem calendário na tela. Existe só uma **contagem de dias interna**, usada no save e em conquistas; não aparece na tela e não interfere no jogo. Sem estações, as plantas não dependem de época do ano. |

## 7. Arte e som

| Tema | Status |
|---|---|
| Pixel art no estilo do Stardew Valley | ✅ |
| Arte original (não é permitido usar arte do Stardew Valley) | ✅ obrigatório por direitos autorais |
| Quem produz a arte | ✅ **A IA**, delegado pelo dono: busca recursos nos sites que julgar melhores e gera por código o que faltar. Detalhes em `tecnico.md` §7. |
| Música e efeitos sonoros | ✅ **A IA cuida**: músicas e sons gratuitos de sites de recursos para jogos, mais efeitos simples gerados por código. Ver `tecnico.md` §7. |

## 8. Plataforma e tecnologia

| Tema | Status |
|---|---|
| PC | ✅ |
| Linguagem/engine | ✅ Godot 4 + GDScript (escolha delegada à IA; ver [`tecnico.md`](tecnico.md)) |
| Sistema operacional | ✅ Windows (o jogo abre como `.exe`) |
| Idioma | ✅ Tudo em **português**: textos, diálogos e menus. Os livros também são em português. |
| Save | ✅ O jogador salva **a qualquer momento, pelo menu**. |
| Atualizações | ✅ O dono vai atualizar o jogo de tempos em tempos (novos livros, melhorias). **O save nunca pode ser perdido numa atualização.** Ver `tecnico.md` §5. |
| Jogadores | ✅ **Um jogador só**, por enquanto. Multiplayer não está descartado para o futuro. |
| Controles | ✅ **Teclado e mouse**, como no Stardew no PC: WASD para andar, mouse para usar ferramentas e atacar. |

## 9. Livros do jogo

✅ A **primeira versão jogável** sai com **pelo menos uns 10 livros** (D-041); cerca de 15 no plano inicial. Livros sem PDF entram por pesquisa a partir do título (`conteudo-dos-livros.md` §3). Depois, o dono continua mandando livros novos e a IA cria e encaixa cada um no mundo e na história (D-040). O mundo é **expansível**: biomas novos se conectam ao mapa e dimensões novas entram pelo portal, sem quebrar saves (`tecnico.md` §5).

| Livro | Autor | Ficha | Status |
|---|---|---|---|
| — | — | — | Aguardando os PDFs |
