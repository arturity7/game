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

## 3. Estrutura do repositório 🔵

```
/
├── README.md
├── CLAUDE.md               # regras de trabalho da IA
├── docs/                   # documentação de design
├── livros/                 # fichas de análise (NUNCA os PDFs)
└── game/                   # projeto Godot (criado na fase de código)
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

## 5. Git 🔵

- Um commit por alteração, com push logo em seguida (pedido do dono ✅).
- Mensagens em português com prefixo: `docs:`, `feat:`, `fix:`, `conteudo:` (conteúdo de livro), `arte:`.
- Arte e áudio pesados: Git LFS quando o projeto chegar lá.

## 6. Arte 🔵

Delegada à IA pelo dono (D-021). Abordagem:

1. **Base:** pacotes de pixel art gratuitos no estilo fazenda/aventura (fontes a avaliar: itch.io, OpenGameArt, Kenney), sempre conferindo a licença de cada pacote e registrando a origem em `game/assets/CREDITOS.md`.
2. **Sob medida:** o que for específico dos livros (inimigos, bosses, lugares, itens) é gerado por código (scripts Python que desenham os sprites pixel a pixel), mantendo a mesma paleta e escala da base.
3. **Consistência:** paleta de cores única definida no início, tiles de 16×16, personagens em 16×32.
4. **Provisório primeiro:** arte simples para prototipar; refinada depois.

Limitação: o ambiente de trabalho da IA pode não conseguir baixar arquivos de alguns sites. Nesse caso, a IA pede ao dono para baixar o pacote ou gera tudo por código.

## 7. Decisões técnicas para depois

Sistema de diálogo (próprio ou plugin), formato do save, organização de cenas, testes. Serão decididas quando a fase de código começar e dependem das respostas em [`perguntas-abertas.md`](perguntas-abertas.md).
