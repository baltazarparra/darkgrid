# caipora — Roguelike Brasileiro de Horror Folclórico

> Browser-first roguelike built with Godot 4.6 + GDScript.  
> Published on itch.io as an HTML5 build.

---

## 1. Visão do Produto

**caipora** é um roguelike 2D em pixel art ambientado no horror folclórico brasileiro.

Você joga como a **Caipora**, guardiã da mata, despertando em uma floresta corrompida onde os antigos pactos entre humanos, bichos, mortos, rios e encantados foram quebrados.

A cada movimento no grid, o mundo responde. A Caipora avança por trilhas tortas, clareiras queimadas, rios escuros, capelas abandonadas e vilas tomadas por superstição. Cada passo é uma escolha. Cada encontro pode virar caça, punição, fuga ou encantamento.

Diferente de um herói tradicional, a Caipora não está ali para salvar a humanidade. Ela é uma entidade antiga, ambígua e perigosa: protetora dos animais, senhora dos rastros, espírito de assovio, armadilha e vingança. Sua missão é descobrir o que adoeceu a mata — e decidir se os humanos ainda merecem permanecer nela.

### Tom

**GORE / TERROR / SANGRENTO**

Inspirado pela tensão estratégica de roguelikes clássicos, pela estranheza ritual de *Sol Cesto* e pela atmosfera opressiva de *Bloodborne*. caipora troca o gótico europeu por um horror brasileiro de terra molhada, cipó, fumaça, olho brilhando no escuro e canto vindo do rio.

### Mecânica Central

O combate usa um sistema de **timing**:
- Pressione **Espaço** no frame correto para desferir um **ataque crítico** (2x–3x de dano).
- Pressione **Espaço** no frame correto para **esquivar perfeitamente** (zero dano) e **contra-atacar**.

Toda ação tem feedback visceral: screen shake, partículas de sangue, hit-stop e sons de impacto.

### Escopo do MVP

- 1 jogável: **Caipora**
- 1 inimigo: criatura folclórica (ex: Caboclo d'Água, Boto corrompido, ou entidade genérica da mata)
- 1 arena: clareira queimada ou capela abandonada na floresta
- Sistema de timing implementado e satisfatório

**Fora do escopo do MVP:**
- Steam / desktop builds
- Mobile builds
- Gamepad support
- Multiplayer
- Cloud saves
- Leaderboards
- Achievements
- Música (SFX apenas no MVP)

---

## 2. Plataforma Alvo

- **Primária:** Web / HTML5 (itch.io)
- **Renderizador:** Godot 2D (Compatibility mode para estabilidade WebGL)
- **Resolução:** 1280×720 (escalável)

---

## 3. Tech Stack

| Camada | Escolha |
|--------|---------|
| Engine | Godot 4.6.3 |
| Linguagem | GDScript |
| Renderização | 2D, OpenGL Compatibility |
| Distribuição | itch.io HTML5 export |
| Controle de Versão | Git |
| Agent Tools | `@coding-solo/godot-mcp` (MCP server) |

---

## 4. Arquitetura do Jogo

### 4.1 Loop de Gameplay

```
[Menu Principal]
    ↓
[Exploração]  ← grid-based, turn-based (floresta)
    ↓  (pisar no tile de arena)
[Combate na Arena] ← action / timing-based
    ↓  (vitória / morte)
[Recompensas / Morte]
    ↓
[Hub / Meta-progressão]
    ↓
[Exploração]  ← próxima arena
```

**Exploração:**
- Movimento grid-based (4 direções)
- Turn-based: jogador move um tile → criaturas movem
- Visibilidade limitada / fog of war
- Pisar em um tile de arena dispara combate
- Ambientes: trilha torta, clareira queimada, rio escuro, capela abandonada

**Combate na Arena:**
- Action em tempo real (não turn-based)
- Jogador e inimigo têm cooldowns de ataque
- Inimigo telegrafa ataques com cue visual + janela de wind-up
- Jogador pressiona **Espaço** durante a janela de cue para esquivar + contra-atacar
- Jogador pressiona **Espaço** durante sua própria janela de ataque para crítico
- Errar o timing = resultado normal (sem penalidade, sem bônus)

### 4.2 Sistemas Core

| Sistema | Responsabilidade |
|---------|------------------|
| `TurnManager` | Ordem de turnos na exploração |
| `ArenaManager` | Spawna inimigos, gerencia estado da arena, condições de vitória/derrota |
| `TimingSystem` | Detecta presses de espaço dentro das janelas de cue, emite hit/miss |
| `CombatSystem` | Aplica dano, lida com morte, dispara feedback |
| `FeedbackSystem` | Screenshake, partículas, hit-stop, sound cues |
| `MetaProgression` | Unlocks entre runs (persistido em `user://`) |

### 4.3 Estrutura de Entidades

```
Caipora (Player)
├── MovementController (exploração)
├── CombatActor (arena)
│   ├── Health
│   ├── AttackCooldown
│   └── TimingWindow
└── FeedbackReceiver

Criatura (Enemy)
├── CombatActor
│   ├── Health
│   ├── AttackPattern (telegraph → wind-up → strike)
│   └── TimingWindow (para esquiva do jogador)
└── FeedbackReceiver
```

---

## 5. Estrutura de Diretórios

```
caipora/
├── assets/
│   ├── sprites/          # todos os sprites: chars, inimigos, tiles, itens (.png)
│   ├── audio/
│   │   └── sfx/          # efeitos sonoros (.wav, jsfxr/sfxr)
│   ├── fonts/            # fonte pixelada (.ttf / .otf)
│   └── licenses/         # licenças CC0 e atribuições
├── scenes/
│   ├── ui/               # menus, HUD, telas
│   ├── exploration/      # mapa grid, fog, camadas de tile
│   ├── arena/            # arenas de combate
│   └── shared/           # componentes reutilizáveis (barra de vida, etc)
├── scripts/
│   ├── core/             # autoloads: GameState, SignalBus, MetaProgression
│   ├── systems/          # TimingSystem, CombatSystem, FeedbackSystem
│   ├── entities/         # Caipora, Criatura (classes base)
│   ├── exploration/      # lógica de grid, TurnManager
│   ├── arena/            # ArenaManager, padrões de ataque
│   └── utils/            # helpers, constants
├── tests/
│   └── unit/             # testes unitários GUT
├── docs/                 # documentos de design
└── export/               # saída do build HTML5 (gitignored)
```

---

## 6. Padrões de Código

### 6.1 Naming

| Tipo | Convenção | Exemplo |
|------|-----------|---------|
| Classes | PascalCase | `CombatActor`, `TimingSystem` |
| Variáveis / Funções | snake_case | `attack_damage`, `start_timing_window()` |
| Constantes | UPPER_SNAKE_CASE | `MAX_HEALTH`, `TIMING_WINDOW_FRAMES` |
| Signals | passado snake_case | `health_changed`, `timing_hit` |
| Arquivos | snake_case | `combat_actor.gd`, `arena_manager.gd` |

### 6.2 Layout de Script

```gdscript
class_name CombatActor
extends CharacterBody2D

# ─── Exports ───────────────────────────────────────
@export var max_health: int = 100
@export var attack_damage: int = 10

# ─── Signals ───────────────────────────────────────
signal health_changed(new_health: int)
signal died

# ─── Constants ─────────────────────────────────────
const TIMING_WINDOW_FRAMES := 6

# ─── State ─────────────────────────────────────────
var current_health: int
var is_timing_window_open: bool = false

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
    current_health = max_health

# ─── Public API ────────────────────────────────────
func take_damage(amount: int) -> void:
    current_health = clampi(current_health - amount, 0, max_health)
    health_changed.emit(current_health)
    if current_health <= 0:
        died.emit()

# ─── Private ───────────────────────────────────────
func _open_timing_window() -> void:
    is_timing_window_open = true
```

### 6.3 Princípios

- **Composition over inheritance:** Use `@export` nodes e componentes, evite árvores de herança profundas.
- **Signals para desacoplamento:** Sistemas se comunicam via `SignalBus` autoload ou signals diretos, não referências diretas.
- **State machines:** Use padrão `StateMachine` para Caipora e Criaturas (explorar → combater → morto).
- **Sem números mágicos:** Defina constantes no topo do script ou em `constants.gd` autoload.
- **Typed everything:** Use static typing (`-> void`, `-> int`, `: int`) em todas as funções e variáveis.
- **Uma classe por arquivo:** Não empilhe múltiplas classes em um único `.gd`.

---

## 7. Arquitetura de Cenas

### 7.1 Autoloads (`Project > Project Settings > Autoloads`)

| Nome | Script | Propósito |
|------|--------|-----------|
| `GameState` | `scripts/core/game_state.gd` | Tela atual, estado da run, pause |
| `SignalBus` | `scripts/core/signal_bus.gd` | Signals globais (comunicação desacoplada) |
| `MetaProgression` | `scripts/core/meta_progression.gd` | Unlocks, currency, stats entre runs |
| `FeedbackSystem` | `scripts/systems/feedback_system.gd` | Screenshake global, partículas, som |

### 7.2 Padrões de Scene Tree

- **Cena de Arena:** `ArenaManager` (Node2D) possui o background, spawna instâncias de `Caipora` e `Criatura`.
- **Cenas de UI:** Baseadas em CanvasLayer, ancoradas ao viewport, usam nós `Control` para layout.
- **Componentes reutilizáveis:** HealthBar, DamageNumber, TimingCue são cenas instanciáveis (`PackedScene`) exportadas como `@export var`.

---

## 8. MCP & Agent Harness

O projeto usa `@coding-solo/godot-mcp` instalado e configurado.

### 8.1 MCP Tools Disponíveis

| Tool | Quando usar |
|------|-------------|
| `create_scene` | Criar novo arquivo `.tscn` |
| `add_node` | Adicionar nó a uma cena existente |
| `save_scene` | Salvar alterações em uma cena |
| `run_project` | Rodar o jogo e capturar output |
| `get_debug_output` | Ler stdout/stderr do jogo rodando |
| `stop_project` | Parar o processo do jogo |
| `launch_editor` | Abrir o editor Godot |
| `get_godot_version` | Verificar versão do Godot instalado |

### 8.2 Workflow do Agente

1. **Orient:** Ler `PLAN.md`, checar `git status`, ler `AGENTS.md`.
2. **Verify:** Rodar smoke test (`run_project`) antes de fazer mudanças.
3. **Implement:** Uma task por sessão. Usar MCP tools para criação de cenas.
4. **Test:** Rodar smoke test + GUT tests. Se houver mudanças visuais, validar com screenshot.
5. **Update:** Commit com mensagem descritiva. Marcar task completa em `PLAN.md` se aplicável.

---

## 9. Build & Export Pipeline

### 9.1 Desenvolvimento Local

```bash
# Rodar o jogo (requer display :0, WSLg funciona)
~/.local/bin/godot --path /home/baltz/darkgrid

# Rodar headless (para operações de cena via MCP)
~/.local/bin/godot --headless --path /home/baltz/darkgrid --script <script>

# Rodar testes GUT
~/.local/bin/godot --headless --path /home/baltz/darkgrid -s res://addons/gut/gut_cmdln.gd
```

### 9.2 Exportar para HTML5

```bash
# O preset de export deve estar configurado no Godot primeiro
~/.local/bin/godot --headless --path /home/baltz/darkgrid --export-release "Web" export/index.html
```

### 9.3 Deploy no itch.io

1. Zipar conteúdo de `export/`.
2. Fazer upload na página do projeto no itch.io.
3. Marcar "This file will be played in the browser" para `index.html`.

---

## 10. Testes & Validação

### 10.1 Camadas

| Camada | Tool | Gatilho |
|--------|------|---------|
| Smoke test | `run_project` | Após cada mudança |
| Unit tests | GUT (Godot Unit Test) | Antes do commit |
| Validação visual | Screenshot | Antes do commit |
| Playtest | Manual | Nos boundaries de milestone |

### 10.2 Critérios de Aceitação por Milestone

- **Fase 1:** Caipora se move no grid. Câmera segue. Não crasha.
- **Fase 2:** Arena carrega. Cue de timing aparece. Espaço registra hit/miss. Dano aplica.
- **Fase 3:** Criatura ataca com telegraph. Boss tem padrão único. Condições de vitória/derrota funcionam.
- **Fase 4:** Meta-progressão unlocks persistem. Polish: partículas, sons, screenshake.
- **Fase 5:** Export HTML5 roda no browser. Página do itch.io carrega e joga.

---

## 11. Milestones

### Fase 1: Grid + Movimento da Caipora
- [ ] Cena de exploração grid-based
- [ ] Personagem Caipora com movimento 4-direcional
- [ ] Câmera segue
- [ ] Tile de arena dispara combate

### Fase 2: Arena + Sistema de Timing
- [ ] Cena de arena com background
- [ ] Caipora combat actor (vida, dano)
- [ ] Cue de timing UI (barra visual + janela)
- [ ] Detecção de espaço dentro da janela
- [ ] Ataque crítico no timing perfeito
- [ ] Feedback: screenshake + partículas + som

### Fase 3: Criatura + Boss
- [ ] Criatura combat actor
- [ ] Telegraph de ataque (animação de wind-up + cue)
- [ ] Esquiva perfeita + contra-ataque no timing
- [ ] Boss com padrão de ataque único
- [ ] Condição de vitória (morte da criatura) / derrota (morte da Caipora)

### Fase 4: Meta-Progressão + Polish
- [ ] Cena de hub entre runs
- [ ] Sistema de unlocks (personagens, modifiers)
- [ ] Save persistente (`user://`)
- [ ] Polish de partículas
- [ ] Sound design (sfx para cada ação)
- [ ] Tuning de screenshake
- [ ] Hit-stop frames

### Fase 5: Export + Publish
- [ ] Preset de export HTML5 configurado
- [ ] Teste de export no browser
- [ ] Página do itch.io criada
- [ ] Upload e verificação

---

## 12. Diretrizes de Assets

- **Sprites:** CC0 da Kenney.nl. Escolha **um único pack** para consistência visual. 16×16 ou 32×32, .png, fundo transparente. **Sem sprites gerados por IA** para o jogo principal.
- **Áudio:** Gerar com jsfxr/sfxr. Exportar como .wav. Curto, punchy, under 100KB cada. **Sem música no MVP.**
- **UI:** Usar nós nativos do Godot (`Button`, `Panel`, `Label`, `ProgressBar`). Sem sprite sheets customizadas para UI.
- **Fontes:** Uma fonte pixelada com licença permissiva (ex: Kenney Fonts ou "Press Start 2P").
- **Licenças:** Copiar a licença de cada pack de assets para `assets/licenses/`.

### Paleta de Horror Folclórico Brasileiro

| Uso | Cor | Hex |
|-----|-----|-----|
| Fundo / Noite | Preto azulado | `#0d1117` |
| Terra / Trilha | Marrom avermelhado | `#3d1f1f` |
| Folhagem / Musgo | Verde podre | `#1a2f1a` |
| Sangue / Dano | Vermelho vivo | `#8b0000` |
| Destaque / Cue | Âmbar / Fogo | `#ff6b00` |
| Texto | Branco sujo | `#c9d1d9` |

---

## 13. Notas

- **Browser-first:** Evite shaders pesados, texturas grandes, física complexa. Teste tempo de load frequentemente.
- **Janelas de timing:** Comece generoso (12 frames), ajuste baseado no feel do playtest.
- **Feedback é rei:** Cada ação deve ser satisfatória. Priorize juice sobre conteúdo.
- **Save often:** Use commits do git como checkpoints. O agente deve commitar após cada task bem-sucedida.
- **Tom:** Nunca suavize o horror. A floresta é hostil. A Caipora é perigosa. O sangue é real.
