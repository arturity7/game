# Técnico — engine, linguagem e arquitetura

> O dono do projeto delegou a escolha de linguagem à IA. Itens marcados 🔵 são propostas da IA que podem mudar quando a fase de código começar.

---

## 1. Engine e linguagem: Godot 4 + GDScript ✅

Requisitos do dono (D-022): abrir no **Windows** e ter **save**. Entrega: executável `.exe` para Windows.

### Por quê

| Critério | Godot 4 |
|---|---|
| Pixel art 2D | Suporte nativo a tiles, sprites animados, câmera com pixel perfeito e escala inteira |
| Custo | Gratuita e open source (licença MIT), sem royalties |
| Exportar para PC | Windows, Linux e Mac a partir do mesmo projeto |
| Git | Cenas e recursos são arquivos de texto — fáceis de versionar e de a IA editar |
| Velocidade de desenvolvimento | Editor visual + linguagem simples; protótipos rápidos |
| Comunidade | Grande, com muitos tutoriais de jogos estilo Stardew |

### Alternativas consideradas

| Opção | Por que não foi a escolhida |
|---|---|
| MonoGame + C# (o que o Stardew usa) | Não tem editor visual; tudo (mapas, colisão, UI) precisa ser programado do zero. Mais lento. |
| Unity + C# | Mais pesada para 2D simples; histórico de mudanças de licença. |
| Godot + C# | Viável, mas GDScript é mais simples e mais integrado ao editor. |

## 2. Princípio de arquitetura: conteúdo em dados, não em código

O jogo vai crescer **livro por livro**. Então:

- **Código** = sistemas genéricos: movimento, fome, plantação, animais, combate, motor de diálogos, motor de perguntas, transição de mapas, salvamento.
- **Dados** = tudo que vem dos livros: diálogos, perguntas e respostas, inimigos, bosses, puzzles, mapas.

Adicionar um livro = adicionar uma pasta de dados. Sem mexer no código.

### Pensando num multiplayer futuro 🔵

O jogo é single-player por enquanto (D-038), mas o dono não descartou multiplayer. Sem escrever nada de rede agora, o código mantém o **estado do jogo separado da tela** (dados do mundo, inventário e progresso não ficam dentro dos nós visuais) e toda mudança de estado passa por funções centrais. Isso não custa mais agora e evita reescrever tudo se o multiplayer vier.

## 3. Estrutura do repositório 🔵

```
/
├── README.md
├── CLAUDE.md               # regras de trabalho da IA
├── docs/                   # documentação de design
├── livros/                 # fichas de análise (NUNCA os PDFs)
└── game/                   # projeto Godot (protótipo 0 em 12/10/2026)
    ├── project.godot
    ├── scenes/             # cenas (.tscn)
    ├── scripts/            # código (.gd)
    ├── assets/             # arte e som
    └── content/
        └── livros/
            └── <nome-do-livro>/
                ├── dialogos.json
                ├── perguntas.json
                ├── inimigos.json
                └── mapas/
```

## 4. Resolução e escala 🔵

- Tiles de **16×16 pixels**, como no Stardew.
- Resolução interna baixa (ex.: 480×270) ampliada em **escala inteira** para 1920×1080 (4×). Mantém o pixel nítido.

## 5. Save compatível entre atualizações ✅ (requisito do dono, D-031)

O jogo vai receber atualizações e **nenhuma atualização pode quebrar ou apagar o save existente**. Como garantir 🔵:

- **Save fora da pasta do jogo:** fica na pasta de dados do usuário do Windows (`user://` do Godot, em `%APPDATA%`). Substituir o `.exe` não toca no save.
- **Save versionado:** todo arquivo de save guarda o número da versão do formato (`save_version`).
- **Migração automática:** ao abrir um save antigo, o jogo aplica, em ordem, as migrações de cada versão até a atual (`v1 → v2 → v3…`). Nunca se descarta dado que não se reconhece.
- **IDs estáveis:** todo item, missão, livro, área e pergunta tem um ID fixo (ex.: `livro_x.pergunta_03`). Um ID publicado **nunca muda nem é reaproveitado**; se algo sai do jogo, o ID fica reservado.
- **Conteúdo novo entra "desbloqueável":** um livro novo aparece no save antigo como conteúdo ainda não visitado, sem exigir novo jogo.
- **Backup automático:** antes de migrar, o jogo copia o save antigo (`save.bak`).
- **Teste obrigatório:** cada atualização é testada carregando saves de versões anteriores guardados no repositório (`game/tests/saves/`).
- **Formato legível:** save em JSON, fácil de inspecionar e consertar se algo der errado.

## 6. Git 🔵

- Um commit por alteração, com push logo em seguida (pedido do dono ✅).
- Mensagens em português com prefixo: `docs:`, `feat:`, `fix:`, `conteudo:` (conteúdo de livro), `arte:`.
- Arte e áudio pesados: Git LFS quando o projeto chegar lá.

## 7. Arte 🔵

Delegada à IA pelo dono (D-021). Estilo pedido pelo dono em 13/10/2026: **parecido com Pokémon (GBA) e Stardew Valley** — pixel art vista de cima, cores vivas, contorno escuro, personagem baixinho de cabeça grande. Nada é copiado desses jogos: desenho e paleta são próprios.

1. **Tudo gerado por código** em `ferramentas/arte/`:
   - `pixel.py`: paleta em rampas (do escuro ao claro), contorno automático, ruído fixo por posição e o desenho de terreno em grade dupla.
   - `gerar_arte.py`: terreno, objetos, personagem, plantação, ícones de itens e interface. `python3 ferramentas/arte/gerar_arte.py` regrava os PNGs em `game/assets/sprites/`.
   - `fonte.py`: a fonte de pixel própria **Leaf Pixel** (formato BMFont: `game/assets/fontes/leaf_pixel.fnt` + `.png`), com acentos do português.
2. **Terreno em grade dupla:** a grama é a base (com variações: tufos e flores em manchas), com **manchas grandes de grama mais escura e mais clara** (borda pontilhada) para quebrar o verde liso, como no chão do Stardew (`tiles.json` → `grama.manchas`: ruído suave por célula, escala, semente e limiar). Terra, caminho, água (animada, com espuma e barranco) e o solo arado e molhado são desenhados por cima, com bordas arredondadas. Cada camada fica deslocada meio tile; cada tile olha as 4 células nos seus cantos (máscara TL=1, TR=2, BL=4, BR=8). São 16 desenhos por terreno, mais variações do tile cheio para não repetir.
3. **Objetos com profundidade:** casa (96×112), árvores (32×48 e 48×72), arbustos, pedras e cercas que se ligam às vizinhas; enfeites soltos na grama (mato alto, flores, cogumelos, pedrinhas) que não bloqueiam e somem se a célula for arada. Quem está mais embaixo na tela fica na frente (y-sort): o jogador passa atrás da copa das árvores e do telhado. Em volta do mapa há mata fechada só de enfeite. As sombras no chão são semitransparentes e sem contorno (o contorno automático só pega pixels opacos). Mato e flores balançam com um farfalhar quando o jogador passa por cima.
4. **Personagem:** 16×32, 4 direções × 4 quadros de caminhada + 1 pose de usar ferramenta (vira para a célula e para por um instante), com sombra. Nadando, só o tronco aparece, com ondinhas.
5. **Plantação:** quadros de 16×32 por estágio (4 estágios por cultura); o último mostra o fruto.
6. **Interface:** tela de abertura com o logo sobre a fazenda (câmera passeando; Continuar, Novo jogo, Sair); painéis de madeira com pergaminho (9-patch), espaços da barra de itens, ícones de vida, fome, sol, lua e moeda. Fonte Leaf Pixel no tamanho 13 (1 pixel do desenho = 1 pixel da tela) e 26 nos títulos; a Pixelify Sans (licença OFL) fica de reserva para caracteres que a Leaf Pixel não tem.
7. **Noite e efeitos:** à noite as janelas da casa acendem (luz quente com `PointLight2D` + vidros acesos, `objetos.json` → `luzes` e `noite`). Ferramentas balançam sobre a célula, com terra ou gotas voando; a colheita sobe e some (`scripts/world/efeitos.gd`). **Vida no cenário** (`scripts/world/ambiente.gd`, só ao ar livre, só desenho): borboletas de dia, folhas caindo das árvores com `"folhas": true` e vaga-lumes à noite (numa camada própria, para brilharem no escuro).
8. **Conferir:** `bash ferramentas/fotos_jogo.sh <pasta>` tira fotos da cena (casa, plantação, lago nadando, noite, menu) em 480×270 e ampliadas 3×.
9. **Conteúdo dos livros** (inimigos, bosses, lugares, itens): mesmo processo, mesma paleta e escala (tiles de 16×16, personagens de 16×32).

Pacotes prontos de terceiros só entram se o dono pedir, com a licença registrada em `game/assets/CREDITOS.md`.

**Som e música** (D-039): por enquanto tudo gerado por código em `ferramentas/som/gerar_sons.py` (WAV de 22050 Hz em `game/assets/sons/`; a música é convertida para OGG pelo ffmpeg, para o .zip do jogo caber no envio de 30 MB): passos, enxada, regar, encher o regador, plantar, colher, comer, clique, troca de item, dormir, salvar, e a música da fazenda (composição própria em estilo de console portátil: ondas quadradas e triangulares, Fá maior, 96 bpm, cerca de 80 s em laço). Tocados pelo autoload `Som`; volumes em `balanceamento.json` (`volume_musica_db`, `volume_efeitos_db`). Alternativa: músicas e sons gratuitos de sites de recursos para jogos (licença conferida e creditada em `CREDITOS.md`), mais efeitos simples (passos, golpes, coleta) gerados por código. Limitação: o ambiente de trabalho da IA pode não conseguir baixar arquivos de alguns sites; nesse caso, a IA pede ao dono para baixar o pacote ou gera tudo por código.

## 8. Protótipos 0 e 1 (12 e 13/10/2026) 🔵

Primeira versão de código, em `game/`. Ainda sem livros: só a base em que eles vão entrar.

| Parte | Como ficou |
|---|---|
| Versão do Godot | **4.3**, renderizador **Compatibilidade** (OpenGL 3), que roda em mais PCs com Windows |
| Tela | Resolução interna 480×270, ampliada em escala inteira; janela inicial de 1440×810 (3×); pixels sem filtro |
| Estado do jogo | `scripts/core/game_data.gd`: dados do jogador, do mundo e do progresso, separados dos nós visuais (§2) |
| Save | `scripts/core/save_codec.gd` (texto ↔ dados, versão e migrações) e `scripts/autoload/save_system.gd` (arquivo `user://save.json`). Campos que faltam recebem o padrão; chaves desconhecidas são guardadas e regravadas, nunca descartadas; save de versão mais nova é recusado sem estragar o arquivo; antes de migrar, cópia em `user://save.vN.bak` (§5) |
| Regras de sobrevivência | `scripts/core/survival.gd`: fome cai com o tempo e mais rápido com esforço; sem fome, a vida cai; vida zerada = desmaio, sem game over, perde uma porcentagem do dinheiro; relógio com dia de 18 minutos (D-037, D-047) |
| Valores de jogo | `content/config/balanceamento.json` (ajustável sem mexer no código) |
| Mapas | `content/mapas/<id>.json`: grade de caracteres + legenda. Cada caractere é um tipo de chão (`content/config/tiles.json`) ou um objeto (`content/config/objetos.json`: arte, pegada, colisão, se dá para dormir). Objetos maiores que uma célula (a casa) ficam na lista `objetos`. `saidas` = células que levam a outro mapa (com o ponto de chegada); `porta` (em `objetos.json`) deixa uma célula da pegada passável. Interiores usam um `fundo` desenhado (paredes = chão sólido), `noite` e `luzes`. O desenho é montado em `scripts/world/mundo.gd` (§7) |
| Jogador | WASD/setas; na água nada mais devagar (D-070); colisão nos pés |
| Plantação | Enxada ara grama ou terra (não debaixo de objetos); regador de 20 usos, enche na água; sementes; a planta só cresce com o solo molhado; o lago irriga até 4 tiles (D-053); colhe com o botão direito (`scripts/core/fazenda.gd`, `content/config/culturas.json`) |
| Inventário | 30 espaços, barra de 10 (teclas 1–0 ou roda do mouse); `scripts/core/inventario.gd`, `content/config/itens.json`. Ferramentas no botão esquerdo, mirando a célula sob o mouse (se ao alcance) ou a da frente |
| Casa por dentro | Entra pela porta da casa (passagem com a tela escurecendo); cômodo com cama, mesa, cadeiras, estante de livros e vaso (`content/mapas/casa.json`, fundo desenhado em `ferramentas/arte/interiores.py`). À noite, a janela escurece e a vela da mesa acende |
| Comer e dormir | Botão direito com comida na mão enche a fome; botão direito na **cama** dorme (só das 18h às 6h; o tempo corre 30× até as 6h) |
| Pesca | Vara de pescar (Mercado); a linha cai na água do mouse ou na primeira água à frente; espera, mordida com "!" e um instante para puxar (`scripts/world/pesca.gd`, sorteio em `scripts/core/peixes.gd`). Peixes por mapa em `peixes` (D-073) |
| Mapas ao norte | Colina do Portal (`colina.json`: portal apagado, menires, trilhos) e Lago Walden (`walden.json`); trilhos são um tipo de chão com desenho simples (`tile` em `tiles.json`); a mata em volta de cada mapa pode ser de outro objeto (`mata`, ex.: pinheiro) (D-074) |
| Cidade | `content/mapas/cidade.json`, a leste da fazenda: estrada de calçada, postes que acendem à noite, praça com chafariz. **Mercado** (8h–18h; porta trancada fora do horário): botão direito na vendedora (por cima do balcão) abre a loja (`scripts/ui/loja.gd`; clique compra/vende 1, Shift compra 5 ou vende tudo; dados em `content/config/lojas.json` e preços em `itens.json`). **Clínica**: quem desmaia acorda lá. **Forja do Ferreiro** (9h–17h): ferramentas melhores (enxada larga e regador grande, que pegam três células em linha). Moradores parados com sprite próprio (`npcs` no mapa) (D-072) |
| Save | Versão 2 (inventário em espaços e canteiros), com migração da versão 1 |
| Tela de jogo | Painéis de madeira: vida e fome, hora (sol ou lua) e dinheiro, barra de itens, avisos; o dia não aparece (GDD §6); luz muda com a hora |
| Abertura | Logo sobre a fazenda; Continuar (se houver save), Novo jogo, Sair (`scripts/ui/tela_inicial.gd`) |
| Menu | Esc: Continuar, Salvar, Carregar, Sair (GDD §8) |
| Teclas | Registradas em código (`scripts/autoload/controles.gd`) |
| Arte | Gerada por código, estilo Pokémon/Stardew (§7) |
| Testes | `bash ferramentas/testar_jogo.sh`: testes sem tela (`tests/run_tests.gd`: save, saves antigos de `tests/saves/`, migração, fome, vida, relógio, desmaio, mapa e objetos, arte citada nos dados, inventário, plantação) e autoteste da cena com tela virtual (`tests/autoteste.gd`: andar, colisão com a casa, fome, salvar, carregar, nadar, arar, regar, plantar, colher, comer, dormir) |
| Exportação | `bash ferramentas/exportar_windows.sh` gera `game/build/LeafAndLore.exe` (um arquivo só, com os dados dentro; preset em `game/export_presets.cfg`). O `.exe` não vai para o Git |

Ainda não há: animais, machado e corte de árvores, moradores andando (rotina), combate, portal e a maior parte do conteúdo dos livros (o primeiro livro jogável é a Carta a Meneceu, §9).

## 9. Conteúdo dos livros no jogo (formato dos dados) 🔵

Cada livro é uma pasta `game/content/livros/<id>/` lida inteira pelo autoload `Config` (livro novo = pasta nova, sem mexer no código):

| Arquivo | O que tem |
|---|---|
| `livro.json` | id, título, autor, ficha de origem |
| `perguntas.json` | `texto`, `opcoes` (a de índice `certa` é a correta; embaralhadas na tela, a não ser com `"embaralhar": false`), `nivel` (`memoria`/`releitura`; releitura tem `dica` com o lugar no livro, D-044), `peso` (`simples`/`importante`; importante tem `punicao` `vida` ou `amanha`, D-029) e `ref` (de onde veio, conteudo-dos-livros.md §4) |
| `dialogos.json` | conversas: `quem`, `inicio` (lista de `{se, ir}`) e `nos` com `fala`, `efeitos`, `escolhas`, `pergunta` (+ `certo`, `errado`, `bloqueada`), `ramos` e `ir`. Condições e efeitos estão descritos em `scripts/core/dialogo.gd` |
| `missoes.json` | nome e descrição que aparecem no diário |
| `itens.json` | itens do livro (somam aos itens básicos) |
| `conquistas.json` | medalhas do livro |

- **Onde aparecem:** os moradores ficam em `npcs` dos mapas (com `dialogo`); placas e inscrições são objetos com `texto`.
- **Avanço do jogador** (`scripts/core/progresso.gd`, em `progresso` do save): flags, estado das missões (`missao:<id>` = `ativa`/`feita`), respostas (`acertou`, `tentativas`, `reabre_dia`) e conquistas (dia em que foi ganha). Campos novos dentro de `progresso`, sem mudar a versão do save.
- **Tela:** caixa de conversa no pé da tela com nome, texto letra a letra, escolhas e perguntas (`scripts/ui/caixa_dialogo.gd`; Espaço/Enter/E passam, 1–4 escolhem). Diário com missões e conquistas na tecla J ou Tab (`scripts/ui/diario.gd`). E também conversa (o mesmo que o botão direito).
- **Testes:** `tests/run_tests.gd` confere todas as conversas (nós, perguntas, itens, missões e conquistas citados existem), todas as saídas entre mapas e segue a história de cada livro do começo ao fim.

## 10. Decisões técnicas para depois

Sistema de diálogo e de perguntas (próprio, lendo os dados de `content/livros/`), organização das cenas por região e ícone do `.exe`. Serão decididas conforme o protótipo crescer.
