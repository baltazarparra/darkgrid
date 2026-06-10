# PLANO — Performance 60fps em todos os devices (incl. Android fraco)

> Plano de execução derivado da auditoria de performance de 2026-06-10
> (camadas de script, rendering e export auditadas; todos os achados de alto
> impacto verificados no código). Meta: **60fps sustentados no export HTML5**,
> piso de hardware = Android de entrada (classe 2020) e iPhone Safari.

---

## 1. Princípios

1. **Medir antes, medir depois.** Nenhuma otimização entra sem baseline no
   device de referência. Estimativas de ms são hipóteses até o profiler confirmar.
2. **Uma tarefa por sessão** (protocolo do projeto). Cada item abaixo é uma
   sessão com commit próprio e gate verde.
3. **Zero regressão de tom.** Nenhuma otimização pode desidratar o gore/terror:
   o fogo continua queimando, o sangue continua espirrando — só que mais barato.
4. **Orçamento de frame:** 16,6ms. Pior caso conhecido: **frame de acerto
   crítico na arena** (hit-stop + screenshake + 3 bursts de partículas +
   re-record do backdrop + DoomFire), e **exploração P3** (fog fullscreen +
   insetos + god rays).

---

## 2. Diagnóstico (resumo da auditoria)

O projeto já acerta a base para GL Compatibility/WebGL2: `CPUParticles2D`
(nunca GPU), gradient map desligado no web, nearest filter, cenas enxutas,
máx. 2 `PointLight2D` por arena. Os gargalos reais são:

| # | Gargalo | Onde | Tipo |
|---|---------|------|------|
| G1 | Simulação de fogo por CPU: ~18k iterações GDScript + `set_pixel` por célula a cada 3 frames, em TODAS as arenas + menu | `scripts/ui/doom_fire.gd:90-115` | CPU (pico recorrente) |
| G2 | Sem pooling de partículas: cada hit instancia nós + materiais; crítico cria 3 sistemas no mesmo frame | `scripts/systems/feedback_system.gd:70-199` | CPU (pico no frame do hit) |
| G3 | Backdrop re-grava ~370 comandos de draw por frame durante o screenshake (parallax via `queue_redraw`) | `scripts/arena/arena_backdrop.gd:121-204` | CPU (pico no frame do hit) |
| G4 | Render na resolução física do device (DPR 2–3x): cada camada fullscreen custa até 9x mais fill-rate | `project.godot` (stretch `canvas_items`) + `export_presets.cfg` | GPU (fill-rate) |
| G5 | Vida ambiente redesenha ~200 primitivas/frame incondicionalmente (formigas/aranhas a 60Hz para mover ≤9px/s) | `scripts/exploration/ambient_life.gd:47-126` | CPU (constante na exploração) |
| G6 | God rays: 3 polígonos aditivos da altura do mapa redesenhados todo frame só para pulsar alpha | `scripts/exploration/forest_ambience.gd:35-66` | CPU+GPU |
| G7 | Shaders fullscreen com `distance()`/hash/`sin` por fragmento, empilhados (atmosphere + fog + DoomFire + scrim) | `assets/shaders/atmosphere.gdshader`, `shaders/fog_reveal.gdshader`, `assets/shaders/title_fire.gdshader` | GPU (overdraw) |
| G8 | `PointLight2D` (lua P1/P3, vitral P5) = passes extras de luz em Compatibility | `scripts/arena/arena_backdrop.gd:287-319` | GPU |
| G9 | Materiais aditivos idênticos duplicados (`CanvasItemMaterial.new()` por emissor/spawn) quebram batching | `furia_visual.gd`, `feedback_system.gd`, `ambient_life.gd`, `forest_ambience.gd`, `arena_backdrop.gd` | GPU (batching) |
| G10 | Áudio WAV PCM cru (~7,2MB) — afeta load no browser, não fps | `assets/audio/` | Load time |

**Falsos positivos já descartados** (não gastar sessão com isso):
`controls_hud` só chama `JavaScriptBridge.eval` em troca de tela (sticky flag
funciona); `HealthBar`/`TimingBubble` redesenham pouco e só quando ativos;
`light_radial.png`/`light_vitral.png` ESTÃO em uso (`forest_ambience.gd:10`,
`arena_backdrop.gd:311`); caminhos de gameplay (`timing_system`,
`arena_manager`, `caipora.gd`) estão limpos.

---

## 3. Fase 0 — Baseline e instrumentação

> Sem isso, as fases 1–3 são fé, não engenharia.

### 0.1 Overlay de frame-time (debug)
- Overlay opcional (query param `?perf=1` ou tecla em debug build) mostrando
  FPS, frame-time médio/p95 e `Performance.get_monitor` (draw calls, objects).
- CanvasLayer próprio, custo zero quando desligado. Sem MCP em cenas (gotcha 7):
  construído por código.

### 0.2 Matriz de medição
| Device | Proxy de desenvolvimento |
|--------|--------------------------|
| Android entrada (ex. Moto G8/Redmi 9) Chrome | Chrome DevTools, CPU throttle 6x |
| iPhone Safari (piso de GPU declarado no projeto) | Safari remote inspector |
| Desktop | referência de controle |

### 0.3 Cenários de baseline (gravar tabela em `docs/REPORT-performance.md`)
1. Menu principal (DoomFire + treelines + embers + atmosphere).
2. Exploração P1 (ambient life + god rays) e P3 (idem + fog of war).
3. Arena P5 (igreja: backdrop mais pesado) em combate ocioso.
4. **Frame de crítico** na arena (pior caso absoluto) — medir spike, não média.

**Critério de saída da fase:** tabela preenchida; pior cenário identificado
com números.

---

## 4. Fase 1 — Picos de CPU (frames de impacto)

> Ordem por (impacto ÷ risco). Todos os itens exigem `make gate`;
> os que tocam arena/timing exigem `/validate-controls` antes do commit.

### 1.1 DoomFire barato (G1) — sessão 1
- `ROWS: 90 → 45` e dobrar o `pix` mínimo em `_rebuild()` (1 constante + 1
  expressão). Corta ~4x o custo de `_update_fire` e `_blit_image`.
- Trocar o loop de `set_pixel` por montar um `PackedByteArray` (paleta
  pré-convertida para bytes RGBA8 em `_ready`) + `Image.set_data()` único.
- **Aceite:** lado a lado visual equivalente (é fundo atrás de céu com alpha);
  frame-time do menu e da arena cai mensuravelmente no throttle 6x.
- **Risco:** baixo. Rollback = reverter constantes.

### 1.2 Pooling no FeedbackSystem (G2 + parte de G9) — sessão 2
- Pré-instanciar no `_ready` da arena um nó por tipo de burst (sangue,
  crítico, morte, faísca, dodge, bubble burst, fail) e reusar com
  `restart()` + reposicionamento. `one_shot` já é o modo de todos.
- Um único `CanvasItemMaterial` aditivo compartilhado (const num helper, ex.
  `Constants` ou classe `SharedMaterials`) substituindo todos os
  `CanvasItemMaterial.new()` de blend ADD do projeto.
- O pool vive na cena da arena (FeedbackSystem é nó da cena, não autoload) —
  morre com a cena, sem risco de vazar entre trocas.
- **Aceite:** zero `instantiate()`/`queue_free()` no caminho do hit;
  gore visualmente idêntico (densidade e cores intactas — tom não negocia).
- **Risco:** médio (timing de `restart` em bursts sobrepostos: crítico +
  morte no mesmo frame precisam de 2 emissores de sangue no pool, não 1).

### 1.3 ArenaBackdrop estático com parallax por `position` (G3) — sessão 3
- Separar céu/lua, chão, igreja/bancos em filhos `Node2D` que desenham **uma
  vez** (cada um com seu `_draw` próprio, `queue_redraw` só no setup).
- Parallax do shake passa a mover `position` dos filhos com os fatores
  `SHAKE_FOLLOW_*` existentes (mudar transform não re-grava comandos).
- Treelines já são nós filhos — só padronizar o caminho.
- **Aceite:** nenhum `queue_redraw` do backdrop durante o shake (verificável
  com contador debug); visual de parallax idêntico.
- **Risco:** médio (ordem de desenho: hoje os filhos treeline desenham depois
  do `_draw` do pai — preservar com `z_index`/ordem de filhos; conferir
  `git diff` visual em P1–P5).

### 1.4 Throttle da vida ambiente (G5, G6) — sessão 4
- `AmbientLife`: simular/redesenhar a 20Hz (acumulador de delta; insetos
  movem ≤9px/s — invisível). Pular `queue_redraw` quando nenhum inseto se
  moveu (aranhas passam a maior parte do tempo paradas).
- `ForestAmbience`: god rays redesenhados a 20Hz, ou (melhor) 3 nós
  `Polygon2D` estáticos pulsando alpha via `modulate` (custo por frame ~0).
- **Aceite:** exploração visualmente idêntica; CPU da exploração cai no
  throttle 6x.
- **Risco:** baixo.

**Critério de saída da fase:** no device de referência, o frame de crítico
não estoura o orçamento (≤1 frame perdido) e a exploração roda 60fps.

---

## 5. Fase 2 — GPU fill-rate

### 2.1 Cap de devicePixelRatio no export web (G4) — sessão 5 ✅ implementado, A/B pendente
- IMPLEMENTADO (refinado durante a execução): heurística de hardware é
  imprevisível (`hardwareConcurrency` mente em phone fraco moderno) — o
  default virou um **cap fixo em DPR 2** via `Object.defineProperty` no
  `head_include`, antes do engine iniciar. Telas 3x (maioria dos Android/
  iPhone atuais) ganham 2,25x menos fill-rate; telas ≤2x ficam intactas.
- `?dpr=1` força cap total (para medir o teto de ganho no device);
  `?dpr=native` é o kill-switch (DPR nativo).
- `image-rendering: pixelated` aplicado ao canvas quando capado (nearest
  upscale — coerente com a arte).
- **Aceite (PENDENTE, exige device real):** fps em arena P5 e exploração P3
  antes/depois no Android de referência; nitidez aprovada a olho; rodar
  `/validate-platforms` no device (gotcha 10).
- **Risco:** médio (tradeoff de nitidez — reversível por query param e por
  revert do `export_presets.cfg`).

### 2.2 Shaders fullscreen mais baratos (G7) — sessão 6
- `atmosphere.gdshader`: vignette via textura radial pré-cozida (256×256,
  1 tap) no lugar de `distance()`; grain via textura de ruído tileable 64×64
  scrollada por TIME no lugar do hash por pixel.
- `fog_reveal.gdshader`: uma frequência de oscilação só (remover o segundo
  `sin` dependente de `SCREEN_UV`).
- `title_fire.gdshader`: só se o menu reprovar na medição (LUT de paleta).
- **Aceite:** diff visual imperceptível em screenshot A/B; gradient map no
  web PERMANECE desligado (`GRADING_ON_WEB = false` — não reabrir).
- **Risco:** baixo.

### 2.3 Luzes → sprites aditivos onde a luz não trabalha (G8) — sessão 7
- Lua P1/P3: substituir `ForestLight`/`PointLight2D` por sprite
  `light_radial.png` com blend ADD (mesmo glow, zero light pass).
- Vitral P5: manter se a medição da Fase 0 aprovar (é assinatura visual da
  igreja); trocar só se P5 reprovar.
- **Aceite:** A/B visual aprovado; teto passa a ser ≤1 luz por arena.
- **Risco:** baixo-médio (a `PointLight2D` interage com `CanvasModulate`
  "devolvendo cor" — o sprite ADD precisa reproduzir isso; validar em P1
  que tem modulate próprio).

### 2.4 Material aditivo compartilhado no resto do projeto (G9) — junto com 2.3
- `furia_visual.gd` (até 7 instâncias), `ambient_life.gd`,
  `forest_ambience.gd`, `arena_backdrop.gd` → usar o material compartilhado
  criado em 1.2.
- **Aceite:** `make gate` verde; contagem de draw calls no overlay cai ou
  estável.

**Critério de saída da fase:** 60fps sustentado em arena P5 e exploração P3
no Android de referência com DPR capado.

---

## 6. Fase 3 — Load time e higiene (não-fps)

### 3.1 Compressão de áudio (G10) — sessão 8
- Decisão prévia necessária: `.import` é gitignored, então configurar
  compressão por arquivo no editor **não persiste para outros clones/CI**.
  Opções: (a) passar a commitar `assets/audio/**/*.import`, ou (b) gerar OGG
  no pipeline (`make audio` já regenera SFX procedural — adicionar passo de
  encode).
- **Aceite:** pck/download menor; `make audio` + check de loudness verdes;
  loops de ambiência sem clique na emenda (atenção: OGG re-encode pode
  deslocar amostras de loop — validar `amb_*.wav` antes de migrar).
- **Risco:** médio (qualidade de loop), por isso fase própria.

### 3.2 Higiene de hot path — sessão 8 (carona)
- Remover/condicionar `print` de build em `controls_hud.gd:68`
  (`OS.is_debug_build()`).
- `fog_of_war.gd`: só atualizar shader params quando a posição mudou
  (epsilon) — micro, carona de outra sessão.

---

## 7. Critérios de aceite globais (definition of done do plano)

1. **60fps sustentados** (p95 ≤ 16,6ms) em: menu, exploração P1/P3, arena
   P1–P5 em combate, no Android de referência e iPhone Safari.
2. **Frame de crítico** perde no máximo 1 frame (sem stutter perceptível).
3. Nenhuma regressão visual/tonal: screenshots A/B por fase arquivados no
   `docs/REPORT-performance.md`.
4. `make gate` verde em todo commit; `/validate-controls` antes de qualquer
   commit que toque arena/exploração/timing; `/validate-platforms` no item 2.1.
5. Tabela baseline vs. final preenchida no REPORT.

## 8. Riscos transversais

- **Gotcha 7 (MCP):** todas as mudanças de cena deste plano são por código —
  nenhum `add_node` via MCP em cenas com autoloads.
- **Otimização prematura de itens descartados:** a lista de falsos positivos
  da §2 existe para não queimar sessão neles.
- **Web é o alvo, desktop é mentira confortável:** medições só valem no
  export HTML5 (GDScript em WASM é 2–4x mais lento que nativo; é lá que os
  picos estouram).
