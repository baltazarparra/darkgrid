# PRD — Update: Fase 2 QA + Novos Aprimoramentos

**Data:** 2026-06-02
**Status:** Aguardando implementação

---

## 1. Visão Geral

Este update tem dois objetivos:

1. **Validação da Fase 2** — verificar que todos os entregáveis implementados (sub-fases 2.0–2.4) estão funcionando corretamente no jogo real antes de liberar conteúdo novo.
2. **Novos aprimoramentos pós-Fase 2** — dois upgrades desbloqueados no Hub depois que o jogador chega à Fase 2, com drop aumentado de fragmentos na Fase 2 para viabilizar a progressão.

---

## 2. Gate de Validação — Fase 2 (pré-requisito)

Antes de implementar qualquer feature nova, executar o seguinte checklist manualmente:

### 2.1 Sub-fase 2.0 — `input_sequence`
- [ ] Boss da Fase 1 ainda usa sequência `→ ← → ←` no especial roxo
- [ ] Bolhas de timing exibem a seta correta para cada hit do especial
- [ ] `make gate` verde sem regressão

### 2.2 Sub-fase 2.1 — Diálogo
- [ ] `DialogueScreen` aparece ao entrar no tile de boss na Fase 2
- [ ] Nome **BOITATÁ** exibido em destaque (laranja, fonte grande)
- [ ] Caipora diz "Você nos traiu..." → aguarda input
- [ ] Boitatá responde "Vocês me abandonaram!" → aguarda input
- [ ] Após segundo input, combate inicia com o Boitatá corretamente

### 2.3 Sub-fase 2.2 — Caçador com Tocha
- [ ] Inimigos normais na Fase 2 são Caçador (não Criatura)
- [ ] HP do Caçador = 9
- [ ] Ataque especial do Caçador exibe setas `↑ ↓ ↑ ↓` (4 hits)
- [ ] Dano do especial = 2 por hit que acertar
- [ ] Telegraph do especial: pulso âmbar (diferente do vermelho da criatura)

### 2.4 Sub-fase 2.3 — Boitatá
- [ ] HP do Boitatá = 15
- [ ] Especial branco exibe setas `↑ ↑ ↓ ↓` (4 hits)
- [ ] Dano do especial branco = 3 por hit acertado
- [ ] Intervalo entre hits do branco visivelmente mais rápido que o roxo
- [ ] Telegraph branco: pulso overbright branco (distinto do roxo)
- [ ] Aura de fogo laranja (diferente da aura roxa do boss da Fase 1)

### 2.5 Sub-fase 2.4 — Arena Visual + Mapa
- [ ] Ao sair da Fase 1, jogador vai para Fase 2 (não para tela de WIN)
- [ ] Mapa da Fase 2 tem CanvasModulate alaranjado
- [ ] Tiles de fogo presentes no mapa
- [ ] Pisar em fogo aplica **2 de dano** (não 1)
- [ ] Derrotar inimigo normal na Fase 2 volta para `exploration_phase2`
- [ ] Derrotar Boitatá vai para tela de WIN

### 2.6 Bug conhecido a corrigir antes dos upgrades
A arena retorna `SignalBus.Screen.EXPLORATION` para todos os inimigos derrotados
(`arena_manager.gd:341`). Na Fase 2 isso leva de volta ao mapa errado. **Corrigir como pré-requisito.**

---

## 3. Funcionalidades do Update

### 3.1 Drop de 1.5 Fragmentos na Fase 2

**Comportamento atual:** Derrotar qualquer inimigo não-boss em qualquer fase adiciona exatamente 1 fragmento inteiro.

**Comportamento novo:**
- Fase 1 (exploração normal): mantém drop de 1 fragmento por kill.
- Fase 2 (exploração fase 2): drop de **1,5 fragmentos** por kill.

**Decisão de implementação — fragmento como float acumulador:**

`MetaProgression.fragments` é atualmente `int`. Trocar para `float` internamente. A exibição e os custos de compra continuam tratando como inteiros (floor/ceil conforme o caso). O método `add_fragment()` mantém compatibilidade; um novo método `add_fragments(amount: float)` aceita valores parciais.

```gdscript
var fragments: float = 0.0

func add_fragment() -> void:
    add_fragments(1.0)

func add_fragments(amount: float) -> void:
    fragments += amount
    save_progress()
    SignalBus.fragment_gained.emit(fragments)
```

O save serializa como float; o load usa `float(data.get("fragments", 0))`.

**Onde chamar `add_fragments(1.5)` vs `add_fragment()`:**

A arena_manager chama `MetaProgression.add_fragment()` quando `not GameState.active_combat_is_boss`. O ArenaManager precisa saber se está em Phase 1 ou Phase 2. Usar `GameState.active_phase: int` (ver seção 3.3).

```gdscript
# arena_manager.gd — _on_actor_died
if not GameState.active_combat_is_boss:
    if GameState.active_phase == 2:
        MetaProgression.add_fragments(1.5)
    else:
        MetaProgression.add_fragment()
```

---

### 3.2 Dois Novos Aprimoramentos (Hub Fase 2)

Desbloqueados **apenas** depois que `GameState.active_phase >= 2` (ver seção 3.3). Visíveis e compráveis somente a partir desse ponto.

#### Aprimoramento: Fúria da Floresta
| Campo | Valor |
|-------|-------|
| Chave | `"forca_2"` |
| Nome | Fúria da Floresta |
| Efeito | +1 dano por hit (total 3 hits de dano) |
| Custo | 6 fragmentos |
| Pré-requisito | `forca` comprado + fase 2 alcançada |
| `max_level` | 1 |

**Nota mecânica:** `get_damage_bonus()` retorna `get_upgrade_level("forca") + get_upgrade_level("forca_2")`. Com ambos comprados, `base_attack_damage = 1 + 2 = 3`.

#### Aprimoramento: Pele de Árvore
| Campo | Valor |
|-------|-------|
| Chave | `"saude_2"` |
| Nome | Pele de Árvore |
| Efeito | +2 HP permanente |
| Custo | 9 fragmentos |
| Pré-requisito | fase 2 alcançada (independente de `saude`) |
| `max_level` | 1 |

**Nota mecânica:** `get_health_bonus()` retorna `(get_upgrade_level("saude") + get_upgrade_level("saude_2")) * 2`. Com ambos, +4 HP permanente total.

---

### 3.3 Rastreamento de Fase Alcançada

Novo campo em `MetaProgression` (persistido):

```gdscript
var phase_reached: int = 1
```

Novo campo em `GameState` (volátil, resetado a cada run):

```gdscript
var active_phase: int = 1
```

**Quando atualizar `phase_reached`:**
- Ao entrar em `exploration_phase2.tscn`, chamar `MetaProgression.phase_reached = max(MetaProgression.phase_reached, 2)` e salvar.
- `GameState.active_phase = 2` ao entrar na Fase 2.

**Quando usar:**
- Hub: exibe upgrades de Fase 2 se `MetaProgression.phase_reached >= 2`.
- Arena: determina quantidade de fragmentos no drop.

---

### 3.4 Correção: Retorno da Arena para o Mapa Correto

**Problema:** `arena_manager.gd:341` sempre volta para `Screen.EXPLORATION`.

**Correção:**
```gdscript
# _on_actor_died — arena_manager.gd
if caipora_won:
    if GameState.active_combat_is_boss:
        GameState.change_screen(SignalBus.Screen.WIN)
    else:
        GameState.defeated_enemy_ids.append(GameState.active_map_enemy_id)
        var exploration_screen := SignalBus.Screen.EXPLORATION_PHASE2 \
            if GameState.active_phase == 2 else SignalBus.Screen.EXPLORATION
        GameState.change_screen(exploration_screen)
```

---

## 4. Arquivos a Modificar

| Arquivo | Mudanças |
|---------|---------|
| `scripts/core/meta_progression.gd` | `fragments: float`, `add_fragments(amount)`, `phase_reached: int`, serialização, novos UPGRADE_DEFS |
| `scripts/core/game_state.gd` | `active_phase: int = 1`, resetar no `start_run()` |
| `scripts/exploration/exploration_phase2_manager.gd` | Setar `GameState.active_phase = 2` e `MetaProgression.phase_reached = 2` no `_ready()` |
| `scripts/arena/arena_manager.gd` | Drop por fase (`add_fragments(1.5)` na Fase 2), retorno de arena correto por fase |
| `scripts/ui/hub.gd` | Exibir e construir linhas de `forca_2` e `saude_2` quando `phase_reached >= 2` |
| `scripts/ui/hud.gd` | Popup de fragmento: mostrar "+1.5 fragmentos" na Fase 2 (ler `active_phase`) |

---

## 5. Novos Testes

| Arquivo de teste | O que cobre |
|-----------------|-------------|
| `tests/unit/test_phase2_upgrades.gd` | `add_fragments(1.5)` acumula corretamente; `get_damage_bonus()` soma `forca`+`forca_2`; `get_health_bonus()` soma ambos os níveis de saúde; `phase_reached` persiste no save |
| `tests/unit/test_fragment_drop.gd` | Drop de 1.5 na Fase 2 vs 1.0 na Fase 1 via `active_phase` |

---

## 6. Critérios de Aceitação

- [ ] `make gate` verde após todas as mudanças
- [ ] Fragmentos acumulam como float, exibidos corretamente no Hub e HUD
- [ ] Com 6 fragmentos e fase 2 alcançada, "Fúria da Floresta" aparece no Hub e pode ser comprado
- [ ] Com 9 fragmentos e fase 2 alcançada, "Pele de Árvore" aparece no Hub e pode ser comprado
- [ ] Após comprar "Fúria da Floresta", `base_attack_damage` sobe para 3
- [ ] Após comprar "Pele de Árvore", HP máximo sobe em +2
- [ ] Upgrades de Fase 2 **não aparecem** no Hub se `phase_reached < 2`
- [ ] Derrotar Caçador na Fase 2 dá 1.5 fragmentos (parcial acumulado)
- [ ] Após duas kills na Fase 2, fragmentos aumentam 3.0 (confirmando acumulação float)
- [ ] Derrotar inimigo na Fase 2 arena retorna para `exploration_phase2`, não para `exploration`
- [ ] Derrotar Boitatá ainda vai para a tela de WIN
