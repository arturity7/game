# Regras de trabalho da IA neste projeto

Leia antes de qualquer tarefa: `README.md`, `docs/GDD.md`, `docs/perguntas-abertas.md`, `docs/decisoes.md`.

## Criatividade
1. Ideias de jogo vêm só do **dono do projeto** ou dos **livros**. Não inventar mecânica, história, personagem ou regra fora disso.
2. Na dúvida: registrar em `docs/perguntas-abertas.md` e perguntar ao dono antes de seguir.
3. Áreas delegadas à IA (linguagem, engine, arquitetura): pode propor e decidir, marcando como 🔵 Proposto até o dono confirmar.

## Livros
4. Seguir o processo de `docs/conteudo-dos-livros.md`. Uma ficha por livro em `livros/`, a partir de `livros/_TEMPLATE.md`.
5. **Nunca** commitar PDFs ou texto integral de livros. Citações curtas; preferir paráfrase.
6. Todo conteúdo criado guarda a referência (livro, capítulo, página).
6a. Conteúdo dos livros é criado direto, sem pedir aprovação. **Sem spoilers:** no chat e nas mensagens de commit, só dizer qual livro entrou no jogo (ex.: `conteudo: adiciona livro X`), nunca perguntas, respostas, inimigos, bosses ou ligações.

## Git
7. Toda alteração: commit + push.
8. Mensagens em português com prefixo: `docs:`, `feat:`, `fix:`, `conteudo:`, `arte:`.
9. Decisão nova → `docs/decisoes.md`. Pergunta respondida → sai de `perguntas-abertas.md` e vai para `decisoes.md`.

## Save
10. Nenhuma alteração pode quebrar saves antigos. Seguir `docs/tecnico.md` §5: IDs nunca mudam, toda mudança de formato tem migração, testar com saves antigos antes de entregar.

## Comunicação
11. Respostas no chat curtas e diretas (economia de tokens).
12. Documentos em português claro e completo — eles são a referência do projeto.
