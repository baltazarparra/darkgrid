---
name: validate-platforms
description: Valida o jogo nas plataformas-alvo (orientação LIVRE — retrato e paisagem) — iPhone/Android telefone nas duas orientações e tablet — após mudanças em UI, câmera, orientação ou safe area.
disable-model-invocation: true
---

# Validação das Plataformas-Alvo (orientação livre)

Execute antes de commitar mudanças em: viewport, câmera, HUD, ControlsHud,
export_presets.cfg, ou qualquer cena de UI.

> **Pivot de orientação (Fase 10):** NÃO há mais orientação travada nem overlay
> "gire o dispositivo". O jogador escolhe girando o aparelho; o layout responde a
> `size_changed`. O viewport-base segue 750×1334 (retrato), mas TODA tela precisa
> funcionar nas duas orientações.
>
> **Armadilha de enum:** no exporter web do Godot, `progressive_web_app/orientation`
> é `0=Any, 1=Landscape, 2=Portrait` (gerou a trava acidental de paisagem no passado).
> O projeto usa `0` (Any). `project.godot handheld/orientation=6` (SENSOR).

---

## Plataforma 1 — Telefone retrato (iPhone Safari / Android Chrome)

**Viewport:** ~393×852 CSS px | **Modo:** browser direto ou PWA

Simular redimensionando o browser ou usando Chrome DevTools mobile emulator.

- [ ] Jogo roda, sem overlay bloqueante, D-pad visível embaixo
- [ ] Exploração: as **26 colunas** do mapa cabem na largura (contain na largura), rola na vertical
- [ ] Arena: combate enquadrado no espaço **acima** do D-pad (não no centro morto da tela alta)
- [ ] D-pad escala 1.5× e respeita a trava de largura (`DPAD_MAX_WIDTH_FRACTION`)

---

## Plataforma 2 — Telefone PAISAGEM (iPhone Safari / Android Chrome)

**Viewport:** ~852×393 CSS px | **Modo:** browser direto ou PWA

Era bloqueada pelo antigo PortraitGuard — agora é cidadã de primeira classe.

- [ ] Jogo roda, sem overlay; D-pad escala 1.3×
- [ ] Safe area lateral (notch deitado) respeitada via CSS `env()` (`controls_hud.gd`)
- [ ] Arena: Caipora e Criatura visíveis simultaneamente; bolhas de timing fora do D-pad
- [ ] Exploração: câmera segue a Caipora; HUD não cobre a ação
- [ ] Hub: cards de aprimoramento acessíveis (layout responde a `is_portrait`)

---

## Plataforma 3 — Giro DURANTE o jogo

- [ ] Girar retrato↔paisagem em cada tela (menu, exploração, arena, hub, diálogo):
  layout recalcula no `size_changed`, nada vaza nem some
- [ ] PWA manifest exportado: `"orientation":"any"` (`export/index.manifest.json`)

---

## Plataforma 4 — Tablet (retrato ou paisagem)

**Viewport exemplo:** iPad Air 820×1180 retrato | 1180×820 paisagem | **Modo:** browser ou PWA

- [ ] Arena zoom ≤ 2.0x (verificar: `_camera.zoom.x` no debug ou print)
- [ ] Combate cabe na tela — inimigo e Caipora visíveis simultaneamente
- [ ] HUD: barras de vida escalam proporcionalmente, sem colidir nem cortar
- [ ] Exploração: mapa grid visível, câmera segue a Caipora; sem letterbox excessivo

**Zoom cap:** `arena_manager.gd:_update_camera_fit()` — `clampf(z, 0.5, 2.0)`

---

## Checklist Rápido

```bash
make test
# Chrome DevTools → Toggle device toolbar → testar:
#   393×852  retrato   → jogo roda, D-pad 1.5×, mapa de 26 colunas visível
#   852×393  paisagem  → jogo roda, D-pad 1.3×, safe area lateral ok
#   1180×820 tablet    → arena zoom ≤ 2.0x
# Girar em cada tela: layout recalcula sem vazamento
```

Se `/validate-controls` ainda não foi executado nesta sessão, execute também.

---

## Referência de Arquivos

| Arquivo | Responsabilidade |
|---------|-----------------|
| `project.godot` | Viewport 750×1334 + `handheld/orientation=6` (SENSOR) |
| `export_presets.cfg` | `progressive_web_app/orientation=0` (Any — sem trava) |
| `scripts/utils/constants.gd` | `is_portrait()` + `PHONE_SHORT_SIDE_MAX` (fonte da orientação) |
| `scripts/ui/controls_hud.gd` | D-pad + safe area + trava de largura + escala por orientação |
| `scripts/entities/caipora.gd` | Câmera de exploração (contain na largura) |
| `scripts/arena/arena_manager.gd` | Zoom cap 2.0x + lift da ação acima do D-pad |
