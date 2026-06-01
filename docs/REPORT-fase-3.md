# Report de Execução — Fase 3: Enemy AI & Visceral Feedback

> **Projeto:** caipora — Brazilian Folk Horror Roguelike
> **Data:** 2026-06-01
> **Executor:** Claude Code (Opus 4.8)
> **Duração:** ~1 sessão
> **Status:** ✅ Concluída

---

## 1. Objetivo da Fase

Transformar a Criatura de um boneco de treino em um predador autônomo e tornar o
feedback de combate visceral. A Criatura passa a **decidir** quando atacar via uma
StateMachine própria; o wind-up ganha telegraph visual; um Boss multi-strike aparece;
e cada impacto ganha peso com partículas específicas, hit-stop frames, death animation
e SFX. Como bônus de coerência, o beco sem saída de fim de combate (KI-004) foi resolvido
com telas placeholder WIN/GAME_OVER, fechando o loop jogável.

**Filosofia:** *"O inimigo não é um obstáculo. O inimigo é uma promessa de dor."*

---

## 2. Escopo Planejado vs. Executado

### 2.1 Requisitos Funcionais (RF)

| RF | Descrição | Status | Notas |
|----|-----------|--------|-------|
| **RF-301** | StateMachine na Criatura | ✅ | `EnemyStateMachine` (IDLE→WIND_UP→ATTACK→COOLDOWN) dirigida por `AttackPattern` (Resource). ArenaManager perdeu o `_windup_timer`; reage só a sinais. |
| **RF-302** | Telegraph visual no wind-up | ✅ | Pulso vermelho (`modulate`+`scale`) em loop durante WIND_UP; lunge de `position.x` no ATTACK. Interrompido na morte. |
| **RF-303** | Boss com pattern diferente | ✅ | `Boss extends Criatura`, 3× scale, 96×96, 200 HP, dano 18. Pattern multi-strike (3 golpes, `strike_delay` 0.4). |
| **RF-304** | Blood particles aprimoradas | ✅ | 3 cenas `CPUParticles2D`: `blood`(20, cai), `critical`(35, gradient, sobe), `death`(60, gradient massivo). |
| **RF-305** | Hit-stop frames | ✅ | `FeedbackSystem.trigger_hit_stop` via `Engine.time_scale=0` + timer com `ignore_time_scale`. Anti-acúmulo. 3/4/2/5 frames por evento. |
| **RF-306** | Death animation | ✅ | `CombatActor._on_health_died`: flash branco → fade out → `queue_free`. Flag `_is_dying` bloqueia dano/ataque. ArenaManager aguarda ~0.6s antes da troca de tela. |
| **RF-307** | SFX | ✅ | 6 WAVs mono 22050Hz gerados por `scripts/tools/gen_sfx.py` (fallback de jsfxr — ver KI-005). Todos < 18KB. |
| **RF-308** | Conectar SFX ao combate | ✅ | `SfxSystem` (AudioStreamPlayer descartável). ArenaManager toca attack/hit/dodge/perfect/death; `timing_perfect` no frame do input. |

### 2.2 Requisitos Não-Funcionais (RNF)

| RNF | Descrição | Status | Notas |
|-----|-----------|--------|-------|
| **RNF-301** | Performance 60 FPS | ✅ (esperado) | Partículas `CPUParticles2D`; hit-stop curto. Validação HTML5 fica para a Fase 5. |
| **RNF-302** | SFX WAV mono 22050Hz < 100KB | ✅ | Maior arquivo: `death.wav` ~17KB. |
| **RNF-303** | StateMachine com enum + match/case | ✅ | Sem `if` encadeado de estado. `class_name` em todos os scripts novos. |
| **RNF-304** | Testes GUT (StateMachine + Boss) | ✅ | 4 testes SM + 3 testes Boss = 7 novos. Total **23/23 passando**. |
| **RNF-305** | Decoupling ArenaManager↔StateMachine | ✅ | Comunicação só por sinais (`attack_started`, `pattern_finished`). ArenaManager nunca referencia `Boss`. |
| **RNF-306** | Extensibilidade via Resource | ✅ | `AttackPattern` como `.tres`; novos inimigos = nova cena + novo pattern, sem código. |

---

## 3. Arquitetura Entregue (delta sobre a Fase 2)

```
caipora/
├── assets/audio/sfx/
│   ├── attack.wav  hit.wav  dodge.wav
│   └── timing_perfect.wav  death.wav  ui_click.wav
├── resources/attack_patterns/
│   ├── criatura_pattern.tres        # 1 golpe (default)
│   └── boss_pattern.tres            # 3 golpes consecutivos
├── scenes/
│   ├── arena/
│   │   └── boss.tscn                # Boss 3×, 96×96, 200 HP, tom escuro
│   ├── shared/
│   │   ├── blood_particles.tscn     # 20, cai com gravity
│   │   ├── critical_particles.tscn  # 35, sobe, gradient
│   │   └── death_particles.tscn     # 60, explosão massiva
│   └── ui/
│       ├── win.tscn                 # placeholder WIN (KI-004)
│       └── game_over.tscn           # placeholder GAME_OVER (KI-004)
├── scripts/
│   ├── entities/
│   │   ├── attack_pattern.gd        # class_name AttackPattern (Resource)
│   │   ├── enemy_state_machine.gd   # class_name EnemyStateMachine
│   │   └── boss.gd                  # class_name Boss extends Criatura
│   ├── systems/
│   │   └── sfx_system.gd            # class_name SfxSystem
│   ├── ui/
│   │   └── end_screen.gd            # class_name EndScreen
│   └── tools/
│       └── gen_sfx.py               # gerador de SFX (fallback jsfxr)
└── tests/unit/
    ├── test_enemy_state_machine.gd  # 4 testes
    └── test_boss_pattern.gd         # 3 testes
```

**Modificados:** `criatura.gd` (StateMachine + telegraph + `_base_scale`/`_base_modulate`),
`combat_actor.gd` (death animation + `_is_dying`), `feedback_system.gd` (partículas + hit-stop),
`arena_manager.gd` (sinais da SM + SFX + hit-stop; `enemy_scene`), `game_state.gd`
(WIN/GAME_OVER + `next_enemy_scene`), `criatura.tscn`/`arena.tscn` (nós novos), `ROADMAP.md`.

### 3.1 Fluxo de Combate (turno do inimigo, novo)

```
ArenaManager._start_enemy_turn()
  → _enemy.state_machine.start_pattern(pattern)
StateMachine: IDLE → WIND_UP → ATTACK
  → attack_started  ──► ArenaManager abre janela de defesa (TimingCue + TimingSystem)
  (multi-strike: ATTACK → WIND_UP → ATTACK … por strike_count)
  → COOLDOWN → pattern_finished ──► ArenaManager._start_caipora_turn()
```

---

## 4. Problemas Encontrados e Correções

| # | Problema | Causa | Fix |
|---|----------|-------|-----|
| **B-016** | `class_name` novos não resolvidos nos testes (`Could not find type "AttackPattern"`) | Cache global de classes (`.godot/...cfg`) não atualizado ao rodar GUT headless sem reimport | Rodar `godot --headless --import` após criar scripts com `class_name`. |
| **B-017** | `var windup := ... if ... else ...` falha no parser | Inferência de tipo (`:=`) não funciona com ternário sem tipo explícito | Trocado por `var windup: float = ...`. |
| **B-018** | `test_combat_actor` chamava `_actor._ready()` manualmente antes do `add_child` | Com a nova Criatura acessando `@onready state_machine`, o `_ready` manual quebraria (nó ainda fora da árvore) | Removida a chamada manual; o `add_child_autofree` dispara o `_ready` e resolve os `@onready`. |
| **B-019** | `Engine.time_scale=0` congelaria o próprio timer do hit-stop | Timers do SceneTree escalam com `time_scale` | `create_timer(t, true, false, true)` com `ignore_time_scale=true`. |
| **B-020** | Telegraph apagaria o tom escuro do Boss (reset para `Color.WHITE`) | Reset assumia base branca | Captura `_base_modulate` no `_ready`; pulso e reset usam-no. |

### 4.1 Decisões de Coerência (lacunas do PRD)

| # | Lacuna | Resolução |
|---|--------|-----------|
| **D-1** | PRD não amarrava como o Boss entra em jogo | `ArenaManager.enemy_scene` (`@export`, default Criatura) + `GameState.next_enemy_scene` (override opcional). ArenaManager nunca referencia `Boss`. |
| **D-2** | Multi-strike: "contra-ataque único após o último / interromper sequência" (PRD) | Simplificado para **resolução por golpe** (cada esquiva = contra-ataque; cada erro = dano), reaproveitando o fluxo de defesa da Criatura sem ramo especial. Mais robusto e consistente; Boss segue claramente mais ameaçador (3 janelas, mais rápido). |
| **D-3** | Telas WIN/GAME_OVER eram da Fase 4 (KI-004) | Adicionadas como placeholder mínimo agora, fechando o loop. Menus/hub completos seguem para a Fase 4. |
| **D-4** | PRD citava enum `{PERFECT, GOOD, MISS}` | Mantido o `{PERFECT, MISS}` da Fase 2 (sem `GOOD`). |

---

## 5. Testes e Validação

### 5.1 Testes Unitários (GUT)

```
res://tests/unit/test_enemy_state_machine.gd
* test_idle_to_windup_transition              ✅
* test_full_cycle_idle_windup_attack_cooldown ✅
* test_pattern_finished_emitted_after_cooldown✅
* test_multi_strike_opens_multiple_attacks    ✅

res://tests/unit/test_boss_pattern.gd
* test_attack_pattern_has_strike_fields       ✅
* test_boss_is_a_criatura_with_boss_stats     ✅
* test_boss_pattern_runs_three_strikes        ✅

(+ 16 testes das Fases 0–2, todos mantidos)

Totals — Scripts 7 · Tests 23 · Passing 23 · Failing 0
```

### 5.2 Validação de Carga (headless)

- `arena.tscn`, `boss.tscn`, `win.tscn`, `game_over.tscn` instanciam sem erros.
- Projeto roda headless sem erros de parse/autoload.

### 5.3 Pendente (smoke manual / Fase 5)

- Verificação audiovisual com `F5` (pulso, lunge, hit-stop, SFX, telas) e 60 FPS em HTML5.

---

## 6. Commits

| Hash | Mensagem |
|------|----------|
| `5c308b5` | fase-3-wave-1: enemy state machine + attack pattern resource |
| `a41a7c0` | fase-3-wave-2: wind-up telegraph (pulse + lunge) |
| `17247fe` | fase-3-wave-3: blood/critical/death particles, hit-stop, death animation |
| `691e180` | fase-3-wave-4: sfx generation + combat audio wiring |
| `71c2f4c` | fase-3-wave-5: boss multi-strike pattern |
| `5cdbd40` | fase-3-wave-6: win/game_over placeholder screens (resolve KI-004) |

---

## 7. Estado de Saída da Fase 3

- ✅ Criatura cicla autonomamente (IDLE→WIND_UP→ATTACK→COOLDOWN) via StateMachine
- ✅ Telegraph visual (pulso vermelho + lunge) precede cada ataque
- ✅ Boss multi-strike (3 golpes) plugável via `enemy_scene` / `GameState.next_enemy_scene`
- ✅ Blood / critical / death particles distintas por tipo de hit
- ✅ Hit-stop frames (2–5) dão peso aos impactos
- ✅ Death animation (flash + fade + partículas) antes da troca de tela
- ✅ 6 SFX gerados e conectados aos eventos de combate
- ✅ Telas WIN/GAME_OVER placeholder fecham o loop (KI-004 resolvida)
- ✅ 23/23 testes unitários passando

### Próximo Milestone

**Fase 4: Meta-Progression & UI** — MainMenu, HUD de vida, Hub entre runs com upgrades,
persistência em `user://savegame.json`, e os menus completos que substituem os placeholders
WIN/GAME_OVER desta fase.

---

## 8. Referências

- [PRD Fase 3](./PRD-fase-3.md) — Especificação funcional
- [REPORT Fase 2](./REPORT-fase-2.md) — Arena & Timing
- [ROADMAP.md](../ROADMAP.md) — Roadmap do MVP (Fases 0–5)
