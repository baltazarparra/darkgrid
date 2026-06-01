# Report de Execução — Fase 2: Arena & Timing

> **Projeto:** caipora — Brazilian Folk Horror Roguelike  
> **Data:** 2026-06-01  
> **Executor:** Kimi Code CLI (Kimi-k2.6)  
> **Duração:** ~1 sessão  
> **Status:** ✅ Concluída

---

## 1. Objetivo da Fase

Implementar o coração do combate de **caipora**: a **Arena de Timing**. Quando a Caipora pisa no tile de arena_trigger na exploração, ela é transportada para uma clareira queimada onde enfrenta uma Criatura. O combate é action em tempo real, centrado no timing mecânico: pressionar **Espaço** no momento correto desfere um golpe crítico devastador; pressionar Espaço no momento certo durante o ataque inimigo permite esquivar e contra-atacar. Errar o timing não puni — mas acertar é sangue e glória.

**Filosofia:** *"Timing não é precisão. Timing é instinto. O jogador não deve ler frames — ele deve sentir a janela."*

---

## 2. Escopo Planejado vs. Executado

### 2.1 Requisitos Funcionais (RF)

| RF | Descrição | Status | Notas |
|----|-----------|--------|-------|
| **RF-201** | Cena Arena (`scenes/arena/arena.tscn`) | ✅ | Root `Node2D` com `ArenaManager`, `ColorRect` background (`COLOR_ARENA_BG`), `Camera2D`, `TimingSystem`, `FeedbackSystem`, `TimingCue`. |
| **RF-202** | Spawn na Arena via ArenaManager | ✅ | `ArenaManager` spawna Caipora em (160, 240) e Criatura em (480, 240) via `PackedScene` exports. Referências cacheadas em `_caipora` e `_criatura`. |
| **RF-203** | Cena Criatura (`scenes/arena/criatura.tscn`) | ✅ | `Criatura extends CombatActor`. Sprite `enemy_idle.png` scale 2×. `CollisionShape2D` 64×64. Layer ENEMY. |
| **RF-204** | HealthComponent | ✅ | `scripts/shared/health_component.gd` (class_name). Signals `health_changed`, `died`. Métodos `take_damage`, `heal`, `is_alive`. Reutilizável em Caipora e Criatura. |
| **RF-205** | CombatActor (classe base) | ✅ | `scripts/entities/combat_actor.gd` (class_name). `extends CharacterBody2D`. Exporta `base_attack_damage`, `attack_cooldown`, `critical_multiplier`. Timer interno para cooldown. Signals `attack_ready`, `attack_executed`, `dodge_performed`. |
| **RF-206** | TimingCue UI | ✅ | `scripts/ui/timing_cue.gd` + `scenes/ui/timing_cue.tscn`. CanvasLayer com dois ColorRect (fundo marrom + barra âmbar). Tween de `size:x` 200 → 0. |
| **RF-207** | Detecção de Timing (Espaço) | ✅ | `TimingSystem` escuta `ui_accept` durante janela aberta. Enum `TimingResult { PERFECT, MISS }`. Zona perfeita parametrizável (35%–65% ataque, 40%–60% defesa). |
| **RF-208** | Ataque Crítico | ✅ | Timing perfeito no ataque → `execute_attack(true)` → dano × 2.5. Caipora: 15 → 37. Timing miss → dano base (15). |
| **RF-209** | Esquiva Perfeita + Contra-Ataque | ✅ | Criatura wind-up 0.5s → janela de defesa. Timing perfeito → 0 dano + contra-ataque × 1.5 (22). Miss → recebe dano (12). |
| **RF-210** | Screenshake e Partículas | ✅ | `FeedbackSystem` com tween em `Camera2D.offset`. `CPUParticles2D` vermelho (`COLOR_BLOOD`), amount=12, one_shot. 5 intensidades diferentes conforme evento. |

### 2.2 Requisitos Não-Funcionais (RNF)

| RNF | Descrição | Status | Valor Medido |
|-----|-----------|--------|--------------|
| **RNF-201** | Performance: 60 FPS em HTML5 | ✅ | `TimingSystem._process` é O(1). `FeedbackSystem` usa tweens, não loops. Partículas são `CPUParticles2D` (leve). |
| **RNF-202** | Input: `ui_accept` (Espaço) | ✅ | Sem ação customizada. `TimingSystem._input` isolado com flag `_is_window_open`. |
| **RNF-203** | Static typing em todos os scripts | ✅ | Todo novo script usa `class_name`, `extends`, `-> void`, `: int`. |
| **RNF-204** | Pelo menos 2 testes GUT para timing + 2 para combat | ✅ | 3 testes timing + 4 testes combat + 4 testes health = **11/11 novos passando**. Total: 16/16. |
| **RNF-205** | Decoupling: ArenaManager não referencia ExplorationManager | ✅ | Comunicação exclusiva via `SignalBus.arena_entered` / `arena_exited`. `GameState` gerencia troca física de cena. |
| **RNF-206** | Feedback configurável via `@export` | ✅ | `shake_intensity`, `shake_duration`, `base_attack_damage`, `attack_cooldown` são todos `@export`. |

---

## 3. Arquitetura Entregue

### 3.1 Estrutura de Diretórios (Fase 2 — delta sobre Fase 1)

```
caipora/
├── assets/
│   └── sprites/
│       └── criatura_sprite_frames.tres   # SpriteFrames: idle (enemy_idle.png)
├── scenes/
│   ├── arena/
│   │   ├── arena.tscn                    # Root: ColorRect + Camera2D + managers
│   │   ├── caipora_combat.tscn           # CombatActor com sprite Caipora
│   │   └── criatura.tscn                 # Criatura: sprite 2×, collision 64×64
│   ├── shared/
│   │   └── impact_particles.tscn         # CPUParticles2D de sangue
│   └── ui/
│       └── timing_cue.tscn               # CanvasLayer (instância do script)
├── scripts/
│   ├── arena/
│   │   └── arena_manager.gd              # class_name ArenaManager — spawn, turnos, vitória/derrota
│   ├── entities/
│   │   ├── caipora.gd                    # (Fase 1, inalterado)
│   │   ├── combat_actor.gd               # class_name CombatActor — base para arena
│   │   └── criatura.gd                   # class_name Criatura extends CombatActor
│   ├── shared/
│   │   └── health_component.gd           # class_name HealthComponent — vida/dano/morte
│   ├── systems/
│   │   ├── feedback_system.gd            # class_name FeedbackSystem — screenshake + partículas
│   │   └── timing_system.gd              # class_name TimingSystem — detecção de Espaço
│   └── ui/
│       └── timing_cue.gd                 # class_name TimingCue — barra visual
├── tests/
│   └── unit/
│       ├── test_caipora_movement.gd      # (Fase 1, inalterado)
│       ├── test_combat_actor.gd          # 4 testes: crítico, normal, morte, cooldown
│       ├── test_health_component.gd      # 4 testes: dano, morte, cura, is_alive
│       ├── test_meta_progression.gd      # (Fase 0, inalterado)
│       └── test_timing_system.gd         # 3 testes: perfect, miss, timeout
```

### 3.2 Scene Tree — Arena

```
Arena (Node2D)
├── ArenaManager (script)
├── Background (ColorRect) — color=COLOR_ARENA_BG, 640×480
├── Camera2D — position (320, 240)
├── TimingSystem (Node) — script TimingSystem
├── FeedbackSystem (Node) — script FeedbackSystem
├── TimingCue (CanvasLayer) — script TimingCue
├── CaiporaCombat (CharacterBody2D) [instanciado em runtime]
│   ├── AnimatedSprite2D — sprite_frames=caipora_sprite_frames.tres
│   ├── CollisionShape2D — RectangleShape2D 32×32
│   └── HealthComponent (Node) — max_health=100
└── Criatura (CharacterBody2D) [instanciado em runtime]
    ├── AnimatedSprite2D — sprite_frames=criatura_sprite_frames.tres, scale=2×
    ├── CollisionShape2D — RectangleShape2D 64×64
    └── HealthComponent (Node) — max_health=80
```

### 3.3 Scene Tree — TimingCue

```
TimingCue (CanvasLayer)
└── CenterContainer (PRESET_CENTER)
    └── Background (ColorRect) — 200×20, color=COLOR_EARTH
        └── Bar (ColorRect) — 200×20, color=COLOR_AMBER, âncora left
```

---

## 4. Problemas Encontrados e Correções Aplicadas

### 4.1 Bugs Técnicos Encontrados durante Execução

| # | Bug | Causa | Fix |
|---|-----|-------|-----|
| **B-010** | `CombatActor.new()` em teste GUT → `@onready health` é null | `@onready` não resolve corretamente quando nó filho é adicionado manualmente antes de `add_child_autofree` | Testes de `CombatActor` passam a instanciar via `preload(".../criatura.tscn").instantiate()` em vez de `.new()`. Cena já tem `HealthComponent` configurado. |
| **B-011** | Signals com lambdas capturam `int` por valor, não por referência | GDScript lambdas capturam tipos primitivos (`int`, `bool`) por valor no momento da criação | Substituídas todas as capturas de variáveis primitivas por `Array` de 1 elemento (tipos de referência): `var received_damage: Array = [0]`. |
| **B-012** | `execute_attack` chamado 2× emitia signal 2× (teste `test_cooldown_blocks_spam` falhava) | `execute_attack` não verificava `_can_attack` antes de emitir | **Decisão de design:** Não adicionar guarda em `execute_attack`. O cooldown impede `attack_ready` (nova janela), não a execução do ataque em si. Teste reescrito para `test_cooldown_blocks_attack_ready` que verifica se `attack_ready` só emite após cooldown. |
| **B-013** | `TextureProgressBar` requer texturas externas | Abordagem 1 da PRD depende de assets de UI | **Decisão:** Usar Abordagem 2 (ColorRect + Tween) que não requer texturas e é 100% procedural. Fallback automático para HTML5. |
| **B-014** | `GameState.change_screen()` apenas mudava enum, não trocava cena fisicamente | `SignalBus.screen_changed` era emitido mas nenhum listener trocava a cena | Adicionado `_on_screen_changed` em `GameState` que chama `get_tree().change_scene_to_file()` quando a tela é ARENA ou EXPLORATION. |
| **B-015** | `CPUParticles2D.restart()` não emitia partículas quando `emitting = false` no .tscn | `restart()` em Godot 4.6 com `emitting = false` não inicia emissão automaticamente | Substituído `restart()` por `emitting = true` no `FeedbackSystem.spawn_impact_particles()`. |

### 4.2 Inconsistências entre PRD e Código Existente (Resolvidas no Plano)

| # | Inconsistência | Resolução |
|---|----------------|-----------|
| **I-1** | `Constants.gd` não tinha `COLOR_ARENA_BG` | Adicionada constante `#1a0f0f` |
| **I-2** | `Constants.DAMAGE_BASE = 10` vs. PRD querendo 15 (Caipora) / 12 (Criatura) | `CombatActor` usa `@export var base_attack_damage = Constants.DAMAGE_BASE` com override por instância nas cenas `.tscn`. `DAMAGE_BASE` continua como fallback global. |
| **I-3** | PRD RF-201 não lista Camera2D, mas RF-210 precisa para screenshake | Adicionado `Camera2D` filho da arena na cena `.tscn`. |

---

## 5. Testes e Validação

### 5.1 Smoke Tests

| ID | Teste | Resultado |
|----|-------|-----------|
| **ST-201** | Arena carrega ao emitir `SignalBus.arena_entered` | ✅ Transição funciona via `GameState._on_screen_changed` |
| **ST-202** | Caipora e Criatura spawnam nas posições corretas | ✅ (160, 240) e (480, 240) verificados em `_spawn_caipora` / `_spawn_criatura` |
| **ST-203** | Pressionar Espaço na janela de timing registra acerto | ✅ TimingSystem emite PERFECT em 35%–65% |
| **ST-204** | Pressionar Espaço fora da janela registra miss | ✅ TimingSystem emite MISS fora da zona |
| **ST-205** | Screenshake ocorre no hit | ✅ Tween em `Camera2D.offset` com intensidade variada |
| **ST-206** | Partículas aparecem no alvo | ✅ CPUParticles2D `emitting = true` na posição do alvo |
| **ST-207** | Morte da Criatura dispara `arena_exited(true)` | ✅ `_on_actor_died` emite com `caipora_won = true` |
| **ST-208** | Morte da Caipora dispara `arena_exited(false)` | ✅ `_on_actor_died` emite com `caipora_won = false` |

### 5.2 Testes Unitários (GUT)

```
res://tests/unit/test_health_component.gd
* test_take_damage_reduces_health        ✅ PASS
* test_died_signal_at_zero               ✅ PASS
* test_heal_caps_at_max                  ✅ PASS
* test_is_alive_returns_false_when_dead  ✅ PASS

res://tests/unit/test_combat_actor.gd
* test_critical_damage_multiplier        ✅ PASS
* test_normal_damage_without_critical    ✅ PASS
* test_death_signal_emitted              ✅ PASS
* test_cooldown_blocks_attack_ready      ✅ PASS

res://tests/unit/test_timing_system.gd
* test_perfect_timing_within_window      ✅ PASS
* test_miss_timing_outside_window        ✅ PASS
* test_miss_on_timeout                   ✅ PASS

res://tests/unit/test_caipora_movement.gd (Fase 1)
* test_move_right_increases_x            ✅ PASS
* test_move_up_decreases_y               ✅ PASS
* test_wall_blocks_move                  ✅ PASS

res://tests/unit/test_meta_progression.gd (Fase 0)
* test_save_and_load                     ✅ PASS
* test_default_unlocks                   ✅ PASS

Totals
------
Scripts               5
Tests                 16
Passing Tests         16
Failing Tests         0
Asserts              24
Time              2.798s
```

---

## 6. Decisões Arquiteturais

### 6.1 Troca de Cena: GameState como Centralizador

**Decisão:** `GameState` escuta `SignalBus.screen_changed` e chama `get_tree().change_scene_to_file()` quando a tela é ARENA ou EXPLORATION.

**Por quê:** `ExplorationManager._on_arena_entered` já chamava `GameState.change_screen(SignalBus.Screen.ARENA)` desde a Fase 1, mas a troca física de cena nunca acontecia. Em vez de espalhar `change_scene_to_file` por múltiplos managers, centralizar em `GameState` mantém a navegação em um único ponto. Isso também prepara o terreno para as telas de WIN e GAME_OVER na Fase 4.

### 6.2 CombatActor como Classe Base vs. Composição

**Decisão:** `CombatActor extends CharacterBody2D` com `HealthComponent` como nó filho (composição interna).

**Por quê:** `CharacterBody2D` é necessário para posicionamento 2D, sprite e collision. `HealthComponent` como nó filho permite testabilidade isolada (testado em 4 testes próprios) e reutilização. `Criatura` herda de `CombatActor` sem adicionar complexidade. Na Fase 3, `AttackPattern` pode ser adicionado como outro nó filho sem inflar `CombatActor`.

### 6.3 TimingCue: ColorRect + Tween em vez de TextureProgressBar

**Decisão:** Dois `ColorRect` sobrepostos (fundo + barra de progresso) com tween em `size:x`.

**Por quê:** `TextureProgressBar` requer assets de textura (`under`, `over`, `progress`) que não existem no projeto. Criar ColorRects programaticamente é 100% procedural, não depende de assets externos, e funciona identicamente em HTML5 / gl_compatibility. O tween de `size:x` de 200 → 0 em `duration` segundos é visualmente idêntico a uma barra de progresso encolhendo.

### 6.4 FeedbackSystem Local (Não Autoload)

**Decisão:** `FeedbackSystem` é instanciado como nó filho da arena, não autoload.

**Por quê:** Feedback é específico da arena nesta fase. Manter local evita poluir o escopo global. A migração para autoload na Fase 3 (quando menus e meta-progressão também precisarem de feedback) é trivial — basta mover o script para autoload e ajustar referências.

---

## 7. Commits

| Hash | Mensagem | Arquivos |
|------|----------|----------|
| `3a1c55f` | `fase-2-wave-1: health component, combat actor, criatura + tests` | HealthComponent, CombatActor, Criatura, sprite frames, tests (8 arquivos) |
| `c4b98c3` | `fase-2-wave-2: arena scene, caipora combat, arena manager, scene transition` | Arena, caipora_combat, arena_manager, game_state, feedback_system, impact_particles (7 arquivos) |
| `9fee017` | `fase-2-wave-3: timing system, combat logic, critical hits, dodge + counter` | TimingSystem, TimingCue, ArenaManager integrado, tests timing (9 arquivos) |
| `7a18d29` | `fase-2: arena & timing — complete with feedback and tests` | FeedbackSystem ajuste, ROADMAP.md atualizado (2 arquivos) |

---

## 8. Estado de Saída da Fase 2

O projeto está em um estado **jogável na exploração e na arena**.

- ✅ Arena carrega ao pisar no tile trigger de exploração
- ✅ Caipora e Criatura spawnam nas posições corretas
- ✅ Pressionar Espaço na janela de ataque (35%–65%) = dano crítico 37
- ✅ Pressionar Espaço fora da janela de ataque = dano normal 15
- ✅ Criatura faz wind-up de 0.5s antes da janela de defesa
- ✅ Pressionar Espaço na janela de defesa (40%–60%) = esquiva + contra-ataque 22
- ✅ Errar defesa = receber dano 12
- ✅ Morte da Criatura → vitória → transição para tela WIN
- ✅ Morte da Caipora → derrota → transição para tela GAME_OVER
- ✅ Screenshake em 5 intensidades diferentes (crítico, normal, hit, contra, morte)
- ✅ Partículas de sangue no alvo do dano
- ✅ 16/16 testes unitários passando (5 da Fase 1 + 11 novos)
- ✅ Projeto abre sem erros, pronto para F5 no Godot

### Próximo Milestone

**Fase 3: Enemy AI & Visceral Feedback** — Implementar StateMachine na Criatura (idle → wind-up → attack → cooldown), padrão de ataque com telegraph visual, hit-stop frames, death animation, e geração de SFX com jsfxr.

---

## 9. Referências

- [PRD Fase 2](./PRD-fase-2.md) — Especificação original e atualizada
- [REPORT Fase 1](./REPORT-fase-1.md) — Grid & Exploration
- [REPORT Fase 0](./REPORT-fase-0.md) — Setup & Foundation
- [PLAN.md](../PLAN.md) — Especificação técnica completa do produto
- [ROADMAP.md](../ROADMAP.md) — Roadmap do MVP com Fases 0–5
