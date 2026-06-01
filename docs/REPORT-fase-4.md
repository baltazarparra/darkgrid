# Report de Execução — Fase 4: Meta-Progression & UI

> **Projeto:** caipora — Brazilian Folk Horror Roguelike
> **Data:** 2026-06-01
> **Executor:** Claude Code (Opus 4.8)
> **Duração:** ~1 sessão
> **Status:** ✅ Concluída

---

## 1. Objetivo da Fase

Fechar o **loop do jogo**: porta de entrada (MainMenu), HUD de vida, Hub de descanso e
progressão entre runs, upgrades permanentes salvos em disco, e a costura completa das
transições de tela. Ao fim da fase, é possível **jogar uma run completa, perder, voltar
mais forte e tentar de novo**.

Fluxo entregue: `MainMenu → Hub → Exploração → Arena → Win/GameOver → Hub → próxima run`.

**Filosofia:** *"Progressão não é número maior. É a coragem de entrar de novo sabendo o que há lá dentro."*

---

## 2. Escopo Planejado vs. Executado

### 2.1 Requisitos Funcionais (RF)

| RF | Descrição | Status | Notas |
|----|-----------|--------|-------|
| **RF-401** | MainMenu | ✅ | `CanvasLayer` com título/subtítulo, Iniciar (→ Hub), Sair; carrega o save no boot. É a `main_scene`. |
| **RF-402** | Hub | ✅ | Recupera HP no `_ready`; exibe stats; `UpgradeList` gerada de `UPGRADE_DEFS`; "Entrar na Floresta" inicia a run. |
| **RF-403** | Upgrades em MetaProgression | ✅ | `UPGRADE_DEFS` (Vigor cap 3, Reflexos cap 2), `purchase_upgrade` (compra livre c/ cap), getters derivados, save retrocompatível. |
| **RF-404** | Estado de run no GameState | ✅ | `run_active`, `caipora_max_hp/current_hp`, `start_run`/`heal_to_full`/`end_run`. HP volátil (fora do save). |
| **RF-405** | Aplicar run/meta à Caipora | ✅ | ArenaManager seta HP/cooldown no spawn, reemite `caipora_health_changed`, ativa `caipora_died`, grava HP no fim. |
| **RF-406** | HUD de vida | ✅ | `ProgressBar` ligada a `SignalBus.caipora_health_changed`; desacoplado da Caipora. |
| **RF-407** | Win/GameOver no loop | ✅ | `EndScreen.won` → `end_run(won)` no `_ready`; `ui_accept` volta ao Hub. |
| **RF-408** | Transições completas | ✅ | `GameState` roteia MAIN_MENU/HUB; `main_scene` = MainMenu; loop sem becos. |

### 2.2 Requisitos Não-Funcionais (RNF)

| RNF | Descrição | Status | Notas |
|-----|-----------|--------|-------|
| **RNF-401** | Performance | ✅ (esperado) | UI leve; HUD atualiza só no sinal. Validação HTML5 na Fase 5. |
| **RNF-402** | Código | ✅ | `class_name` em `MainMenu`/`Hub`/`Hud`; static typing; sem hardcode (deriva de `Constants`/`MetaProgression`). |
| **RNF-403** | Decoupling | ✅ | HUD só escuta `SignalBus`; navegação só por `GameState.change_screen`. |
| **RNF-404** | Persistência | ✅ | Save retrocompatível (`upgrades` default `{}`); `SAVE_PATH` virou `var` p/ isolamento de teste. |
| **RNF-405** | Testes | ✅ | 6 testes novos (upgrades + run state). **29/29 passando** (23 anteriores + 6). |
| **RNF-406** | UI sem assets externos | ✅ | ColorRect/Label/Button/ProgressBar + paleta `Constants`; StyleBoxFlat procedural no HUD. |

---

## 3. Arquitetura Entregue (delta sobre a Fase 3)

```
caipora/
├── scenes/ui/
│   ├── main_menu.tscn      # boot — título + Iniciar/Sair
│   ├── hub.tscn            # stats + upgrades + Entrar na Floresta
│   └── hud.tscn            # ProgressBar de vida (na arena)
├── scripts/ui/
│   ├── main_menu.gd        # class_name MainMenu
│   ├── hub.gd              # class_name Hub (gera linhas de UPGRADE_DEFS)
│   ├── hud.gd              # class_name Hud (escuta SignalBus)
│   └── end_screen.gd       # +@export won, end_run, volta ao Hub
└── tests/unit/
    ├── test_upgrades.gd    # 3 testes
    └── test_run_state.gd   # 3 testes
```

**Modificados:** `meta_progression.gd` (UPGRADE_DEFS/upgrades/getters, SAVE_PATH var),
`game_state.gd` (run state + rotas MAIN_MENU/HUB), `arena_manager.gd` (HP/cooldown/sinais),
`combat_actor.gd` (wait_time no execute_attack), `arena.tscn` (nó Hud), `win/game_over.tscn`
(won + hints), `project.godot` (main_scene), `ROADMAP.md`.

### 3.1 Fluxo de Vida (HP persistente)

```
Hub._ready → GameState.heal_to_full()          # HP cheio, com bônus de meta
Hub "Entrar" → GameState.start_run()            # run_active, max = base + bônus
Arena._spawn_caipora → lê GameState.caipora_current_hp/max_hp e aplica à Caipora
  HealthComponent.health_changed → SignalBus.caipora_health_changed → HUD
Arena fim → grava caipora_current_hp de volta no GameState (persiste p/ próximo encontro)
Win/GameOver → GameState.end_run(won) → stats + save → volta ao Hub (cura)
```

---

## 4. Problemas Encontrados e Decisões

| # | Item | Resolução |
|---|------|-----------|
| **B-021** | `attack_cooldown` ajustado pós-spawn não afetava o Timer | `wait_time` era setado só no `_ready`. `execute_attack` passa a atualizar `_attack_timer.wait_time` antes de `start()`. |
| **B-022** | Testes de autoload poluiriam o `savegame.json` real | `SAVE_PATH` virou `var`; testes apontam para `user://test_savegame.json` e limpam no `after_each`. |
| **D-1** | Idempotência de `end_run` (PRD §6) | `change_scene_to_file` cria instância nova → `_ready` roda uma vez por entrada; sem guard extra necessário. |
| **D-2** | Ordem de init do HUD vs. emit inicial | `Hud` é nó-filho da arena → `_ready` (connect) roda antes do `_ready` do root (ArenaManager) que emite o estado inicial. |
| **Nota** | `class_name` novos | Exigiram `godot --headless --import` antes do GUT (mesmo padrão da Fase 3). |

---

## 5. Testes e Validação

### 5.1 Testes Unitários (GUT)

```
res://tests/unit/test_upgrades.gd
* test_purchase_increments_and_caps          ✅
* test_unknown_upgrade_is_rejected            ✅
* test_upgrades_persist_through_save_load     ✅

res://tests/unit/test_run_state.gd
* test_start_run_fills_hp_with_bonus          ✅
* test_damage_persists_until_heal             ✅
* test_end_run_updates_stats                  ✅

(+ 23 testes das Fases 0–3, todos mantidos)

Totals — Scripts 9 · Tests 29 · Passing 29 · Failing 0
```

### 5.2 Validação de Carga (headless)

- `main_menu.tscn`, `hub.tscn`, `hud.tscn`, `arena.tscn` (7 filhos c/ Hud) instanciam sem erros.
- `import` sem erros de parse nos scripts novos. Boot do projeto cai no MainMenu sem erros.

### 5.3 Pendente (smoke manual / Fase 5)

- Run completa com `F5` (MainMenu→Hub→comprar upgrade→combate com HUD→HP persistente→fim→Hub),
  persistência entre sessões e 60 FPS em HTML5.

---

## 6. Commits

| Hash | Mensagem |
|------|----------|
| `e85e84a` | fase-4-wave-1: meta upgrades + run state in gamestate |
| `5f93092` | fase-4-wave-2: main menu + screen routing |
| `b2ffbd1` | fase-4-wave-3: hub scene with upgrades + run start |
| `02c4546` | fase-4-wave-4: apply run/meta to caipora + hud |
| `4b3a942` | fase-4-wave-5: win/game_over record run + return to hub |

---

## 7. Estado de Saída da Fase 4

- ✅ Boot no MainMenu; Iniciar leva ao Hub
- ✅ Hub mostra caçadas/vitórias, permite aprimorar Vigor/Reflexos (salvo em disco) e iniciar a run
- ✅ HUD reflete a vida da Caipora em tempo real
- ✅ HP persiste entre encontros de uma run; recupera no Hub
- ✅ Bônus de meta (+HP, -cooldown) afetam a Caipora na arena
- ✅ Vitória/derrota registram estatísticas, salvam e voltam ao Hub
- ✅ Loop completo percorrível sem becos sem saída
- ✅ 29/29 testes unitários passando

### Próximo Milestone

**Fase 5: Export & Publish** — export HTML5, teste no browser (load < 10s) e publicação no itch.io.
Substituir os SFX sintéticos (KI-005) e placeholders por assets autorais é trabalho pós-MVP.

---

## 8. Referências

- [PRD Fase 4](./PRD-fase-4.md) — Especificação funcional
- [REPORT Fase 3](./REPORT-fase-3.md) — Enemy AI & Visceral Feedback
- [ROADMAP.md](../ROADMAP.md) — Roadmap do MVP (Fases 0–5)
