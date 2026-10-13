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

Delegada à IA pelo dono (D-021). Abordagem:

1. **Base:** pacotes de pixel art gratuitos no estilo fazenda/aventura (fontes a avaliar: itch.io, OpenGameArt, Kenney), sempre conferindo a licença de cada pacote e registrando a origem em `game/assets/CREDITOS.md`.
2. **Sob medida:** o que for específico dos livros (inimigos, bosses, lugares, itens) é gerado por código (scripts Python que desenham os sprites pixel a pixel), mantendo a mesma paleta e escala da base.
3. **Consistência:** paleta de cores única definida no início, tiles de 16×16, personagens em 16×32.
4. **Provisório primeiro:** arte simples para prototipar; refinada depois.

**Som e música** (D-039): mesma abordagem. Músicas e sons gratuitos de sites de recursos para jogos (licença conferida e creditada em `CREDITOS.md`), mais efeitos simples (passos, golpes, coleta) gerados por código.

Limitação: o ambiente de trabalho da IA pode não conseguir baixar arquivos de alguns sites. Nesse caso, a IA pede ao dono para baixar o pacote ou gera tudo por código.

## 8. Protótipo 0 (12/10/2026) 🔵

Primeira versão de código, em `game/`. Ainda sem livros: só a base em que eles vão entrar.

| Parte | Como ficou |
|---|---|
| Versão do Godot | **4.3**, renderizador **Compatibilidade** (OpenGL 3), que roda em mais PCs com Windows |
| Tela | Resolução interna 480×270, ampliada em escala inteira; janela inicial de 1440×810 (3×); pixels sem filtro |
| Estado do jogo | `scripts/core/game_data.gd`: dados do jogador, do mundo e do progresso, separados dos nós visuais (§2) |
| Save | `scripts/core/save_codec.gd` (texto ↔ dados, versão e migrações) e `scripts/autoload/save_system.gd` (arquivo `user://save.json`). Campos que faltam recebem o padrão; chaves desconhecidas são guardadas e regravadas, nunca descartadas; save de versão mais nova é recusado sem estragar o arquivo; antes de migrar, cópia em `user://save.vN.bak` (§5) |
| Regras de sobrevivência | `scripts/core/survival.gd`: fome cai com o tempo e mais rápido com esforço; sem fome, a vida cai; vida zerada = desmaio, sem game over, perde uma porcentagem do dinheiro; relógio com dia de 18 minutos (D-037, D-047) |
| Valores de jogo | `content/config/balanceamento.json` (ajustável sem mexer no código) |
| Mapas | `content/mapas/<id>.json`: grade de caracteres + legenda; tipos de chão em `content/config/tiles.json` (atlas, sólido, água). O mapa é montado em código num `TileMapLayer` |
| Jogador | WASD/setas; na água nada mais devagar (D-070); colisão nos pés |
| Tela de jogo | Barras de fome e vida, hora e dinheiro; o dia não aparece (GDD §6); luz muda com a hora |
| Menu | Esc: Continuar, Salvar, Carregar, Sair (GDD §8) |
| Teclas | Registradas em código (`scripts/autoload/controles.gd`) |
| Arte | Provisória, gerada por `ferramentas/arte/gerar_placeholder.py` (§7) |
| Testes | `bash ferramentas/testar_jogo.sh`: testes sem tela (`tests/run_tests.gd`: save, saves antigos de `tests/saves/`, fome, vida, relógio, desmaio, mapa) e autoteste da cena com tela virtual (`tests/autoteste.gd`: andar, colisão, fome, salvar, carregar, nadar) |

Ainda não há: plantação, animais, inventário em uso, cidade, clínica (o desmaio acorda no ponto inicial), diálogos, perguntas, combate, conteúdo dos livros e exportação para `.exe`.

## 9. Decisões técnicas para depois

Sistema de diálogo e de perguntas (próprio, lendo os dados de `content/livros/`), organização das cenas por região e exportação para Windows. Serão decididas conforme o protótipo crescer.
