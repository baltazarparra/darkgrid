# ROADMAP — Caipora

## Fase 1 — Floresta Corrompida ✅ Completa

Cena de exploração grid-based, combate de arena com sistema de timing, Criatura (inimigo normal) e boss Caçador Amaldiçoado.

---

## Fase 2 — A Amazônia em Chamas

### 2.0 — Refatoração Arquitetural: `input_sequence`

**Motivação:** A sequência de inputs do ataque especial está hardcoded em `arena_manager.gd:238`.
Os novos padrões da Fase 2 precisam de sequências diferentes — mover isso para o recurso.

**Tarefas:**
- [ ] `scripts/entities/attack_pattern.gd` — adicionar `@export var input_sequence: Array[String] = []`
- [ ] `scripts/arena/arena_manager.gd` (~linha 238) — usar `_active_enemy_pattern.input_sequence` em vez do array hardcoded; mapear action → hint dinamicamente
- [ ] `resources/attack_patterns/boss_special_pattern.tres` — adicionar `input_sequence = ["ui_right", "ui_left", "ui_right", "ui_left"]` explicitamente
- [ ] `make gate` passa (smoke + GUT sem regressão)

---

### 2.1 — Sistema de Diálogo

**Motivação:** O combate com o BOITATÁ deve ser precedido de uma cena de diálogo narrativo. Nenhum sistema de diálogo existe no projeto.

**Tarefas:**
- [ ] `scripts/core/signal_bus.gd` — adicionar sinais `boss_intro_started` e `dialogue_finished`
- [ ] `scenes/ui/dialogue_screen.tscn` — CanvasLayer com overlay escuro, label de nome em destaque, caixa de fala, indicador "▼"
- [ ] `scripts/ui/dialogue_screen.gd` — gerencia array de falas `[{speaker, text}]`, aguarda `ui_accept` / SPACE entre cada fala, emite `dialogue_finished` ao fim
- [ ] Integrar em `scenes/exploration/exploration_phase2.tscn`: tile de boss emite `boss_intro_started` → `DialogueScreen` carrega → `dialogue_finished` → `GameState.change_screen(Screen.ARENA)` com `GameState.next_enemy_scene = boitata_scene`
- [ ] `tests/unit/test_dialogue_screen.gd` — sequência de falas e emissão de `dialogue_finished`
- [ ] `make gate` passa

---

### 2.2 — Inimigo: Caçador com Tocha

**Motivação:** Inimigo padrão da Fase 2. Base idêntica à Criatura da Fase 1, com um terceiro padrão de ataque especial (4 hits, `↑↓↑↓`).

**Padrões de ataque:**

| Padrão | Sequência | Hits | Strike delay | Dano/hit |
|--------|-----------|------|-------------|---------|
| Básico | `↓` | 1 | — | 1.0× |
| Duplo (jump_telegraph) | `↓ ↓` | 2 | 0.15s | 0.5× |
| Especial (tocha) | `↑ ↓ ↑ ↓` | 4 | 0.5s | 2.0× |

**HP:** 9

**Tarefas:**
- [ ] `resources/attack_patterns/cacador_special_pattern.tres` — `strike_count=4`, `strike_delay=0.5`, `damage_multiplier=2.0`, `is_special=true`, `input_sequence=["ui_up","ui_down","ui_up","ui_down"]`
- [ ] `scripts/entities/cacador.gd` — herda `Criatura`; seleção 35% especial / 30% duplo / 35% básico; telegraph especial com `COLOR_TELEGRAPH_ENEMY_ALT` + jump
- [ ] `scenes/arena/cacador.tscn`
- [ ] `scripts/utils/constants.gd` — `CACADOR_MAX_HEALTH := 9`
- [ ] `tests/unit/test_cacador_patterns.gd`
- [ ] `make gate` passa

---

### 2.3 — Boss: BOITATÁ

**Motivação:** Boss da Fase 2 — serpente de fogo com diálogo pré-combate. Reutiliza todos os padrões do boss da Fase 1 e adiciona um especial branco (`↑↑↓↓`) mais rápido e mais letal.

**Padrões de ataque:**

| Padrão | Sequência | Hits | Strike delay | Dano/hit | Cor telegraph |
|--------|-----------|------|-------------|---------|--------------|
| Triplo básico | `↓ ↓ ↓` | 3 | 0.4s | 1.0× | Roxo |
| Duplo bloco | `↓ ↓` (jump) | 2 | 0.3s | 1.0× | Âmbar |
| Especial roxo | `→ ← → ←` | 4 | 0.5s | 2.0× | Roxo |
| **Especial branco** | `↑ ↑ ↓ ↓` | 4 | **0.3s** | **3.0×** | **Branco** |

> Strike delay do branco = 0.5 − 0.2 = 0.3s (0.2s menor que o especial roxo). Dano = 3 HP por hit acertado.

**HP:** 15

**Diálogo pré-combate:**
- Nome **BOITATÁ** em destaque (`COLOR_AMBER`, `FONT_TITLE`)
- **CAIPORA:** "Você nos traiu..."
- **BOITATÁ:** "Vocês me abandonaram!"

**Tarefas:**
- [ ] `resources/attack_patterns/boitata_white_special_pattern.tres` — `strike_count=4`, `strike_delay=0.3`, `damage_multiplier=3.0`, `is_special=true`, `input_sequence=["ui_up","ui_up","ui_down","ui_down"]`
- [ ] `scripts/entities/boitata.gd` — herda `Boss`; seleção 25% branco / 25% roxo / 25% duplo / 25% básico; override `_play_windup_telegraph()` para cor branca no especial branco
- [ ] `scenes/arena/boitata.tscn`
- [ ] `scripts/utils/constants.gd` — `BOITATA_MAX_HEALTH := 15`, `COLOR_TELEGRAPH_BOITATA_WHITE := Color(2.0, 2.0, 2.0)`, `COLOR_AURA_BOITATA := Color(1.0, 0.45, 0.05, 0.75)`
- [ ] `tests/unit/test_boitata_patterns.gd` — delay 0.3s, dano 3.0×, sequência `↑↑↓↓`
- [ ] `make gate` passa

---

### 2.4 — Arena Visual e Mapa de Exploração

**Motivação:** O ambiente da Fase 2 deve comunicar "floresta em chamas" — mais escuro, mais hostil. O mapa introduz hazard de fogo com dano direto à Caipora.

**Arena visual:**
- [ ] `scenes/arena/arena_phase2.tscn` — background de floresta em chamas, `CanvasModulate` vermelho-escuro
- [ ] CPUParticles2D de brasas caindo na arena
- [ ] SFX: `assets/audio/sfx/fire_crackling.wav`

**Mapa de exploração:**
- [ ] `scenes/exploration/exploration_phase2.tscn` — tileset de brasas/cinzas, tiles de fogo espalhados
- [ ] `scripts/exploration/fire_tile_handler.gd` — ao pisar em `tile_fire`: 2 HP de dano, cooldown 0.5s, emite `SignalBus.caipora_health_changed`
- [ ] `scripts/utils/constants.gd` — `FIRE_TILE_DAMAGE := 2`, `FIRE_TILE_COOLDOWN := 0.5`
- [ ] CPUParticles2D de chama nos tiles de fogo
- [ ] Transição automática da Fase 1 → Fase 2 ao vencer a última arena
- [ ] `tests/unit/test_fire_damage.gd` — 2 HP de dano, cooldown funciona
- [ ] `make gate` passa

---

## Gate de Qualidade (todas as sub-fases)

```bash
make smoke   # jogo inicia sem erros
make test    # GUT regression gate passa
```

Antes de fechar qualquer sub-fase:
1. `make gate` verde
2. Visual testado manualmente (se houver mudança de tela)
3. Commit com mensagem descritiva
