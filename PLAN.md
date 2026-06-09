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
- ~~Cloud saves~~ → backend pronto pós-MVP (Supabase, schema `caipora`); falta integrar no cliente Godot
- ~~Leaderboards~~ → backend pronto pós-MVP (Supabase, Edge Function `caipora-api`); falta integrar no cliente Godot
- Achievements
- ~~Música (SFX apenas no MVP)~~ → adicionada pós-MVP: maracatu adaptativo + ambiência + stingers (ver §12)

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
[Combate na Arena] ← turnos + action command de timing
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
- Combate por turnos com **action commands de timing** (no estilo *Legend of Dragoon* e *Clair Obscur: Expedition 33*) — não é ação em tempo real. O turno alterna entre jogador e inimigo; dentro de cada turno o jogador acerta o frame/janela correto para crítico ou esquiva.
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
2. **Verify:** Rodar `make smoke` antes de fazer mudanças.
3. **Implement:** Uma task por sessão. Usar MCP tools para criação de cenas.
4. **Test:** Rodar `make gate` (smoke + GUT). Se houver mudanças visuais, validar com screenshot.
5. **Update:** Commit com mensagem descritiva. Marcar task completa em `PLAN.md` se aplicável.

---

## 9. Build & Export Pipeline

### 9.1 Desenvolvimento Local

Os comandos do harness vivem no `Makefile` (fonte única). Rode da raiz do repo.
Sobrescreva o binário com `make test GODOT=/caminho/para/godot`.

```bash
make smoke    # sobe headless ~50 frames e sai (smoke test)
make test     # roda o gate GUT (tests/unit)
make export   # build HTML5 reproduzível em export/
make gate     # smoke + test (antes de cada commit)

# Rodar o jogo com display (WSLg fornece :0)
~/.local/bin/godot --path .
```

### 9.2 Exportar para HTML5

```bash
# O preset "Web" já está configurado em export_presets.cfg
make export
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

### Fase 1: Grid + Movimento da Caipora ✅
- [x] Cena de exploração grid-based
- [x] Personagem Caipora com movimento 4-direcional
- [x] Câmera segue
- [x] Tile de arena dispara combate

### Fase 2: Arena + Sistema de Timing ✅
- [x] Cena de arena com background
- [x] Caipora combat actor (vida, dano)
- [x] Cue de timing UI (barra visual + janela)
- [x] Detecção de espaço dentro da janela
- [x] Ataque crítico no timing perfeito
- [x] Feedback: screenshake + partículas + som

### Fase 3: Criatura + Boss ✅
- [x] Criatura combat actor
- [x] Telegraph de ataque (animação de wind-up + cue)
- [x] Esquiva perfeita + contra-ataque no timing
- [x] Boss com padrão de ataque único
- [x] Condição de vitória (morte da criatura) / derrota (morte da Caipora)

### Fase 4: Meta-Progressão + Polish ✅
- [x] Cena de hub entre runs
- [x] Sistema de unlocks (personagens, modifiers)
- [x] Save persistente (`user://`)
- [x] Polish de partículas
- [x] Sound design (sfx para cada ação)
- [x] Tuning de screenshake
- [x] Hit-stop frames

### Fase 5: Export + Publish 🚧
- [x] Preset de export HTML5 configurado (`export_presets.cfg`, auditado)
- [x] Build HTML5 reproduzível via CLI (`make export`, 39MB, zero erros)
- [ ] Teste de export no browser (Chrome + Firefox)
- [ ] Página do itch.io criada
- [ ] Upload e verificação

### Fase 6: Grid Roguelike ✅
- [x] Inimigos no mapa
- [x] Sistema de turnos
- [x] Mapa de 3 salas

### Fase 3 Final: Curupira + Fog of War + Encerramento ✅
- [x] Novos Screens: EXPLORATION_PHASE3, ARENA_PHASE3, ENDING
- [x] Upgrades nível 3: forca_3 (Fúria Ancestral, 8 frags) e saude_3 (Raiz Viva, 12 frags)
- [x] phase_reached=3 ao derrotar Boitatá (upgrades disponíveis antes de entrar na Fase 3)
- [x] Fog of War: CanvasLayer + shader radial, raio 3 tiles (fog_reveal.gdshader)
- [x] Mapa "Ventre da Mata": corredores estreitos, sem fogo
- [x] Inimigo Assombração: espectro 12 HP, aura fantasmal cinza-azulada
- [x] Timing −0.15s na Fase 3 via _phase_window() em runtime (PHASE3_TIMING_REDUCTION)
- [x] Boss Curupira: 20 HP, pés-para-trás, aura verde-mata, padrões RASTRO (←→←→, 2.5x) e ASSOBIO (3x, janela mínima)
- [x] Diálogo pré-boss: "ninguém te deixou..." / "isso pouco importa agora"
- [x] EndingScreen: sequência cinematográfica com fade, texto, silhueta procedural andando pela floresta
- [x] Mensagem final: "a floresta vive... por enquanto"

### Fase 7: Identidade Visual & Padronização ✅
- [x] Paleta como fonte única (`constants.gd`) — ~60 `Color()` centralizados
- [x] Design system de UI (`theme.tres`): Button/Panel/Label/ProgressBar, bordas duras
- [x] Telas padronizadas (menu, game over, win, hub) com type scale consistente
- [x] Atmosfera unificadora: vinheta + grão (`atmosphere.gdshader`, sem screen-read)
- [x] Floresta amazônica: tiles redesenhados + flora (samambaia/cipó)
- [x] Vida ambiente decorativa: vaga-lumes (CPUParticles2D) + insetos (sem interação)
- [x] Personagens identificáveis: Caipora 64×64 (cabelo de fogo, olhos brilhando,
      cobertura de folhas/cipó, chicote de cipó, pés normais pra frente, imponente —
      maior que o caçador; o pé-pra-trás é do Curupira, parente, NÃO da Caipora),
      caçador 48×48 (chapéu/espingarda), bruxo 48×48 (capuz/cajado/gema)
- [x] Geradores algorítmicos: `gen_tiles.py`, `gen_chars.py`; captura: `screenshot.gd`

### CHAMA — Espada com elemento fogo ✅
- [x] Depois da espada (`forca_3`, "Raiz-de-Ira"), a cada **10 monstros comuns** derrotados há
      **1 sorteio** (`MetaProgression.register_kill_for_chama()`); contador `kills_toward_chama`
      **acumulado entre runs** (persistido no save).
- [x] Chance de drop num único ponto de tuning: `MetaProgression.CHAMA_DROP_CHANCE` (default 0.5).
- [x] Ao ganhar, recebe a **CHAMA no lugar do fragmento** daquela morte (`arena_manager._on_actor_died`);
      `has_chama` é **permanente** (salvo). HUD mostra popup "CHAMA!" (`SignalBus.chama_gained`).
- [x] Efeito fogo: **+1 dano** (`get_damage_bonus()` soma `CHAMA_DAMAGE_BONUS`), **partículas de chama
      somadas às douradas** e **sprite flamejante** `weapon_forca3_fogo.png`
      (gerador `scripts/gen_weapon_forca3_fogo.py`) — em `weapon_visual.gd`, visível na **arena e na
      exploração** (ambas via `WeaponVisual.attach_to`).
- [x] Testes: `tests/unit/test_chama.gd`.

### Fase 8: Geração Procedural de Mapas 🚧

Hoje os 4 mapas são `MAP_LAYOUT` estáticos (strings 26×18) hardcoded em cada
`exploration_phaseN_manager.gd`. Objetivo: **todo mapa gerado proceduralmente a
cada run**, usando os estáticos como referência de feel (mesma topologia,
contagem de inimigos e densidade de hazard). Princípio: **estrutura garantida +
variação** — a topologia macro garante salas/boss/saída/conectividade; o
procedural varia detalhes, hazards e posicionamento.

Arquitetura: gerador PURO e determinístico (seed por run) separado da
apresentação, com pipeline em camadas (topologia → sala do boss → validação por
flood-fill → hazards → entidades) e gate de invariantes em GUT. O char-grid
(`W/F/E/R/S`) continua sendo a IR — plugável nos managers sem fricção.

- [x] **Etapa 0 — Fundação testável** (sem mudança no jogo):
  - `scripts/exploration/map_config.gd` (`MapConfig`, Resource): params por fase
    (topologia OPEN/CORRIDOR, contagem de inimigos, hazards, baú/chave, fog),
    factory `for_phase()` codificando a identidade das Fases 1–4.
  - `scripts/exploration/generated_map.gd` (`GeneratedMap`): container de dados
    (grid + spawn + saída + inimigos + baú/chave) com `reachable_from()` (BFS).
  - `scripts/exploration/map_generator.gd` (`MapGenerator`): gerador puro
    determinístico — OPEN (região aberta + pilares blue-noise + alcova do boss)
    e CORRIDOR (drunkard's walk). RNG semeado próprio (Fisher-Yates manual, não
    `Array.shuffle()` global). Regenera em falha de conectividade.
  - `tests/unit/test_map_generator.gd`: 10 testes de invariante × 4 fases × 10
    seeds (determinismo, conectividade saída↔spawn, paridade de contagem de
    inimigos, 1 boss, placement válido/único/fora do spawn, densidade de hazard,
    variação por seed, baú/chave condicionais). ~4676 asserts, gate verde.
- [x] **Etapa 1 — Plugar na Fase 1**:
  - `GameState.run_seed` (sorteado em `start_run()`) + `map_seed_for_phase(fase)`
    (mistura determinística): mapa novo por run, mas **idêntico ao voltar da arena**
    (mesma run+fase → mesmo mapa); inimigos derrotados seguem fora via
    `defeated_enemy_ids` (IDs determinísticos). Sem cache em `GameState` — regen
    determinística basta.
  - `exploration_manager.gd` (Fase 1) consome `GeneratedMap` no lugar de
    `MAP_LAYOUT`/`ENEMY_DEFS`/`DECO_DEFS`/`*_POS`. Fonte-única-de-verdade de
    walkability: `_is_walkable` lê o mapa gerado (mesma fonte que pinta o TileMap).
  - Decorações: posições no gerador (`decoration_count`), tipos sorteados da
    paleta `MapObject.DECO_TYPES` por RNG semeado (estáveis na volta da arena).
  - **Regras de placement** (pedido do design): contagem por fase 4/4/6/6; baú e
    chave sempre longe do jogador e longe um do outro; boss sempre na metade mais
    distante; sempre 1–2 guardas perto do boss.
  - Fases 2–4 **intactas** (ainda estáticas) — jogo segue jogável ponta-a-ponta.
  - Testes: `test_map_generator.gd` (15 invariantes) + `test_exploration_phase1.gd`
    (integração da cena). Gate verde: 120 testes / ~10.9k asserts.
- [x] **Etapa 2 — Topologia CORRIDOR + Fase 3** (com fog of war):
  - `exploration_phase3_manager.gd` consome `GeneratedMap` (CORRIDOR), preservando
    fog of war, aura de fogo, `_find_safe_spawn`, dano de fogo 2, roteamento
    Curupira/Assombração + diálogo e o `CanvasModulate` verde. Contagem 6.
  - **Correção:** a Fase 3 estática TEM fogo (o PLAN dizia "sem fogo"). Procedural
    mantém fogo (`hazard_chars=["R"]`) **+ garantia universal de rota até o boss
    sem fogo forçado** (`_ensure_clean_path`: limpa hazards sobre uma rota se a
    única passagem cruzar fogo).
  - `has_exit=false`: Fase 3 não tem tile `E` — progride ao **derrotar o Curupira**
    (boss na célula mais profunda). Boss carrega `boss_type` → sprite/aura certos.
  - Decoração modesta temática (raízes/musgo/cipó) via paleta `DECO_THEME`.
  - Tuning CORRIDOR: junções ocasionais (`CORRIDOR_JUNCTION_CHANCE`) p/ salinhas e
    rotas alternativas.
  - Testes: +invariantes (boss_type, rota limpa de fogo, `has_exit`/tile `E`) e
    `test_exploration_phase3.gd` (integração). Gate verde: 125 testes / ~10.8k asserts.
- [x] **Etapa 3 — Manager único + rollout Fases 2 e 4**:
  - Um único `exploration_manager.gd` dirigido por `@export var phase` substitui os
    4 managers (930 → ~430 linhas; deletados `exploration_phase{2,3,4}_manager.gd`).
    Comportamento por fase é DADO: `MapConfig.for_phase()` (geração) + `_build_profile()`
    (apresentação/rota: cenas de boss/regular, tela de arena, diálogo, e flags
    `hazard_damage`/`aura`/`safe_spawn`/`ambient_life`/`keep_position`/`has_fog`/
    `enhance_fire`/`exit_marker`/`phase_reached_on_enter`/paleta de decoração).
    As 4 `.tscn` apontam pro script único com `phase = N`; cor do `CanvasModulate`
    fica na cena.
  - **Fases 2 e 4 viram procedurais.** P4 `has_exit=false` (progride ao derrotar o
    Saci → ENDING; corrigida a inconsistência latente). Decoração modesta temática
    de fogo/morte (troncos queimados/ossos/árvores mortas) nas P2/P4 via `DECO_FIRE`.
  - **Sem regressão:** preservado fogo 1 (P1) vs 2 (P2/3/4), baú/chave só P1, fog só
    P3, manter-posição só P1, `phase_reached=2` ao entrar na P2, auras tocha/fogo,
    spawn seguro P3/P4. Fases 1 e 3 com comportamento idêntico.
  - Testes: integração das 4 fases (`test_exploration_phase{1,2,3,4}.gd`). Gate verde:
    smoke OK, 127 testes / ~9.4k asserts.
- [x] **Etapa 4 — Polish** (fecha o épico):
  - **Transição em toda troca de cena.** Autoload `SceneTransition` (CanvasLayer
    layer 100 — abaixo do `PortraitGuard` 128, acima do HUD) mascara o hard-cut do
    `change_scene_to_file` com fade preto curto (out 0.22s / in 0.28s). `GameState`
    resolve a cena em `_scene_path_for()` (ponto único de roteamento) e delega.
    Flavor **"a mata se reorganiza..."** só ao entrar numa exploração de fase NOVA
    (run start / avanço); volta de combate p/ a mesma fase e telas de menu usam fade
    limpo. `process_mode = ALWAYS` (roda pausado) e engole cliques durante a transição.
  - **Tuning de densidade guiado por preview.** Confirmado via `preview_map.gd` que
    P1/P2/P4 (OPEN) escalam bem o fogo (4%→11%→15%, dá pra contornar andando). Único
    desbalanceamento real: P3 (CORRIDOR largura 1) — fogo vira portão de dano forçado
    nas ramificações fora da rota-ao-boss. Fogo da Fase 3 baixado `0.06 → 0.04`;
    abertura mantida em 0.44 (labirinto é a identidade do Ventre da Mata).
  - **Ferramenta de preview** (`scripts/tools/preview_map.gd`): dump ASCII + densidades
    por fase×seed, headless — tuning de mapa sem display.
  - **Ajuste de povoamento:** 6 monstros em TODAS as fases (antes 4/4/6/6 → agora
    6/6/6/6), sempre com ≥1 guarda perto do boss (`BOSS_GUARD_MIN=1`, já imposto).
    Decorações ambientais mais densas em todas as fases (P1 40→60, P2 22→44,
    P3 18→30, P4 22→44) — só visual, não afeta walkability.
  - Testes: `test_scene_transition.gd` (lógica de flavor + roteamento de TODA tela do
    enum p/ uma cena .tscn única); contagem por fase atualizada para 6/6/6/6. Gate
    verde: smoke OK, 134 testes / ~12.6k asserts.
  - **Adiado (follow-up):** daily-seed + leaderboard; variar canto do boss.

### Fase 9: Hub de Aprimoramentos Jogável 🚧

Tira os aprimoramentos da tela de menu pré-jogo e os transforma num **Acampamento
jogável** pelo qual a Caipora caminha **ao iniciar a run e entre uma fase e outra**. As ervas
compráveis da fase aparecem como **cards grandes e clicáveis** (`HubShop`/`HubCard`), cada um
com ícone, nome, efeito derivado (ex: "Dano +1/hit (total 2)") e custo; **clicar/tocar** num
que dá pra pagar realiza o aprimoramento. A saída é um rastro no chão → próxima fase. **A run
começa pelo acampamento** (`main_menu` abre o HUB antes da Fase 1): a Caipora gasta os
fragmentos acumulados de runs anteriores antes de pisar na mata.
Roadmap completo: [docs/PRD-fase-9-hub-jogavel.md](docs/PRD-fase-9-hub-jogavel.md).

- [ ] **Etapa 0 — Roteamento via hub:** `GameState.pending_exploration` +
  `advance_phase_via_hub()`; `exploration_manager` (tile de saída) e `arena_manager`
  (morte de boss P2→P3, P3→P4) roteiam o **avanço de fase** pelo HUB — vitória comum,
  boss da P1, ENDING e GAME_OVER seguem diretos. `main_menu.gd` inicia a run e cai direto
  na Exploração da Fase 1. Hub de cards atual segue temporário, agora lendo
  `pending_exploration`. Testes de roteamento.
- [ ] **Etapa 1 — Hub jogável (grid + saída):** `scenes/hub/hub.tscn` +
  `scripts/hub/hub_manager.gd` (Node2D: TileMap + Caipora + saída pulsante), `heal_to_full()`
  na entrada, `_scene_path_for(HUB)` aponta pra cena nova. Anda → pisa na saída → próxima
  fase, com continuidade da run preservada.
- [ ] **Etapa 2 — Ervas no chão + compra ao pisar:** posiciona toda erva comprável da fase
  (gate `phase_reached` + `requires` + não-comprada) com ícone + custo; compra ao pisar via
  `MetaProgression.purchase_upgrade` (fonte única de verdade); HUD de fragmentos + resumo
  de bônus; feedback de sucesso/insuficiente.
- [ ] **Etapa 3 — Polish + limpeza:** identidade do acampamento (fogueira, cachimbo, vida
  ambiente, SFX de "fumar", número flutuante, brilho acessível/caro), flavor de transição,
  **aposentar** `scenes/ui/hub.tscn` + `scripts/ui/hub.gd` (mover `OptionsPanel` pro hub
  jogável), atualizar `test_hub_*`/`test_scene_transition`. Gate verde.

### Fase Final: A Igreja na Mata — O Catequizador 🚧

A quinta e **última** fase: o interior de uma igreja colonial dentro da floresta.
O chefe é o **Jesuíta Bandeirante Catequizador**, que abre a fase declarando que
*converteu* os antigos encantados — por isso os "monstros" da tela **são os outros
quatro chefes** (Mula, Boitatá, Curupira, Saci), agora a serviço do altar; no fundo
da nave, o próprio Jesuíta. Encadeia depois do Saci (P4) e substitui o caminho
direto P4→ENDING (agora P4→**P5**→ENDING). É a fase mais difícil do jogo.
Spec completa: [docs/PRD-fase-final-igreja.md](docs/PRD-fase-final-igreja.md).

**Decisões travadas:** janela de reação **a mais dura de todas** (−0.2s ALÉM da
P4 → `PHASE5_TIMING_REDUCTION=0.50`, piso 0.2s); mini-bosses com **HP cheio de
chefe** (12/22/30/36); assets **AAA via pipeline procedural** (gen_chars/tiles/sfx).

> **Status:** Etapas 0–3 **implementadas** nesta sessão. O `make gate` (smoke +
> GUT) ainda **não foi rodado** — o container remoto não tem o binário do Godot.
> Rodar o gate num ambiente com Godot antes do merge; rodar `/validate-controls`
> e `/validate-platforms` (input/arena/timing/UI novos).

- [x] **Etapa 0 — Fundação de dados:** telas `EXPLORATION_PHASE5`/`ARENA_PHASE5`,
  roteamento `_scene_path_for`, `MapConfig.for_phase(5)` (`enemy_count=5`,
  `common_types=[mula,boitata,curupira,saci]`, `boss_type=jesuita`, `has_exit=false`),
  constantes `PHASE5_*` + `COMMON_FRAGMENT_REWARD[5]`/`BOSS_FRAGMENT_BOUNTY[5]`/
  `JESUITA_MAX_HEALTH`. Testes do gerador para a Fase 5.
- [x] **Etapa 1 — Chefe final jogável:** `jesuita.gd` (`extends Saci`, sorteio
  UNIFORME dos 7 padrões de todos os chefes + telegraphs corretos), `jesuita.tscn`,
  `arena_phase5.tscn`, `_phase_window` caso 5 e bônus de dano P5 em
  `_on_defense_timing_result`. `test_jesuita.gd`.
- [x] **Etapa 2 — Exploração da igreja + gauntlet:** `exploration_phase5.tscn`, caso
  5 do `_build_profile`, mini-bosses como comuns (`REGULAR_SCENES` + flag
  `keep_own_hp` p/ preservar HP de chefe), render de mini-boss no `MapEnemy`,
  **diálogo de abertura da fase** ("converti todos eles com espelhos e água benta.
  a floresta pertence ao vaticano."), roteamento P4→P5→ENDING + `phase_reached=5`
  ao liberar a Igreja e `phase_reached=6` ao derrotar o Jesuíta.
  `test_exploration_phase5.gd` + update de `test_scene_transition`/roteamento.
- [x] **Etapa 3 — Assets & polish AAA:** sprite do Jesuíta + SpriteFrames
  (`gen_chars.py`: morrião + gibão sobre batina, espelho + aspersório), decoração de
  igreja (`DECO_CHURCH`: banco/cruz/espelho/pia de água benta/círio em `map_object.gd`),
  3 faixas de áudio (`gen_sfx.py`: `mus_explore_p5` órgão+frígio, `mus_arena_p5`,
  `mus_boss_jesuita` com sino de igreja) wiradas no `AudioDirector`, `CanvasModulate`
  frio. `test_church_props.gd` + `test_audio_director` (P5).

### Economia & Aprimoramentos v2 ✅

Redefinição coerente da economia e da escala dos aprimoramentos para um roguelike
consistentemente **difícil**. Spec completa: [docs/PRD-economia-v2.md](docs/PRD-economia-v2.md).

- [x] **Fonte numérica única.** `UPGRADE_DEFS` ganha `dmg`/`hp`; `get_damage_bonus`/
  `get_health_bonus` são data-driven; o texto do efeito é DERIVADO via `effect_text()`
  (mata a classe de bug do KI-006 — campo `effect` removido).
- [x] **Trilha Fúria com teto.** Cada erva +1 dano (5/10/16/24 frags); dano vai de 1 a 5
  (6 com a CHAMA, agora +1 em vez de +2). Antes o teto era 8–10 e trivializava o late-game.
- [x] **Trilha Cura com incrementos crescentes.** +2/+3/+3/+4 HP (6/12/20/30 frags);
  HP máx. de 2 a 14. Antes era +2 fixo (retorno achatado).
- [x] **Snowball pela metade.** Kill comum dá **meio HP máx.** (acumula em
  `GameState.caipora_max_hp` float, materializa +1 coração a cada 2 kills) + cura 1;
  boss é marco (+1 HP máx. + cura 2). Antes: +1 HP máx. por kill (snowball forte).
- [x] **Currency inteira + boss bounty.** Kill comum 1/2/3/4 por fase; boss paga
  3/5/8/12 (antes boss = 0 e comuns davam 1.5/2.0/2.5 fracionários).
- [x] **HP de comum UNIFORME por banda de fase + dano da Caipora vindo da Fúria.**
  Todo comum (não-boss) tem o MESMO HP: `5` nas fases 1-2, `8` nas fases 3-5
  (`Constants.common_health_for_phase`, aplicado no `_spawn_enemy`). Cada golpe da
  Caipora parte de `1` em toda fase (`Constants.caipora_base_damage_for_phase`) e soma
  apenas ervas de Fúria/CHAMA no `_spawn_caipora`. Bosses mantêm HP próprio
  (12/22/30/36/44); na Fase 5, os 4 chefes convertidos mantêm HP próprio como mini-bosses.
- [x] **Crítico 2×–3× fica fora de escopo** (decisão deliberada, registrada no PRD): o
  burst por skill vem do ataque-duplo; subir o multiplicador estouraria o teto de dano.
- [x] Testes: literais de custo/HP/dano atualizados + `test_effect_text_matches_math`.
  Gate verde: smoke OK, 152 testes / ~12.7k asserts.

### Apresentação de Boss (estilo Mega Man) ✅

Toda boss fight abre com uma pré-tela curta de apresentação **antes do diálogo**:
fundo escuro, o **modelo do boss** surge em cena com um "pop" elástico e brilho de
aura, e abaixo o **nome estilizado** se revela letra a letra entre duas barras de
destaque (com o subtítulo "— CHEFE —"). Vale para os 4 bosses (Mula sem Cabeça,
Boitatá, Curupira, Saci).

- [x] `scripts/ui/boss_intro_screen.gd` (`BossIntroScreen`, CanvasLayer layer 15) +
  `scenes/ui/boss_intro_screen.tscn`. Cena montada por código (depende dos dados do
  boss em `start()`), no padrão de `ending_screen.gd`. Modelo normalizado a uma
  altura de exibição fixa; glow radial procedural (`GradientTexture2D`) na cor de
  aura.
- [x] **Nome sempre completo, nunca espremido.** Fonte grande e fixa (`FONT_TITLE`);
  quebra automática por PALAVRA (`AUTOWRAP_WORD`) em até 2 linhas quando o nome não
  cabe na largura (ex.: "MULA SEM CABEÇA" → "MULA SEM" / "CABEÇA"). A caixa reserva a
  altura do nome completo, então a revelação letra a letra não empurra as barras
  (alinhamento vertical TOP mantém a linha 1 fixa). As barras de destaque se
  reposicionam conforme 1 ou 2 linhas.
- [x] Animação: pop elástico do modelo → barras varrem do centro + subtítulo →
  revelação letra a letra do nome → hold → encerra. Bob ocioso do modelo e pulso
  do glow em loop. Auto-avança após o hold, ou **skip** por toque/tecla/clique
  (com carência anti-skip-acidental de 0.4s, igual ao diálogo).
- [x] Roteamento em `exploration_manager.gd`: combate de boss → `_show_boss_intro()`
  → `boss_intro_finished` → diálogo (ou direto à arena se a boss não tiver falas)
  → arena. Dados por fase no `_build_profile()` (`boss_frames` + `boss_aura`).
  Signal `boss_intro_finished` no `SignalBus` (par do já existente `boss_intro_started`).
- [x] Testes: `tests/unit/test_boss_intro_screen.gd` (15 testes: nome, modelo,
  signals start/finish, idempotência, revelação do nome, quebra de linha/word-wrap,
  caixa do nome limitada, eventos de skip). Gate verde: smoke OK, 179 testes /
  ~12.7k asserts. Verificação visual headless (Xvfb + harness de captura) confirmou
  os 4 bosses, incluindo a Mula em duas linhas.

### Bolsa de Fragmentos (Souls-like / Corpse Run) ✅

Ao **morrer**, a Caipora derruba **TODOS os fragmentos** numa **bolsa**, no lugar exato
da morte (fase + tile). A bolsa fica caída na mata; ao **pisar nela** numa run futura, a
Caipora reaver **todos** os fragmentos. **Morrer de novo** antes de chegar lá **perde
tudo** — a bolsa antiga é sobrescrita e segue com zero. Tensão souls-like sobre a moeda
de meta-progressão, coerente com o tom hostil da floresta.

- [x] Estado persistente em `MetaProgression` (`frag_bag_active/phase/pos/amount`, no save
  `v3`; migração v2→v3 no-op). API: `drop_fragment_bag(phase, pos)` (zera o saldo e
  sobrescreve qualquer bolsa anterior — só marca bolsa nova se havia fragmento),
  `has_bag_in_phase(phase)`, `recover_fragment_bag()` (devolve tudo + `fragment_gained`).
- [x] **Drop na morte** em ambos os caminhos: arena (`arena_manager._on_actor_died`, derrota,
  no tile do combate via `GameState.player_map_pos`) e hazard na exploração
  (`exploration_manager._apply_hazard_damage`, no tile atual).
- [x] **Bolsa no chão + recuperação ao pisar:** `MapObject.Type.BAG` (saco de couro em poça
  de sangue, estilhaços âmbar) + brilho âmbar pulsante. `exploration_manager._spawn_fragment_bag()`
  recria a bolsa na fase da morte; como o mapa é sorteado por run, o tile pode ter virado
  parede → `_nearest_walkable()` (BFS) reancora no caminhável mais próximo. Pisar reaver
  via `_recover_fragment_bag()` (HUD pulsa o ganho).
- [x] Testes: `tests/unit/test_fragment_bag.gd` (drop/recover/overwrite/save round-trip/reset).

### Redesign da Protagonista — A Predadora-Rainha da Mata ✅

A Caipora é o núcleo visual do jogo: só de olhar pra ela tem que dar vontade de
jogar. O boneco de retângulos da Fase 7 foi substituído por um design de
personagem alinhado à indústria (silhueta primeiro, acento único de cor, luz
própria, assimetria, atitude no idle) e fiel ao folclore (urucum, jenipapo,
vestes vivas de folha/cipó, pés normais pra frente). Bíblia visual:
[docs/CONCEITO-protagonista.md](docs/CONCEITO-protagonista.md) — **lei** para
todo asset futuro da protagonista.

- [x] Conceito: silhueta felina de predadora, **juba-cometa de fogo** (flui pra
  trás, eriça no windup, estica no strike), olhos de brasa em máscara de
  jenipapo, cipó-chicote com ponta em brasa, vestes vivas assimétricas.
- [x] Pipeline premium próprio (`scripts/tools/gen_caipora.py`, determinístico):
  desenho vetorial supersampled 8× → downsample → snap de paleta → **selout** →
  **rim light térmico procedural** (o fogo da juba ilumina o corpo) → dither de
  bandas no fogo. 6 frames (idle/walk×2/windup/strike/recover), 64×64.
- [x] `gen_chars.py` delega a protagonista ao `gen_caipora.py` (demais
  personagens intactos, byte a byte).
- [x] Linguagem corporal por pose preservando o contrato do `ActorAnimator` e
  do `caipora_sprite_frames.tres` (mesmos nomes/arquivos — zero mudança de cena).
- [x] **A CHAMA incendeia a Caipora:** com `has_chama` (permanente), os frames
  trocam para a variante incendiada (`player_*_chama.png` +
  `caipora_sprite_frames_chama.tres`): juba mais longa/quente, brasas orbitando
  (derivam entre os frames de walk; nunca caem no rosto), estalo do chicote
  maior. Seleção E aplicação em ponto único (`CaiporaSkin.frames_path/apply`,
  par do `WeaponVisual.attach_to`), por código (sem editar `.tscn`) na
  exploração, na arena e no `TitleWalker` (menu/ending). Conquista NO MEIO do
  combate incendeia na hora (`SignalBus.chama_gained` → re-apply preservando a
  pose). Mesmo contrato de animações — `ActorAnimator` não percebe. Testes:
  `test_caipora_chama_frames.gd`.

---

## 11.1 Known Issues

Rastreador canônico de bugs/débitos conhecidos. O Session Protocol exige registrar
aqui qualquer bug descoberto (mesmo não relacionado) antes de seguir. IDs no formato
`KI-NNN`; referencie-os em commits e REPORTs.

| ID | Severidade | Status | Descrição |
|----|-----------|--------|-----------|
| KI-004 | Média | ✅ Resolvida (`5cdbd40`) | Beco sem saída no fim de combate — telas WIN/GAME_OVER placeholder fecham o loop |
| KI-005 | Baixa | ✅ Resolvida (pós-MVP) | SFX reescritos com síntese de instrumentos do maracatu (alfaia/caixa/ganzá/agogô/gonguê) em `scripts/tools/gen_sfx.py`, com variação anti-repetição. Identidade sonora própria — não são mais placeholders genéricos |
| KI-006 | Baixa | ✅ Resolvida | Label do aprimoramento desincronizava do bônus real. Corrigido de vez na Economia v2: o campo `effect` foi removido e o texto é **derivado** da fonte numérica única (`dmg`/`hp`) via `MetaProgression.effect_text()` — não há mais string solta a divergir. Guardado por `test_effect_text_matches_math` |
| KI-007 | Média | ✅ Resolvida | Mapa não voltava idêntico após o combate: o jogador renascia no spawn (exceto Fase 1) e TODOS os inimigos teleportavam de volta ao spawn (o movimento na exploração é não-determinístico, então a regeração do mapa não os reproduz). Corrigido com snapshot de posições no `_trigger_combat` (`GameState.map_enemy_positions` + `player_map_pos` em todas as fases), restaurado em `_spawn_enemies`/`_setup_player`. `safe_spawn` agora só vale na entrada fresca da fase, não na volta do combate. Flag `keep_position` (sempre-true) removida |
| KI-008 | Média | ✅ Resolvida | `GameState.heal_to_full()` preserva o `caipora_max_hp` ganho dentro da run e só sobe para o novo teto meta se uma erva de Cura comprada no hub tornar esse teto maior. |
| KI-009 | Média | ✅ Resolvida | `Constants.caipora_base_damage_for_phase()` voltou a ser base fixa (`1`) em toda fase; a arena soma apenas Fúria/CHAMA por cima, então o texto das ervas volta a ser o teto real comunicado ao jogador. |
| KI-010 | Média | ✅ Resolvida | A vitória terminal libera `phase_reached = 6`: matar o Jesuíta marca o marco no `ArenaManager`, e `GameState.end_run(true)` também garante o unlock pós-clear antes de salvar a vitória. |

---

## 12. Diretrizes de Assets

- **Sprites:** pixel art autoral procedural (preferido), pack CC0 recolorido, ou **IA com pipeline de limpeza obrigatório** (paleta/grid/alpha). Personagens 48×48, tiles/itens 32×32, .png, fundo transparente. Detalhes em `assets/AGENTS.md`.
- **Áudio:** Identidade sonora própria (maracatu / Amazônia / folk-horror), sintetizada proceduralmente em `scripts/tools/gen_sfx.py` (stdlib, reproduzível). Camadas:
  - **SFX de combate** (`assets/audio/sfx/`): .wav curtos, punchy, under 100KB cada, 3 variantes por som (round-robin no `SfxSystem`).
  - **Ambiência** (`assets/audio/ambience/`): loops por tela — floresta amazônica (exploração/hub), dread (arena).
  - **Maracatu adaptativo** (`assets/audio/music/`): stems sincronizados (alfaia/ganzá/agogô); agogô só entra no boss.
  - **Stingers** (`assets/audio/stingers/`): entrada de arena, vitória, game-over, baú.
  - Arquitetura: bus layout `Master→SFX/Music/Ambience` (`default_bus_layout.tres`), autoload `AudioDirector` (volume persistido em `user://settings.cfg`, ducking, cross-fade por tela, unlock de autoplay HTML5), overlay de Opções com sliders. **A regra "sem música no MVP" foi superada pós-MVP.**
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
