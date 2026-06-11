# PRD — Upgrade Visual da Exploração: Profundidade do Chão + Vivos vs Estáticos

**Status:** aprovado para implementação
**Data:** 2026-06-10
**Escopo:** SOMENTE o modo exploração (mapa top-down). A arena de combate NÃO é tocada.

---

## 1. Problema

1. **O chão não passa nenhuma profundidade.** O TileMap da exploração é pintado com
   4 variantes uniformes e só o `CanvasModulate` da fase escurece tudo por igual —
   nenhuma variação de brilho por célula, nenhuma oclusão junto às paredes, nenhuma
   leitura de volume. O chão está claro demais e lê plano.
2. **Pouco contraste entre vivos e estáticos.** Caipora e inimigos do mapa não se
   destacam o suficiente das decorações (`MapObject`). Falta camada visual que
   diga ao olho "isto está vivo, isto é cenário".

## 2. Objetivos

- Chão da exploração mais escuro, rico e com profundidade real (textura + sombreamento).
- Entidades vivas saltando da cena por silhueta, luz, sombra e movimento.
- Decorações estáticas recuando ao fundo.
- Zero regressão de performance no export web (gl_compatibility, mobile).
- Horror reforçado, nunca suavizado — mais escuro/sangrento é a direção certa.

## 3. Não-objetivos

- Arena de combate (chão procedural da arena já tem gradiente de profundidade).
- Sprites das entidades (não redesenhar Caipora/inimigos; só camadas ao redor).
- `CanvasModulate` por fase (vive nos `.tscn`; edição manual é proibida — gotcha #7).
- Novas `PointLight2D` para o chão (orçamento de luzes já alto: fase 2 ≈ 50 luzes
  com `enhance_fire`; exceção única: a front light da Caipora, ver R3.3).

## 4. Fatos do código (verificados)

| Fato | Onde |
|---|---|
| TileMap montado em runtime; sources 0 (chão) e 1 (parede); pintura determinística por hash | `scripts/exploration/exploration_manager.gd` — `_setup_tilemap()` (l.513), `_paint_map()` (l.537-547) |
| Inimigos do mapa JÁ têm sombra oval (1.0×0.35) e front light; NÃO têm outline nem respiração | `scripts/exploration/map_enemy.gd` — `_spawn_shadow()` (l.115), `_spawn_front_light()` (l.124) |
| Caipora tem sombra pequena (0.5×0.18) e NENHUMA front light própria; na fase 2 (`Aura.NONE`) anda apagada | `scripts/entities/caipora.gd:56-63`; `exploration_manager.gd:564` |
| Fase 5 (igreja) usa `tile_floor_church.png` — mudanças de chão cobrem a igreja | `_build_profile()` (exploration_manager.gd:641-642) |
| Contratos de teste: atlas 128×32; contact/value sheets 528×608; luminância chão−parede > 15 (floresta) / > 35 (igreja); < 12 px de preto puro no chão; acento laranja entre 12 e 180 px | `tests/unit/test_tile_identity_assets.gd` |
| Outline shader existente, aplicado na arena por instância | `shaders/enemy_outline.gdshader`; `criatura.gd:131-136` |
| Respiração idle existente na arena (tween de `scale:y` em loop) | `scripts/systems/actor_animator.gd:152-162` |
| Material aditivo compartilhado (obrigatório p/ não quebrar batching no web) | `Constants.ADDITIVE_MATERIAL` (constants.gd:98) |

**Identidade visual** (`.agents/skills/visual-identity/SKILL.md`, `docs/CONCEITO-protagonista.md`):
a Caipora NÃO recebe outline branco — o glow branco-quente é assinatura dos invasores.
Ela se diferencia por juba laranja + FuriaVisual + luz + sombra. Não re-escurecer o
sprite dela.

## 5. Requisitos

### R1 — Texturas de chão mais escuras e ricas (`scripts/tools/gen_tiles.py`)

- **R1.1** Rebaixar a paleta de terra: `EARTH (88,52,45)→(72,42,36)`,
  `EARTH_DARK (54,29,24)→(42,23,19)`, `EARTH_WET (70,39,35)→(54,30,27)`;
  novo `EARTH_DEEP (30,16,13)` para poças de escuridão (nunca preto puro).
- **R1.2** Mais contraste interno por variante: ruído 0.15 → ~0.22 puxando para os
  escuros; 1–2 blobs grandes de `EARTH_DEEP` por variante; raízes `BARK_DARK` mais
  grossas; acento laranja mantido dentro de 12–180 px (contrato de teste).
- **R1.3** Igreja: sujar `_church_floor_variant` (juntas mais escuras, fuligem nos
  cantos) sem violar a separação de luminância > 35 com a parede.
- **R1.4** Manter 4 variantes (subir exigiria mudar `FLOOR_VARIANTS`, contratos e
  dimensões dos sheets; R2 multiplica leituras: 4 variantes × 3 níveis de brilho).
- **R1.5** Novo atlas de oclusão `tile_shade.png` (96×32, 3 tiles de 32px):
  `edge` (sombra em degraus duros de alpha 0.45/0.30/0.15 — pixel-art chapada, sem
  gradiente), `corner` (2 degraus), `edge_deep` (mais funda, p/ corredores da fase 3).
  Fica FORA do contact sheet (preserva o contrato 528×608).
- **R1.6** Caso de teste novo para `tile_shade.png` (96×32) em
  `test_tile_identity_assets.gd`.
- **R1.7** Risco a observar: marcador de saída `SIMPLE` (exploration_manager.gd:267-272)
  usa o atlas com modulate `COLOR_EXIT` — se perder punch, subir o alpha de
  `COLOR_EXIT` no mesmo commit.

### R2 — Sombreamento runtime do chão (novo `scripts/exploration/floor_shading.gd`)

**Técnica: alternative tiles com `TileData.modulate` + camadas extras de AO no mesmo
TileMap.** Custo zero por frame (decidido no paint), batching preservado, sem shader
de tela cheia, sem luz nova. Descartados: sprites de sombra individuais (centenas de
nós), shader por pixel no TileMap (caro em gl_compatibility), PointLight2D (orçamento).

- **R2.1** Helper estático `FloorShading` (padrão `ForestLight`/`FireEffect`).
  `register_alternatives(floor_source)`: para cada variante, 3 alternativas com
  modulate `0.92×`, `0.84×` e "moonlit" fria `~(1.10, 1.12, 1.22)` — constantes novas
  `FLOOR_SHADE_LEVELS` / `FLOOR_MOON_TINT` em `constants.gd`. Tiles de chão não têm
  colisão (caminhabilidade é por `source_id`, sempre camada 0) — sem regressão.
- **R2.2** Variação por célula em `_paint_map()`: alternativa por hash determinístico
  `(x*31 + y*17 + seed) % N`; 2–4 clusters de luar por mapa (BFS raso a partir de
  células sorteadas com o seed da fase) usando a alternativa moonlit. Opcional barato:
  1 `Sprite2D` `light_radial.png` + `ADDITIVE_MATERIAL`, alpha ~0.06, por cluster.
- **R2.3** Oclusão de borda (AO): source novo (id 2) com `tile_shade.png` + 2 camadas
  novas no TileMap (AO-NS e AO-WE, para célula com parede ao N E a W receber as duas).
  Parede ao N → `edge`; S → `edge` flip_v; W/E → `edge` transpose+flip; diagonal
  isolada → `corner`. Fase 3 (corredores de 1 tile) usa `edge_deep`.
- **R2.4** Integração: `_setup_tilemap()` chama `FloorShading.register_alternatives()`
  e cria source/camadas; `_paint_map()` delega escolha de alternativa e pintura de AO.
  Camada 0 intacta (testes de fase checam sources por id).
- **R2.5** Teste novo `tests/unit/test_floor_shading.gd`: TileMap com ≥3 camadas;
  célula adjacente a parede tem AO pintado; alternativas registradas no source 0.

### R3 — Vivos com mais presença

- **R3.1** Outline nos inimigos do mapa (`map_enemy.gd`): aplicar
  `shaders/enemy_outline.gdshader` no `Sprite2D` (mesmo padrão de
  `Criatura._apply_outline_shader()`). Defaults servem; expor
  `MAP_ENEMY_OUTLINE_THICKNESS` em `constants.gd`. Vale para comuns, minibosses e
  boss (`COLOR_BAPTISM_TINT` em modulate não interfere — glow é cor fixa do shader).
- **R3.2** Caipora SEM outline (identidade visual — ver §4).
- **R3.3** Caipora (`caipora.gd`): sombra de 0.5×0.18 → ~0.85×0.30 (constante
  `CAIPORA_MAP_SHADOW_SCALE`); front light própria permanente em `_ready()` via
  `ForestLight.make(COLOR_ENEMY_FRONT_LIGHT, energy≈0.45, scale≈1.2)` — modesta,
  resolve a fase 2 apagada. Custo: +1 luz no total.
- **R3.4** Respiração idle: extrair helper `scripts/utils/idle_breath.gd`
  (`class_name IdleBreath`, `static func attach(sprite, base_scale, period≈1.1,
  amp≈0.015) -> Tween`) do loop de `ActorAnimator._start_breathing()`; refatorar
  `ActorAnimator` para delegar (fonte única; segue guardando o Tween p/ pausar no
  squash). Aplicar em `MapEnemy.setup()` (delay inicial `randf()*period` para não
  respirarem em uníssono) e no `_animated_sprite` da Caipora exploração.

### R4 — Rebaixar os estáticos (`map_object.gd:setup()`, l.24-31)

- **R4.1** Para `type in DECO_TYPES or type in CHURCH_PROPS` exceto `CANDLE` (fonte
  de luz acesa): `modulate = Constants.COLOR_DECO_DIM` — constante nova
  `~Color(0.62, 0.62, 0.70)` (escurece e esfria; multiply frio aproxima dessaturação
  sem shader).
- **R4.2** NÃO tocar: `FIRE`, `SPIKE` (hazards precisam de contraste), `CHEST`,
  `KEY`, `BAG`, `BURROW` (interativos). `AmbientLife` fica como está.
- **R4.3** Documentar a constante na seção de materiais de props em `constants.gd`.

## 6. Plano de entrega (1 commit por etapa, nesta ordem)

| Etapa | Conteúdo | Arquivos principais |
|---|---|---|
| 1 | R1 — texturas (chão + igreja + tile_shade.png) | `gen_tiles.py`, `test_tile_identity_assets.gd` |
| 2 | R2 — FloorShading (alternativas + AO + luar) | `floor_shading.gd` (novo), `exploration_manager.gd`, `constants.gd`, `test_floor_shading.gd` (novo) |
| 3 | R3 — outline + sombra/luz Caipora + respiração | `map_enemy.gd`, `caipora.gd`, `idle_breath.gd` (novo), `actor_animator.gd`, `constants.gd` |
| 4 | R4 — rebaixar estáticos | `map_object.gd`, `constants.gd` |

A Etapa 2 depende do PNG da Etapa 1. Demais são independentes.

## 7. Critérios de aceite (verificação visual via screenshots, WSLg `:0`)

Tirar screenshots com `scripts/tools/screenshot.gd` nas fases 1, 3 (corredores/AO)
e 5 (igreja). Checar:

- [ ] Chão lê mais escuro/rico, mas a parede AINDA é claramente mais escura que o chão.
- [ ] Sombra de oclusão nas células coladas em parede, sem padrão de grade visível.
- [ ] Variação de brilho por célula sutil + 2–4 poças de luar por mapa.
- [ ] Inimigos com glow de contorno e respirando (desfasados entre si).
- [ ] Caipora com sombra/luz reforçadas e SEM glow; visível na fase 2.
- [ ] Decorações recuadas; fogo, espinho, baú, chave, bolsa e toca ainda saltando.
- [ ] Marcador de saída legível em todas as fases.
- [ ] Checklist da skill visual-identity (§5): Caipora segue a marca mais memorável
      da tela; horror mais escuro, nunca suavizado.

## 8. Gates técnicos (por etapa)

1. PNG mudou → `python3 scripts/tools/gen_tiles.py && ~/.local/bin/godot --headless --import`.
2. `class_name` novo (Etapas 2 e 3) → `godot --headless --import` ANTES de `make test`;
   confirmar que o total de testes SUBIU no sumário do GUT (gotcha #12 — GUT mente verde).
3. `make gate` (smoke + GUT) — atenção a `test_tile_identity_assets.gd` na Etapa 1.
4. Antes do commit final: `/validate-controls` (mudanças tocam exploração).
