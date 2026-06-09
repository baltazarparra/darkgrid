---
name: validate-platforms
description: Valida o jogo nas plataformas-alvo (retrato é primário) — iPhone/Android retrato e tablet — após mudanças em UI, câmera, orientação ou safe area.
disable-model-invocation: true
---

# Validação das Plataformas-Alvo (retrato primário)

Execute antes de commitar mudanças em: viewport, câmera, HUD, ControlsHud, PortraitGuard,
export_presets.cfg, ou qualquer cena de UI.

> **Pivot de orientação:** retrato é a orientação PRIMÁRIA (viewport-base 750×1334,
> `project.godot handheld/orientation=1`). O overlay "Gire o dispositivo" agora pede para
> girar quando um TELEFONE está em PAISAGEM — o inverso do comportamento antigo.

---

## Plataforma 1 — iPhone retrato Safari (primária)

**Viewport:** ~393×852 CSS px | **Modo:** portrait, browser direto (não PWA)

Simular redimensionando o browser ou usando Chrome DevTools mobile emulator.

- [ ] Em RETRATO (~393×852): jogo roda, **sem** overlay, D-pad visível embaixo-direita
- [ ] Exploração: as **26 colunas** do mapa cabem na largura (contain na largura), rola na vertical
- [ ] Arena: combate enquadrado no espaço **acima** do D-pad (não no centro morto da tela alta)
- [ ] Overlay "Gire o dispositivo" (âmbar `>> <<` sobre fundo escuro) aparece ao girar para LANDSCAPE
- [ ] Nenhum elemento de game UI vaza por trás do overlay

**Script:** `scripts/ui/portrait_guard.gd` | Layer: 128 | Mostra quando: web + paisagem +
`minf(vp.x, vp.y) < Constants.PHONE_SHORT_SIDE_MAX` (640)

---

## Plataforma 2 — Android Chrome PWA retrato

**Viewport:** ~412×915 retrato (Pixel 8) | **Modo:** PWA instalada

Testar com Chrome DevTools → Responsive → Pixel 8 (retrato) OU instalar PWA real.

- [ ] PWA manifest trava orientação retrato (`export_presets.cfg`: `pwa/orientation=1`)
- [ ] D-pad aparece (touch device detectado)
- [ ] D-pad respeita a trava de largura (`DPAD_MAX_WIDTH_FRACTION`), sem estourar a tela estreita
- [ ] D-pad não invade safe area inferior (home indicator / gesture bar Android)
- [ ] Bolhas de timing não nascem atrás do D-pad
- [ ] Exploração: mapa inteiro visível na largura; Arena: combate e timing cues visíveis

**Safe area:** `controls_hud.gd._get_safe_margins()` — mínimo 28px garantido

---

## Plataforma 3 — Tablet (retrato ou paisagem)

**Viewport exemplo:** iPad Air 820×1180 retrato | 1180×820 paisagem | **Modo:** browser ou PWA

Tablet/desktop (lado curto ≥ 640) **não** recebem o overlay — jogam em qualquer orientação.

- [ ] Tablet em paisagem (1180×820): **sem** overlay (isenção `minf ≥ 640`), jogo jogável
- [ ] Arena zoom ≤ 2.0x (verificar: `_camera.zoom.x` no debug ou print)
- [ ] Combate cabe na tela — inimigo e Caipora visíveis simultaneamente
- [ ] Bolhas de timing têm espaço fora do D-pad
- [ ] HUD: barras de vida escalam proporcionalmente, sem colidir nem cortar
- [ ] Exploração: mapa grid visível, câmera segue a Caipora; sem letterbox excessivo

**Zoom cap:** `arena_manager.gd:_update_camera_fit()` — `clampf(z, 0.5, 2.0)`

---

## Checklist Rápido

```bash
make test    # 201 testes passando
# Chrome DevTools → Toggle device toolbar → testar:
#   393×852  retrato   → jogo roda, sem overlay, mapa de 26 colunas visível
#   852×393  paisagem  → overlay "Gire o dispositivo" aparece (telefone)
#   1180×820 tablet    → sem overlay, arena zoom ≤ 2.0x
```

Se `/validate-controls` ainda não foi executado nesta sessão, execute também.

---

## Referência de Arquivos

| Arquivo | Responsabilidade |
|---------|-----------------|
| `project.godot` | Viewport 750×1334 + `handheld/orientation=1` (retrato) |
| `scripts/ui/portrait_guard.gd` | Overlay "gire" para telefone em PAISAGEM |
| `scripts/utils/constants.gd` | `is_portrait()` + `PHONE_SHORT_SIDE_MAX` (fonte da orientação) |
| `export_presets.cfg` | PWA orientation lock retrato (Android) |
| `scripts/ui/controls_hud.gd` | D-pad + safe area + trava de largura |
| `scripts/entities/caipora.gd` | Câmera de exploração (contain na largura) |
| `scripts/arena/arena_manager.gd` | Zoom cap 2.0x + lift da ação acima do D-pad |
