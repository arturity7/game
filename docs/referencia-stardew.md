# Referência: como o Stardew Valley funciona

> Estudo de engenharia reversa **por fontes públicas** (wiki oficial da comunidade e documentação de modding).
> Não descompilamos nem copiamos código ou arte do Stardew Valley: isso violaria os termos de uso e os direitos autorais. Estudamos o **comportamento** dos sistemas e reimplementamos do nosso jeito.
>
> A coluna "Nosso jogo" só indica se o dono do projeto já falou sobre o sistema. Não é decisão de design.

---

## 1. Tecnologia

| Item | Stardew Valley | Nosso jogo |
|---|---|---|
| Linguagem | C# | 🔵 proposta em `tecnico.md` |
| Framework | XNA, depois migrado para MonoGame | 🔵 proposta em `tecnico.md` |
| Tiles | 16×16 pixels, desenhados com zoom (padrão 4×) | Mesmo princípio |
| Mapas | Editados no Tiled, formato xTile (`.tbin`/`.tmx`) | Mesmo princípio (editor de tiles) |
| Conteúdo | Dados separados do código (itens, NPCs, diálogos, eventos em arquivos de dados) | Mesmo princípio — essencial para o conteúdo dos livros |
| Salvamento | Só ao dormir, no início do dia seguinte | ❓ |

## 2. Tempo e dia

- O dia vai das **6h às 2h** (20 horas de jogo).
- **10 minutos de jogo = 7 segundos reais.** Um dia completo dura cerca de **14 minutos reais**.
- O tempo **pausa** em menus, diálogos e cenas (no modo single-player).
- Escurece mais cedo no outono e no inverno.
- **4 estações de 28 dias.**
- Às **2h** o personagem desmaia: se estiver fora de casa, perde 10% do dinheiro (máx. 1.000g) e acorda em casa.

**Nosso jogo:** ❓ se terá relógio, calendário e estações.

## 3. Energia e vida

- Energia máxima inicial: **270**. Ferramentas gastam energia; armas não.
- Vida inicial: **100**.
- Energia **0** = exausto: anda mais devagar, usa ferramentas mais devagar. Em **−15** desmaia.
- Comida restaura energia e vida. Não existe fome: comer é opcional, só para recuperar energia/vida.

**Nosso jogo:** ✅ fome existe (diferença principal): cai com o tempo, esforço acelera, e fome zerada tira vida aos poucos, como no Minecraft. ✅ vida existe. ✅ **não existe energia**: só fome e vida.

## 4. Sono

- Dormir até **meia-noite** restaura energia e vida por completo.
- Depois da meia-noite, quanto mais tarde, menos restaura (cerca de 75% à 1h, 50% perto das 2h).
- Ir dormir exausto corta a recuperação pela metade.
- Sempre acorda às 6h.

**Nosso jogo:** ✅ diferente do Stardew: dormir não é obrigatório, não há horário limite nem desmaio. Dormir só faz a noite passar mais rápido (ajuda a plantação), como no Minecraft.

## 5. Plantação

Fluxo: preparar o solo com enxada → plantar semente → regar todo dia (chuva e irrigadores regam sozinhos) → a planta cresce em X dias → colher. Algumas plantas produzem de novo após a colheita. Plantas morrem na troca de estação, salvo as de várias estações.

**Nosso jogo:** ✅ plantação existe. ❓ regras.

## 6. Animais

- Ficam em galinheiro ou estábulo.
- Saem para pastar em dias de sol se a porta estiver aberta; voltam por volta das 17h.
- Comem capim do pasto ou feno do silo.
- Carinho diário e alimentação aumentam a amizade, que melhora os produtos (ovo, leite, lã…).

**Nosso jogo:** ✅ animais existem. ❓ quais e como funcionam.

## 7. Combate

- Em **tempo real**, visto de cima, com armas corpo a corpo (espadas, adagas, porretes) e estilingue.
- Principal área de combate: as minas, com andares e monstros que mudam por profundidade.

**Nosso jogo:** ✅ batalhas e bosses existem. ❓ estilo (tempo real ou outro).

## 8. Diálogos e relacionamentos

- Caixa de texto com retrato do personagem, com respostas de escolha em alguns momentos.
- Amizade medida em corações; presentes e conversas aumentam.
- Eventos (cenas) disparam ao entrar em certos lugares com certo nível de amizade.
- NPCs têm rotina por horário e dia da semana.

**Nosso jogo:** ✅ diálogos existem e podem ser desafios. ❓ relacionamentos, rotinas, NPCs.

## 9. Outros sistemas do Stardew

Pesca, mineração, culinária, artesanato, lojas e dinheiro, missões do quadro de avisos, coleções (museu, centro comunitário), habilidades com níveis, casamento, multiplayer.

**Nosso jogo:** ❓ nenhum desses foi citado ainda.

---

## Fontes

- [Day Cycle — Stardew Valley Wiki](https://stardewvalleywiki.com/Day_Cycle)
- [Energy — Stardew Valley Wiki](https://stardewvalleywiki.com/Energy)
- Demais itens: conhecimento geral sobre o jogo; conferir na [Stardew Valley Wiki](https://stardewvalleywiki.com) antes de usar números exatos.
