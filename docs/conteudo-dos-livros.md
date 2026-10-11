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
| Pergunta / diálogo-desafio | A resposta depende de algo que acontece ou é dito no livro | ❓ tentativas, punição por erro, formato (múltipla escolha, digitar, escolher item…) |
| Diálogo | Conversa com personagem ligada ao livro | ❓ personagens do livro viram NPCs? |
| Puzzle | Enigma montado a partir de algo do livro | ❓ formato |
| Inimigo | Criatura ou antagonista que existe no livro | ❓ depende do estilo de combate |
| Boss | Antagonista marcante do livro | ❓ depende do estilo de combate |
| Local do mapa | Lugar descrito no livro vira área do jogo | ❓ como os locais de livros diferentes se conectam |
| História paralela | Linha de história baseada em trama do livro | ❓ formato (missões, cadeia de diálogos…) |

### Dois níveis de dificuldade nas perguntas (a partir do que o dono descreveu)

| Nível | Critério | Exemplo de tipo de detalhe |
|---|---|---|
| **Memória** | Quem leu o livro consegue lembrar | Acontecimento central, personagem importante |
| **Releitura** | Exige voltar ao livro | Detalhe pequeno, ordem de eventos, nome secundário |

❓ Proporção entre os dois níveis e se a releitura é sempre opcional ou às vezes obrigatória.

## 2.1 Ligações entre livros ✅

Os livros não ficam isolados (D-015): cada livro tem seu bioma, mas desbloquear um lugar de um livro pode exigir algo vindo de outro livro. Por isso, toda ficha lista **possíveis ligações com outros livros** (personagens, objetos, temas ou lugares que conversam entre si), e o mapa de dependências entre livros fica registrado aqui conforme os livros chegam.

| Para desbloquear… (livro / lugar) | Precisa de… (livro / elemento) | Status |
|---|---|---|
| — | — | Aguardando livros |

## 3. Processo por livro (pipeline)

1. **Recebimento** — o dono envia o PDF. O PDF **não** entra no repositório (ver §5).
2. **Extração** — texto extraído do PDF e separado por capítulo.
3. **Leitura e ficha** — leitura completa e preenchimento de `livros/<nome-do-livro>.md` a partir de [`livros/_TEMPLATE.md`](../livros/_TEMPLATE.md): resumo por capítulo, personagens, lugares, criaturas, objetos, eventos, mistérios e detalhes bons para perguntas — sempre com capítulo/página de referência.
4. **Ganchos de jogo** — para cada elemento da ficha, qual tipo de conteúdo combina (tabela na própria ficha).
5. **Proposta** — lista do conteúdo que será criado com aquele livro. ❓ Se cada proposta passa pela aprovação do dono antes de virar jogo, ou se a IA segue direto.
6. **Implementação** — o conteúdo vira **arquivos de dados** (diálogos, perguntas, inimigos, mapas). Adicionar um livro novo não deve exigir mexer no código do jogo (ver [`tecnico.md`](tecnico.md)).
7. **Registro** — o livro entra na tabela do [`GDD.md`](GDD.md) §9 e o commit é feito.

## 4. Rastreabilidade

Todo conteúdo criado guarda internamente de onde veio: **livro, capítulo e página**. Isso serve para:
- conferir se a resposta de uma pergunta está correta;
- revisar conteúdo quando um livro for reanalisado.

❓ Se o jogo deve mostrar essa referência ao jogador (por exemplo, como dica) é decisão do dono.

## 5. Cuidados com direitos autorais

- **PDFs nunca vão para o repositório** (o `.gitignore` bloqueia). Só as fichas de análise.
- Citações dos livros dentro do jogo e das fichas: **curtas**. Perguntas e diálogos usam paráfrase sempre que possível.
- ✅ **Projeto pessoal** (D-014): personagens, lugares e criaturas dos livros podem ser usados livremente. Se um dia o projeto for publicado, esta regra precisa ser revista.
- O repositório é **público** (D-023). As fichas trazem análise e paráfrase, nunca trechos longos dos livros.
