---
name: validate-platforms
description: Valida o jogo nas 3 plataformas-alvo (iPhone portrait Safari, Android PWA landscape, Tablet landscape) após mudanças em UI, câmera ou safe area.
disable-model-invocation: true
---

# Validação das 3 Plataformas-Alvo

Execute antes de commitar mudanças em: viewport, câmera, HUD, ControlsHud, PortraitGuard,
export_presets.cfg, ou qualquer cena de UI.

---

## Plataforma 1 — iPhone 17 portrait Safari

**Viewport:** ~393×852 CSS px | **Modo:** portrait, browser direto (não PWA)

Simular redimensionando o browser para 393×852 ou usando Chrome DevTools mobile emulator.

- [ ] Overlay "Gire o dispositivo" aparece (texto âmbar `>> <<` sobre fundo escuro)
- [ ] Overlay some ao rotacionar para landscape (viewport.x > viewport.y)
- [ ] Nenhum elemento de game UI vaza por trás do overlay
- [ ] Em landscape no Safari (~852×393): jogo roda normalmente, D-pad visível, combate funcional

**Script:** `scripts/ui/portrait_guard.gd` | Layer: 128 | Threshold: viewport.x < 640

---

## Plataforma 2 — Android Chrome PWA landscape

**Viewport:** ~412×915 landscape (Pixel 8) → ~915×412 | **Modo:** PWA instalada

Testar com Chrome DevTools → Responsive → Pixel 8 → Landscape OU instalar PWA real.

- [ ] PWA manifest bloqueia orientação landscape (`export_presets.cfg`: `pwa/orientation=1`)
- [ ] D-pad aparece (touch device detectado)
- [ ] D-pad não invade safe area lateral (punch-hole camera / notch)
- [ ] D-pad não invade safe area inferior (home indicator / gesture bar Android)
- [ ] Bolhas de timing não nascem atrás do D-pad
- [ ] Exploração: câmera zoom razoável (~0.7–1.0x), mapa visível
- [ ] Arena: combate cabe na tela, timing cues visíveis

**Safe area:** `controls_hud.gd._get_safe_margins()` — mínimo 28px garantido

---

## Plataforma 3 — Tablet+ landscape (padrão)

**Viewport exemplo:** iPad Air 1180×820, iPad Pro 2732×2048 | **Modo:** browser ou PWA

- [ ] Arena zoom ≤ 2.0x (verificar: `_camera.zoom.x` no debug ou print)
- [ ] Combate cabe na tela com margem — inimigo e Caipora visíveis simultaneamente
- [ ] Bolhas de timing têm espaço fora do D-pad (D-pad capped em 140px)
- [ ] HUD HP icons escalam proporcionalmente (não cortados, não gigantes)
- [ ] Exploração: mapa grid visível, câmera segue Caipora
- [ ] Sem letterboxing nem pillarboxing excessivo

**Zoom cap:** `arena_manager.gd:_update_camera_fit()` — `clampf(z, 0.5, 2.0)`

---

## Checklist Rápido

```bash
make test    # 82 testes passando
# Chrome DevTools → Toggle device toolbar → testar:
#   393×852  portrait  → overlay visível
#   852×393  landscape → overlay some, jogo roda
#   1180×820 tablet    → arena zoom ≤ 2.0x
```

Se `/validate-controls` ainda não foi executado nesta sessão, execute também.

---

## Referência de Arquivos

| Arquivo | Responsabilidade |
|---------|-----------------|
| `scripts/ui/portrait_guard.gd` | Overlay portrait iPhone Safari |
| `export_presets.cfg` | PWA orientation lock (Android) |
| `scripts/ui/controls_hud.gd` | D-pad safe area (Android PWA) |
| `scripts/arena/arena_manager.gd` | Zoom cap 2.0x (Tablet+) |
