---
name: validate-controls
description: Valida os dois caminhos de input (teclado + touch D-pad) após mudanças em controles, arena, exploração ou timing. Execute antes de commitar.
disable-model-invocation: true
---

# Validação Dual de Controles

Execute esta checklist completa. Os dois caminhos devem funcionar de forma idêntica.

## Passo 1 — Testes automatizados

```bash
make test
```

Confirmar: `test_touch_controls.gd` (4 testes) e `test_controls_hud.gd` (3 testes) passam.
Se qualquer desses falha, NÃO commitar — corrigir primeiro.

## Passo 2 — Exploração: Teclado

Rodar o jogo (`~/.local/bin/godot --path .`) e validar na tela de exploração:

- [ ] Seta direita → Caipora move +1 tile em X
- [ ] Seta esquerda → Caipora move -1 tile em X
- [ ] Seta cima → Caipora move -1 tile em Y
- [ ] Seta baixo → Caipora move +1 tile em Y
- [ ] Diagonal (direita+cima ao mesmo tempo) → move APENAS em X (cardinal puro)
- [ ] Parede (tile sólido) → movimento bloqueado

## Passo 3 — Exploração: Touch D-pad

Ativar D-pad (Options → Touch Controls → Always) e validar:

- [ ] Botão direito do D-pad → move +1 tile em X
- [ ] Botão esquerdo → move -1 tile em X
- [ ] Botão cima → move -1 tile em Y
- [ ] Botão baixo → move +1 tile em Y
- [ ] D-pad **visível** em telas EXPLORATION, EXPLORATION_PHASE2, EXPLORATION_PHASE3
- [ ] D-pad **invisível** em MAIN_MENU, HUB, GAME_OVER, WIN

## Passo 4 — Combate (Arena): Teclado

Entrar em combate e validar:

- [ ] Tecla correta (ação esperada) na janela verde → PERFECT (screenshake + som)
- [ ] Tecla correta fora da janela → MISS (sem feedback)
- [ ] Tecla errada dentro da janela → MISS
- [ ] Boss especial (Curupira): sequência ←→←→ com o teclado gera série de HITs

## Passo 5 — Combate (Arena): Touch D-pad

- [ ] Tocar D-pad na direção correta durante janela verde → PERFECT
- [ ] D-pad **não** cobre bolhas de timing (bolhas nascem longe do D-pad)
- [ ] Boss especial: sequência de toques na ordem correta avança o padrão

## Diagnóstico Rápido

**Falha só no touch, passa no teclado:**
- `ControlsHud._feed_event()` não está chamando `Input.parse_input_event()` corretamente
- A action string no D-pad não coincide com `TimingSystem._expected_action`
- `_on_pressed()` chamado sem `_on_released()` correspondente (action presa)

**Falha só no teclado, passa no touch:**
- `_get_cardinal_input()` usando action string diferente da que o D-pad injeta
- InputMap não tem a tecla física mapeada para a action

## Arquivos Críticos

| Arquivo | Função-chave | Responsabilidade |
|---------|-------------|-----------------|
| `scripts/ui/controls_hud.gd` | `_on_pressed(action)` | Injeção dupla D-pad |
| `scripts/entities/caipora.gd` | `_get_cardinal_input()` | Polling exploração |
| `scripts/systems/timing_system.gd` | `_input(event)` | Event listener combate |
| `scripts/arena/arena_manager.gd` | `_is_under_dpad()` | Posicionamento bolhas |
| `tests/unit/test_touch_controls.gd` | 4 testes | Contrato injeção dual |
