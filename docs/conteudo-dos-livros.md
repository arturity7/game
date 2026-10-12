# Como um livro vira conteúdo de jogo

> Este é o coração do projeto. Aqui fica o **processo** que a IA segue para transformar cada livro em conteúdo. As **regras de jogo** de cada tipo de conteúdo ainda dependem de decisões do dono (marcadas com ❓).

---

## 1. O que o dono do projeto definiu ✅

- Ele envia **PDFs de livros que já leu**.
- A IA **lê e analisa profundamente** cada livro.
- A IA escolhe **o que melhor se encaixa** no jogo e cria conteúdo a partir disso.
- Tipos de conteúdo citados: **puzzles, batalhas, bosses, perguntas, diálogos, histórias paralelas**.
- Exemplos dados pelo dono:
  - um **diálogo** em que, para responder, ele precise **lembrar do livro** ou até **relê-lo** para passar de fase;
  - um **inimigo** que também existe no livro;
  - um **local do mapa** que aparece em um livro.
- Tudo deve ser **articulado para funcionar junto**.

## 2. Tipos de conteúdo

| Tipo | O que significa "vir do livro" | Regras de jogo |
|---|---|---|
| Pergunta / diálogo-desafio | A resposta depende de algo que acontece ou é dito no livro | ✅ Formatos (D-028): **múltipla escolha** e **escolher/entregar o item certo** (ex.: "traga o objeto que o personagem X perdeu"). **Nunca digitar a resposta.** Errar: ver §2.1 |
| Diálogo | Conversa com personagem ligada ao livro | ✅ Personagens dos livros podem morar ou aparecer na cidade e ter um papel lá (D-033). Conversas podem dar **pistas** (ex.: onde achar a chave de um portal). Sem sistema de amizade. |
| Puzzle | Enigma montado a partir de algo do livro | IA decide o formato livro a livro, conforme a história (D-061) |
| Inimigo | Criatura ou antagonista que existe no livro | Combate em tempo real (D-027) |
| Boss | Antagonista marcante do livro | Combate em tempo real (D-027) |
| Local do mapa | Lugar descrito no livro vira área do jogo | ❓ como os locais de livros diferentes se conectam |
| História paralela | Linha de história baseada em trama do livro | IA decide o formato livro a livro, conforme a história (D-061) |

### Dois níveis de dificuldade nas perguntas (a partir do que o dono descreveu)

| Nível | Critério | Exemplo de tipo de detalhe |
|---|---|---|
| **Memória** | Quem leu o livro consegue lembrar | Acontecimento central, personagem importante |
| **Releitura** | Exige voltar ao livro | Detalhe pequeno, ordem de eventos, nome secundário |

❓ Proporção entre os dois níveis e se a releitura é sempre opcional ou às vezes obrigatória.

## 2.1 Errar uma pergunta ✅ (D-029)

A consequência depende do peso do desafio:

| Tipo de desafio | Ao errar |
|---|---|
| Pergunta simples | **Sem punição.** Tenta de novo. |
| Pergunta de boss ou de desafio importante | **Punição leve:** perde um pouco de vida, **ou** o desafio só reabre no dia seguinte (dando tempo de reler o livro). |

Ao criar cada pergunta, a IA registra o tipo dela e qual das punições leves se aplica.

## 2.2 Ligações entre livros ✅

Os livros não ficam isolados (D-015): cada livro tem seu bioma, mas desbloquear um lugar de um livro pode exigir algo vindo de outro livro. Por isso, toda ficha lista **possíveis ligações com outros livros** (personagens, objetos, temas ou lugares que conversam entre si), e o mapa de dependências entre livros fica registrado aqui conforme os livros chegam.

| Para desbloquear… (livro / lugar) | Precisa de… (livro / elemento) | Status |
|---|---|---|
| — | — | Aguardando livros |

## 3. Processo por livro (pipeline)

1. **Recebimento** — o dono envia o PDF **ou só o título** (D-042). O PDF **não** entra no repositório (ver §5).
2. **Extração ou pesquisa**
   - **Com PDF:** texto extraído e separado por capítulo.
   - **Sem PDF (só o título):** a IA pesquisa o máximo possível na internet (resumos, análises, wikis, guias de leitura) e monta a ficha a partir disso. Regras extras para não errar:
     - só vira pergunta o que for confirmado por **mais de uma fonte**;
     - perguntas ficam no nível **Memória** (fatos marcantes); detalhes miúdos ficam de fora, porque sem o texto não dá para garantir a exatidão;
     - a ficha registra as fontes usadas e marca `Fonte da análise: pesquisa`.
3. **Leitura e ficha** — leitura completa e preenchimento de `livros/<nome-do-livro>.md` a partir de [`livros/_TEMPLATE.md`](../livros/_TEMPLATE.md): resumo por capítulo, personagens, lugares, criaturas, objetos, eventos, mistérios e detalhes bons para perguntas — sempre com capítulo/página de referência.
4. **Ganchos de jogo** — para cada elemento da ficha, qual tipo de conteúdo combina (tabela na própria ficha).
5. **Criação direta** ✅ (D-035) — a IA decide e cria o conteúdo sozinha, **sem aprovação prévia**. O dono descobre tudo jogando, **sem spoilers**: nada de perguntas, respostas, inimigos ou ligações aparece no chat nem em mensagens de commit.
6. **Implementação** — o conteúdo vira **arquivos de dados** (diálogos, perguntas, inimigos, mapas). Adicionar um livro novo não deve exigir mexer no código do jogo (ver [`tecnico.md`](tecnico.md)).
7. **Registro** — o livro entra na tabela do [`GDD.md`](GDD.md) §9 e o commit é feito.

## 4. Rastreabilidade

Todo conteúdo criado guarda internamente de onde veio: **livro, capítulo e página**. Isso serve para:
- conferir se a resposta de uma pergunta está correta;
- revisar conteúdo quando um livro for reanalisado.

### Dicas para o jogador ✅ (D-044)

O dono pediu uma mistura de "com dica", "sem dica" e "dica só nas difíceis":

| Nível da pergunta | Dica |
|---|---|
| **Memória** (fatos marcantes) | Sem dica. |
| **Releitura** (detalhes) | Dica **opcional**: o jogador escolhe pedir e recebe o capítulo onde está a resposta. Quem quiser o desafio puro simplesmente não pede. |

Livros analisados só por pesquisa (sem PDF) têm apenas perguntas de nível Memória (ver §3), então não usam dica de capítulo.

## 5. Cuidados com direitos autorais

- **PDFs nunca vão para o repositório** (o `.gitignore` bloqueia). Só as fichas de análise.
- Citações dos livros dentro do jogo e das fichas: **curtas**. Perguntas e diálogos usam paráfrase sempre que possível.
- ✅ **Projeto pessoal** (D-014): personagens, lugares e criaturas dos livros podem ser usados livremente. Se um dia o projeto for publicado, esta regra precisa ser revista.
- O repositório é **público** (D-023). As fichas trazem análise e paráfrase, nunca trechos longos dos livros.
