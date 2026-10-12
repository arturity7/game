# O mundo do jogo — mapa, regiões, dimensões e chaves

> ⚠️ Área com spoilers. Proposta da IA para o desenho do mapa e as ligações entre os livros (D-065), feita depois da análise do lote 1 (20 arquivos, 24 livros). Tudo aqui pode mudar quando o dono pedir ou quando novos livros chegarem; IDs já criados nas fichas não mudam (`docs/tecnico.md` §5).

## 1. Estrutura geral

- **Mundo principal**: a fazenda e a cidade no centro; em volta, os biomas dos livros próximos da vida real (D-017). Os livros de não ficção que não têm paisagem própria viram **lugares** dentro da cidade, da zona rural, da montanha ou da costa.
- **Três dimensões**, para onde se viaja pelo **portal fixo** (D-017), cada uma com a sua **chave**, conquistada numa missão diferente do mundo principal (D-048):
  - **Além da Névoa** (`percy_1.dimensao.alem_da_nevoa`) — os cinco volumes de Percy Jackson.
  - **O Labirinto** (`maze_runner_1.local.labirinto`) — os três volumes de Maze Runner.
  - **O Inferno** (`lewis_cartas.dimensao.inferno`) — Cartas de um Diabo a seu Aprendiz.
- **Sem estações** (D-067): o frio e o calor vêm da região. O mundo principal tem uma **área fria** (a Montanha e a costa de Abbot) e uma **área quente** (o deserto do sul e o vale do Eufrates).

## 2. O mapa do mundo principal

```
                         [ Costa de Abbot ]
                          (fria, mar bravo)
        [ Bosque e Lago Walden ] [ A Montanha — área fria ]
                 |      (Colina do Portal)      |
[ Estepe e aldeia ] — [ Planícies de trigo ] — [ FAZENDA ] — [ CIDADE ] — [ Costa e praias ] — [ Costa do Canal ]
   (Tolstói)            (Mother's Rest)            |        (Jardim na beira)
                                          [ Margrave — Sul úmido ]
                                                   |
                             [ Deserto do sul e a cidade das luzes ] — [ Vale do Eufrates ]
```

| Região | Livro | ID | Posição | Clima | Vizinhos |
|---|---|---|---|---|---|
| A fazenda | — (sistema) | — | Centro | Ameno | Cidade, Margrave, planícies, Walden |
| A cidade | Vários (ver §3) | — | Leste da fazenda | Ameno | Fazenda, Jardim, costa |
| O Jardim | Carta a Meneceu | `epicuro.local.jardim` | Beira oeste da cidade, entre a cidade e a fazenda | Ameno | Cidade, fazenda |
| Margrave | Dinheiro Sujo | `reacher_1.bioma.margrave` | Sul da fazenda | Úmido e quente | Fazenda, deserto do sul |
| As planícies de trigo | Make Me | `reacher_20.bioma.planicies_trigo` | Oeste da fazenda | Aberto, seco | Fazenda, estepe |
| A estepe e a aldeia | De Quanta Terra Precisa um Homem? | `tolstoi.bioma.estepe` | Extremo oeste | Planície de terra preta | Planícies de trigo |
| Bosque e Lago Walden | Walden | `walden.local.bosque_lago` | Norte da fazenda | Mata e lagos | Fazenda, Montanha, Colina do Portal |
| A Montanha (área fria) | Nada Pode Me Ferir, Nunca É Hora de Parar, Conforto na Escuridão, Respire, Seja Útil | — (lugares, ver §3) | Norte | Frio permanente (D-067) | Walden, costa de Abbot |
| A costa de Abbot | Acerto de Contas | `reacher_7.bioma.costa_abbot` | Nordeste | Fria, ventosa, mar bravo | Montanha, costa e praias |
| A costa e as praias | Nada Pode Me Ferir, Inabalável, Respire, Conforto na Escuridão | — (lugares, ver §3) | Leste da cidade | Mar | Cidade, costa de Abbot, Costa do Canal |
| A Costa do Canal | Dunkirk | `dunkirk.local.costa_canal` | Extremo leste, do outro lado do mar | Mar com dois lados | Costa e praias |
| O deserto do sul | Bad Luck and Trouble | `reacher_11.bioma.california_deserto` | Sul de Margrave | Quente e seco | Margrave, vale do Eufrates |
| O vale do Eufrates | O Homem Mais Rico da Babilônia | `babilonia.bioma.vale_eufrates` | Sudeste | Deserto quente com canais | Deserto do sul |

**Por que essa ordem.** Os biomas mais parecidos com a fazenda ficam perto dela (Margrave, os campos e a cidadezinha rural; as planícies de trigo; o bosque e os lagos de Walden). As áreas extremas ficam nas bordas: o frio no norte (a Montanha dos livros de resistência e a costa fria de Abbot), o calor no sul (o deserto da Califórnia e o Eufrates, dois desertos lado a lado), o mar no leste (as praias de treino, depois a Costa do Canal "do outro lado"), a planície sem fim no oeste (o trigo dá na estepe dos basquires, com a mesma terra preta e o mesmo céu aberto).

**A ferrovia.** Três livros têm trilhos: a parada de trem de Mother's Rest (`reacher_20.local.parada_trem`), a casa do Sargento ao lado da linha (`goggins_nunca.local.casa_sargento`) e a ferrovia ao sul do lago Walden. Proposta: uma só linha liga as planícies, a zona rural da fazenda e Walden, e serve de caminho entre o oeste e o norte.

## 3. Lugares sem bioma próprio

| Lugar | Livro | ID | Onde fica |
|---|---|---|---|
| A Academia do Tatame (com a Parede dos Mestres e a ampliação no teatro abandonado) | Conforto na Escuridão, Respire, Inabalável | `rickson_conforto.local.academia_tatame`, `rickson_respire.local.parede_mestres`, `inabalavel.local.teatro_abandonado` | Cidade |
| O clube (olimpíada anual, arco do pedágio) | Inabalável, Nunca É Hora de Parar | `inabalavel.local.clube`, `goggins_nunca.local.arco_pedagio` | Cidade, à beira-mar |
| A Pirâmide | Inabalável | `inabalavel.local.piramide` | Cidade |
| A forja do Ferreiro, o quiosque, o parque da cerca, o abrigo | Seja Útil | `seja_util.local.quiosque`, `seja_util.local.parque_cerca`, `seja_util.local.abrigo` | Cidade |
| O Mercado (Arkad e Mathon também atendem lá) | O Homem Mais Rico da Babilônia | `babilonia.npc.arkad`, `babilonia.npc.mathon` | Cidade |
| O Laboratório Mental | Nunca É Hora de Parar | `goggins_nunca.local.laboratorio_mental` | Fazenda (galpão abandonado) |
| A casa do Sargento | Nunca É Hora de Parar | `goggins_nunca.local.casa_sargento` | Zona rural, junto à ferrovia |
| O ancião da árvore e o fazendeiro "Será?" | Inabalável | `inabalavel.npc.anciao_arvore`, `inabalavel.npc.fazendeiro_sera` | Zona rural |
| O acampamento do Corredor | Nada Pode Me Ferir | `goggins_nada.local.acampamento_corredor` | Pé da Montanha |
| A trilha em oito | Nada Pode Me Ferir | `goggins_nada.local.trilha_oito` | Montanha (área fria) |
| O mirante do vale | Nada Pode Me Ferir | `goggins_nada.local.mirante_vale` | Alto da Montanha |
| O segundo pico | Seja Útil | `seja_util.local.segundo_pico` | Visto do alto da Montanha |
| A Base dos Bombeiros da Floresta, a floresta zumbi, a montanha das falsas cumeeiras | Nunca É Hora de Parar | `goggins_nunca.local.base_bombeiros`, `goggins_nunca.local.floresta_zumbi`, `goggins_nunca.local.montanha_falsos_picos` | Montanha (área fria) |
| O Campo de Treino da Montanha (rio de neve, bambuzal, pinheiro da águia) | Conforto na Escuridão, Respire | `rickson_conforto.local.campo_montanha` | Montanha (área fria) |
| O rio largo | Respire | `rickson_respire.local.rio_largo` | Entre Walden e a Montanha |
| A praia de treino (sino, capacetes, trincheira de lama) | Nada Pode Me Ferir | `goggins_nada.local.praia_treino` | Costa, junto ao clube |
| A pedra da praia | Inabalável | `inabalavel.local.pedra_praia` | Costa |
| A costa da capela e a praia do achado | Respire | `rickson_respire.local.costa_capela`, `rickson_respire.local.praia_achado` | Costa |
| O mar bravo com dunas | Conforto na Escuridão | — | Costa, perto da costa de Abbot |

## 4. Lugares que estavam "a definir"

| Lugar | Livro | ID | Decisão |
|---|---|---|---|
| A trilha da floresta úmida (terra vermelha, três postos de água) | Nada Pode Me Ferir | `goggins_nada.local.trilha_floresta_umida` | Em **Margrave**: o Sul úmido de terra vermelha |
| O pântano | Nunca É Hora de Parar | `goggins_nunca.local.pantano` | Em **Margrave** |
| A travessia quente (do vale fervente ao portal da montanha) | Nada Pode Me Ferir | `goggins_nada.local.travessia_quente`, `goggins_nada.evento.travessia_quente` | No **deserto do sul**: sai da parte mais baixa e quente do deserto e sobe até a borda da Montanha pelo leste. Deixa de ser condicional |
| O deserto de rochas vermelhas | Nunca É Hora de Parar | `goggins_nunca.local.rochas_vermelhas` | No **deserto do sul**, ao lado da travessia quente |
| O livro de natação | Nada Pode Me Ferir | `goggins_nada.item.livro_natacao` | **Continua condicional**: depende de o jogo ter natação, que ainda não foi decidido (ver Q45 em `docs/perguntas-abertas.md`) |

## 5. Dimensões e chaves

| Dimensão | Livros | Do outro lado do portal | Chave | Por quê |
|---|---|---|---|---|
| Além da Névoa (`percy_1.dimensao.alem_da_nevoa`) | `percy_1` a `percy_5` | A estrada de Long Island na noite da tempestade; depois, o hub do acampamento (`percy_1.local.colina_meio_sangue`) | **A chave de Além da Névoa**: Epicuro a entrega quando o jogador termina de levar as três cartas (`epicuro.missao.carta_meneceu`, `epicuro.missao.carta_pitocles`, `epicuro.missao.carta_herodoto`) | O Jardim é o lugar grego do mundo principal, e as cartas ensinam a não ter medo dos deuses e da morte (as sombras do medo de `carta-a-meneceu.md` §10): quem perdeu esse medo pode visitar um mundo de deuses vivos |
| O Labirinto (`maze_runner_1.local.labirinto`) | `maze_runner_1` a `maze_runner_3` | A Caixa (`maze_runner_1.local.caixa`), que leva à Clareira; os volumes 2 e 3 seguem pelo dormitório; a volta ao mundo principal, no fim, é pelo portal | **A chave do Labirinto**: o Corredor a entrega no fim do treinamento da área fria (`goggins_nunca.missao.saltadora`, `goggins_nunca.puzzle.descida_arvore`, `goggins_nunca.minijogo.pouso_x`), quando diz que "a estrada do sucesso é um labirinto" (`goggins_nunca.dialogo.labirinto`) e manda o jogador procurar o próximo | No Labirinto, quem desenha o mapa são os Corredores (`maze_runner_1.mecanica.corredor`); a chave vem do Corredor da Montanha, depois de uma prova de resistência |
| O Inferno (`lewis_cartas.dimensao.inferno`) | `lewis_cartas` | A ladeira suave, sem curvas e sem placas (`lewis_cartas.puzzle.estrada_suave`), que desce até os escritórios | **A chave do Inferno**: fica com o jogador depois de vencer o Diabo atrás do forno (`tolstoi.boss.diabo_forno`), resistindo à ganância | Os dois livros mostram o Diabo agindo pelas tentações do dia a dia (`tolstoi-quanta-terra.md` §11): só quem já resistiu a uma tentação pode descer e voltar |

**O portal fixo.** Proposta: na **Colina do Portal**, um morro baixo entre a fazenda e o bosque de Walden, ao alcance do jogador desde o começo do jogo. O portal fica apagado até a primeira chave; cada chave acende o caminho para a sua dimensão. As três missões das chaves ficam em pontas diferentes do mapa (a cidade, a Montanha, o extremo oeste), para que o jogador explore antes de viajar.

**Ordem.** Não há ordem obrigatória entre as dimensões (D-018: progressão por desbloqueio). Dentro de cada dimensão, os volumes seguem a ordem dos livros.

## 6. Ligações entre livros

- Cada ficha tem a sua tabela de ligações (§11). As ligações que estavam "a confirmar" foram revisadas em 12/10/2026 e agora apontam para IDs que existem.
- **Séries que continuam**: Percy Jackson (cinco volumes na mesma dimensão), Maze Runner (três volumes na mesma dimensão), Jack Reacher (quatro livros em quatro biomas diferentes do mundo principal), Goggins (os dois livros no mesmo Corredor da Montanha), Rickson Gracie (os dois livros nos mesmos lugares de treino).
- **Pontes entre o mundo principal e as dimensões**: as chaves (§5); o Jardim grego e os deuses de Percy; o Corredor da Montanha e os Corredores do Labirinto; o Diabo de Tolstói e o Inferno de Lewis.

## 7. Candidatos a objetivo final (para a Q4b)

Ideias de estrutura para o dono escolher; nenhuma inventa história nova:
1. **As três dimensões**: o objetivo final é terminar as três dimensões (o último volume de cada uma) e voltar ao mundo principal.
2. **Uma missão que junta os livros**: uma última missão no mundo principal que pede algo de cada livro terminado, no estilo das "histórias que se cruzam".
3. **Outro objetivo**, definido pelo dono.

## 8. Pendências

- **Q4b** (objetivo final): pergunta ao dono.
- **Q45** (natação): pergunta ao dono; decide o livro de natação, a volta a nado da pedra da praia e a travessia do rio largo.
