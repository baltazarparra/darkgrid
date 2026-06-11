# PRD — Fase Final: A Igreja na Mata (O Catequizador)

> A quinta e **última** fase de **caipora**: o interior de uma igreja colonial
> erguida dentro da floresta. O chefe é o **Jesuíta Bandeirante Catequizador** —
> que abre a fase declarando que *converteu* os antigos encantados. Por isso os
> "monstros" desta tela **são os outros quatro chefes** (Mula sem Cabeça, Boitatá,
> Curupira, Saci), agora catequizados e a serviço do altar. No fundo da nave, o
> próprio Jesuíta, cujo moveset reúne **todos os ataques de todos os chefes**.
>
> Encadeia depois da Fase 4 (Saci) e **substitui** o caminho direto P4→ENDING:
> agora P4(boss)→**Fase 5**→ENDING. É a fase mais difícil do jogo.

---

## 1. Decisões de design (travadas com o autor)

| Eixo | Decisão |
|------|---------|
| **Janela de reação** | A **mais dura de todas**. A Fase 5 encurta a janela **0.2s ALÉM** da Fase 4 — `PHASE5_TIMING_REDUCTION = 0.50` (0.30 da P4 + 0.20), travado no piso de `0.2s` de `_phase_window`. Vale para mini-bosses e para o Jesuíta. |
| **HP dos mini-bosses** | **HP cheio de chefe** — 12/22/30/36 (Mula/Boitatá/Curupira/Saci). Gauntlet de resistência: quatro lutas longas + o chefe final. |
| **Assets "AAA premium"** | **Pipeline procedural no máximo** — `gen_chars.py` (Jesuíta), `gen_tiles.py` (igreja), `gen_sfx.py`/`AudioDirector` (stem órgão+maracatu corrompido, sino, sibilo de água benta). Reproduzível, CC0, leve para browser. |

---

## 2. Narrativa & tom

**Gancho:** a fala de abertura do Jesuíta — *"converti todos eles com espelhos e
água benta. a floresta pertence ao vaticano."* — **é** a explicação diegética de
por que os outros chefes aparecem como capangas: ele os **converteu**. Mula,
Boitatá, Curupira e Saci vagam a nave como fiéis quebrados, com cacos de espelho
e marcas de batismo. A Caipora desce a nave desfazendo cada conversão à força até
o altar, onde o catequizador a espera.

**Diálogo de ABERTURA DA FASE** (exigência do autor: *antes do início da fase*,
não na porta do chefe). Roda no `_ready()` da exploração da Fase 5, **uma vez**,
na entrada fresca (trava o movimento até dispensar):

```
JESUÍTA BANDEIRANTE CATEQUIZADOR — "converti todos eles com espelhos e água benta.
                                    a floresta pertence ao vaticano."
CAIPORA                          — "teus santos viram húmus na minha mata."
```

> A 2ª fala é proposta (mantém o tom GORE/TERROR e a voz ambígua da Caipora). O
> autor pode trocá-la; a 1ª é canônica e literal ao pedido.

**Encontro do chefe final:** mantém a apresentação estilo Mega Man (revelação do
nome "JESUÍTA BANDEIRANTE CATEQUIZADOR" — nome longo já cai em 2 linhas pelo
word-wrap do `BossIntroScreen`). **Sem** diálogo extra na porta (a fala marcante
já foi dita na abertura) — `boss_dialogue` vazio, indo direto da intro à arena.

**Tom:** não suavizar. A igreja é fria, úmida, com cera derretida, água benta
estagnada virando lodo, espelhos rachados que refletim olhos no escuro, sangue
seco no altar. O sagrado colonial aqui é o invasor; a mata é a vítima e a vingança.

> **Retcon canônico (Santuário dos Encantados, 2026-06):** com a libertação
> definitiva dos encantados — o golpe final da Caipora liberta o espírito, que passa
> a viver em paz no acampamento ([PRD-santuario-dos-encantados.md](PRD-santuario-dos-encantados.md))
> — os "convertidos" da nave passam a ser, canonicamente, **cascas batizadas**:
> simulacros ocos que o Jesuíta moldou com espelhos e água benta sobre a FORMA dos
> encantados, não os espíritos verdadeiros. Isso fortalece o horror dele (profanou
> até a forma deles) e mantém a Fase 5 com dificuldade cheia mesmo com o santuário
> completo. A fala de abertura segue literal — o Jesuíta acredita que os converteu.

---

## 3. Mapeamento na arquitetura (o que muda, e onde)

A Fase 5 entra como **dado**, reusando o `exploration_manager.gd` único e o
`ArenaManager`. Nenhuma reescrita de sistema — só novos casos de fase, um chefe
novo e dois flags pequenos.

### 3.1 Telas & roteamento
- `SignalBus.Screen`: **append** `EXPLORATION_PHASE5, ARENA_PHASE5` (no fim do
  enum — não desloca valores existentes).
- `GameState._scene_path_for()`: dois casos novos → `exploration_phase5.tscn` /
  `arena_phase5.tscn`.
- `arena_manager._resolve_next_screen()`:
  - **P4 boss (Saci) win:** `ENDING` → **`EXPLORATION_PHASE5`** (passa a avançar,
    não encerrar).
  - **P5 boss (Jesuíta) win:** → `ENDING`.
  - **P5 comum win / P5 não-boss:** → `EXPLORATION_PHASE5`.
- `arena_manager._screen_phase()`: `EXPLORATION_PHASE5 → 5` (faz P4→P5 contar como
  avanço de fase, roteando pelo **acampamento/HUB** via `advance_phase_via_hub`).
- `arena_manager._on_actor_died()` (marcos de fase): ao matar o **Saci (P4 boss)**,
  `phase_reached = 5`; ao matar o **Jesuíta (P5 boss)**, `phase_reached = 6`.
  T5 é pós-primeira vitória (`wins_required=1`); T6 exige o marco pós-Jesuíta e
  3 vitórias (`wins_required=3`).

### 3.2 Geração — `MapConfig.for_phase(5)`
- `topology_mode = OPEN` (a nave é um salão; pilares = colunata da igreja).
- `boss_type = "jesuita"`.
- `enemy_count = 5` → **4 mini-bosses + 1 Jesuíta** (o gerador marca o mais
  profundo como boss = o Jesuíta no altar).
- `common_types = ["mula", "boitata", "curupira", "saci"]` via `_common_mix(5)`
  (um de cada; sem repetição — são exatamente os quatro chefes anteriores).
- `hazard_chars = ["R"]`, densidade baixa (`~0.05`) — fogo votivo / círios.
- `pillar_density ~0.06`, `decoration_count ~44`.
- `has_exit = false` (progride ao derrotar o Jesuíta → ENDING; sem tile `E`).
- `has_fog = false`, `has_chest/has_key = false`.

### 3.3 Os 4 mini-bosses como "monstros" comuns
A sacada: spawná-los como inimigos **comuns cuja cena é a cena de chefe**, sem o
cerimonial (sem Mega Man por mini-boss). Cada classe de chefe já traz seu moveset
em `get_attack_pattern()` e seus telegraphs — tudo cai de graça.

- `exploration_manager.REGULAR_SCENES` ganha `"mula"/"boitata"/"curupira"/"saci"`
  → `MULA_SCENE/BOITATA_SCENE/CURUPIRA_SCENE/SACI_SCENE`. Assim `_regular_scene_for`
  já resolve a cena certa, roteando como **comum** (sem intro/diálogo).
- **HP cheio:** hoje `_spawn_enemy` sobrescreve o HP do comum por
  `common_health_for_phase` quando `not active_combat_is_boss`. Para preservar o
  HP de chefe da cena, adiciona-se um flag volátil `GameState.active_combat_keeps_own_hp`
  (setado em `_trigger_combat` quando `enemy_type ∈ {mula,boitata,curupira,saci}`),
  e `_spawn_enemy` pula a sobrescrita quando ligado. Reset após uso, como
  `next_enemy_scene`.
- **Render no mapa:** `MapEnemy` já tem as 4 texturas e cores de aura (hoje só sob
  `is_boss`). Estende-se o ramo `else` (não-boss) para reconhecer esses
  `enemy_type` e usar a textura + aura de chefe correspondentes — mantendo
  `is_boss = false` (roteamento de combate segue "comum"). Alcance de aggro pode
  subir para esses (são chefes): opcional `BOSS_CHASE_RANGE`.
- **Recompensa:** seguem como comuns (snowball ½ HP + cura 1 + fragmentos), com
  `COMMON_FRAGMENT_REWARD[5]` novo (proposto `5`). Evita inundar a economia e
  mantém o boss bounty como o grande prêmio.

### 3.4 O chefe final — `jesuita.gd`
Classe nova `class_name Jesuita extends Saci` (herda telegraphs de rastro/assobio
e o salto duplo). Sobrescreve **só** `get_attack_pattern()` para sortear
**uniformemente** entre **todos os padrões de todos os chefes** ("mesma chance"):

| # | Padrão | Origem | Telegraph |
|---|--------|--------|-----------|
| 1 | `CRIATURA_PATTERN` | base | normal |
| 2 | `SPECIAL_PATTERN` | Boss | roxo/fogo |
| 3 | `DOUBLE_BLOCK_PATTERN` | Boss | normal (duplo) |
| 4 | `WHITE_SPECIAL_PATTERN` (↑↑↓↓) | Boitatá | branco overbright |
| 5 | `RASTRO_PATTERN` (←→←→) | Curupira | verde-mata |
| 6 | `ASSOBIO_PATTERN` (janela mínima, 3×) | Curupira | salto duplo |
| 7 | `SACI_RASTRO_PATTERN` (rastro acelerado) | Saci | fogo |

`get_attack_pattern()` escolhe `1/7` para cada um, setando os `_current_is_*`
corretos (`_current_is_special/_current_is_rastro/_current_is_assobio/
_current_is_white_special`) para o telegraph certo disparar. Como `Boitata` é a
única dona de `WHITE_SPECIAL_PATTERN` e `_current_is_white_special`, o Jesuíta
**redeclara** essa const + flag e estende `_play_windup_telegraph()` para cobrir o
branco do Boitatá além do que herda do Saci. (Alternativa de menor acoplamento:
extrair os padrões para um `BossPatterns` compartilhado — anotado como follow-up;
para o escopo, redeclarar a const é suficiente.)

- **−0.2s e +1 hit:** NÃO vivem na classe — são **da fase** (§3.5). Assim o
  Jesuíta e os 4 mini-bosses compartilham exatamente o mesmo endurecimento, como
  pedido ("o mesmo comportamento").
- `JESUITA_MAX_HEALTH` (proposto `44`) na cena `jesuita.tscn`; `BOSS_FRAGMENT_BOUNTY[5]`
  (proposto `20`). Aura própria `COLOR_AURA_JESUITA` (fumaça de incenso podre —
  dourado-acinzentado corrompido) e telegraph `COLOR_TELEGRAPH_JESUITA`.

### 3.5 Dificuldade da Fase 5 (parametrizada, fonte única)
Em `constants.gd`:
```gdscript
# ─── Fase 5 (A Igreja) ─────────────────────────────
# A fase final: a mais impiedosa. Janela encurta 0.2s ALÉM da Fase 4
# (0.30 + 0.20 = 0.50 "mais rápido", travado no piso de 0.2s de _phase_window)
# e cada golpe de inimigo bate +1 (PHASE5_ENEMY_DAMAGE_BONUS).
const PHASE5_TIMING_REDUCTION := 0.50
const PHASE5_ENEMY_DAMAGE_BONUS := 1.0
```
- `arena_manager._phase_window()`: novo caso `5: return maxf(base - PHASE5_TIMING_REDUCTION, 0.2)`.
- `arena_manager._on_defense_timing_result()`: novo ramo `elif GameState.active_phase == 5: damage += Constants.PHASE5_ENEMY_DAMAGE_BONUS`.
- `Constants.caipora_base_damage_for_phase(5) = 1`; a fase não soma dano. O HP
  de comum não se aplica (mini-bosses usam HP próprio), e o dano vem da Fúria/CHAMA.

> **Nota de tuning:** com `−0.50`, padrões de janela curta (ASSOBIO) tocam o piso
> de `0.2s`. É a intenção ("mais dura de todas"), mas o piso impede o impossível.
> Playtest pode afrouxar `PHASE5_TIMING_REDUCTION` sem tocar em código de combate.

### 3.6 Diálogo de abertura da fase (mecanismo novo, pequeno)
`_build_profile()` (caso 5) ganha `intro_dialogue: Array` + `intro_speaker`. Em
`exploration_manager._ready()`, **se** `intro_dialogue` não-vazio **e** entrada
fresca (`GameState.player_map_pos == Vector2i(-1,-1)` — i.e., não é volta de
combate), instancia `DialogueScreen`, **trava o movimento** (`_locked = true`) e
destrava no `dialogue_finished`. Reusa 100% o `DialogueScreen` e o
`SceneTransition`; não dispara na volta dos combates dos mini-bosses (aí
`player_map_pos` é a posição salva, não `-1`).

---

## 4. Assets (procedural, máximo polish)

### 4.1 Sprites — `scripts/tools/gen_chars.py`
- **Jesuíta Bandeirante Catequizador** (64×64, presença de chefe, como a Caipora):
  sincretismo de horror — **batina preta** de jesuíta + **gibão de couro** e
  **morrião** (capacete) de bandeirante; numa mão um **espelho** (isca de
  conversão), na outra um **aspersório** de água benta pingando; rosto de zelote
  esquálido, olhos fundos. Animações: idle / wind-up / attack / hurt → SpriteFrames
  `assets/sprites/jesuita_sprite_frames.tres` (intro Mega Man + arena) e
  `jesuita_idle.png` (mapa).
- **Mini-bosses convertidos (opcional, polish):** overlay sutil de "batismo" —
  caco de espelho / pingo de água benta — reusando os sprites de chefe existentes
  por `modulate`/partícula, sem novo spritesheet (mantém leve).

### 4.2 Tiles & decoração — `gen_tiles.py` + `MapObject`
- **Piso de igreja:** lajes de pedra / mosaico colonial gasto (`tile_floor` variante
  igreja). **Paredes:** taipa caiada rachada com escorrido de sangue/mofo.
- **Paleta de decoração `DECO_CHURCH`** (novos `MapObject.Type` + desenhos):
  `PEW` (banco quebrado), `CROSS` (cruz de madeira torta), `MIRROR` (espelho
  rachado), `FONT` (pia de água benta virando lodo), `CANDLE` (círio votivo, com
  brilho se `enhance_fire`), reaproveitando `BONES`/`BLOOD_POOL`/`STUMP`.
- `CanvasModulate` da cena: frio-úmido de igreja (azul-pedra esverdeado).

### 4.3 Áudio — `gen_sfx.py` / `AudioDirector`
- **Stem da Fase 5 (música adaptativa):** drone de **órgão/canto gregoriano
  corrompido** sobre a percussão de maracatu (alfaia + agogô), desafinando quando
  o chefe entra. Loop reproduzível (stdlib), sincronizado ao bus `Music`.
- **Ambiência:** pingar d'água, vela crepitando, sussurro de reza distante (loop
  `assets/audio/ambience/`).
- **Stingers:** **sino de igreja** na revelação do chefe; **sibilo de água benta**
  no telegraph do especial; estertor de órgão na vitória.

> "AAA premium" aqui = o **pipeline reproduzível do projeto no máximo de polish**
> (browser-first, CC0, sem dependência externa), coerente com `assets/AGENTS.md`
> e a §12 do PLAN.

---

## 5. Cenas novas
- `scenes/exploration/exploration_phase5.tscn` → `exploration_manager.gd`, `phase = 5`,
  `CanvasModulate` frio de igreja.
- `scenes/arena/arena_phase5.tscn` → `ArenaManager` com background de nave/altar e
  `caipora_combat_scene` setado.
- `scenes/arena/jesuita.tscn` → `Jesuita` (CombatActor + `EnemyStateMachine` +
  `AnimatedSprite2D` com `jesuita_sprite_frames.tres`), `health.max_health = 44`.

---

## 6. Rollout em etapas (cada etapa fecha com `make gate` verde)

> **Status:** Etapas 0–3 **concluídas**. O fecho da Etapa 3 (tiles de igreja,
> `amb_church`, stingers sino/água-benta/órgão e overlay de batismo nos
> mini-bosses) entrou na branch `claude/fase5-etapa3-polish`.

- **Etapa 0 — Fundação de dados (sem mudança jogável):** enum de telas, roteamento
  `_scene_path_for`, `MapConfig.for_phase(5)` + `_common_mix(5)`, constantes de
  dificuldade/recompensa (`PHASE5_*`, `COMMON_FRAGMENT_REWARD[5]`,
  `BOSS_FRAGMENT_BOUNTY[5]`, `JESUITA_MAX_HEALTH`). Testes do gerador para a Fase 5
  (5 inimigos, 4 commons mapeados aos 4 tipos de chefe, 1 boss `jesuita`,
  `has_exit=false`).
- **Etapa 1 — Chefe final jogável:** `jesuita.gd` (sorteio uniforme dos 7 padrões +
  telegraphs), `jesuita.tscn`, `arena_phase5.tscn`, `_phase_window` caso 5,
  `_on_defense_timing_result` bônus P5, aura/telegraph novos. `test_jesuita.gd`
  (cobre os 7 padrões, flags, distribuição, HP).
- **Etapa 2 — Exploração da igreja + gauntlet:** `exploration_phase5.tscn`, caso 5
  do `_build_profile`, `REGULAR_SCENES` + flag `keep_own_hp`, render de mini-boss
  no `MapEnemy`, diálogo de abertura. Roteamento P4→P5→ENDING e
  `phase_reached=5`/`6`. `test_exploration_phase5.gd` (boot, 4 mini-bosses + Jesuíta,
  diálogo trava/destrava, vitória do chefe → ENDING) + update de
  `test_scene_transition` (novas telas) e do roteamento do `arena_manager`.
- **Etapa 3 — Assets & polish AAA:** sprite do Jesuíta + SpriteFrames, tiles/deco de
  igreja (`DECO_CHURCH`), stem de áudio + stingers, `CanvasModulate`, verificação
  visual headless (Xvfb) dos 4 mini-bosses no mapa + intro do Jesuíta em 2 linhas.

---

## 7. Validação
- `make gate` (smoke + GUT) verde ao fim de cada etapa.
- **`/validate-controls`** — toca input/arena/timing (janela P5, novo chefe).
- **`/validate-platforms`** — toca UI/câmera/safe-area (nova arena, intro, deco).
- Verificação visual headless (harness de captura) para sprites/telegraphs novos.

## 8. Riscos & mitigações
- **Janela no piso (ASSOBIO + −0.50):** mitigado pelo piso `0.2s`; tunável por
  constante sem tocar combate.
- **Gauntlet longo (4 chefes HP cheio + final):** o HUB antes da P5 cura e permite
  comprar ervas; playtest decide se reduz `enemy_count` ou afrouxa HP.
- **Acoplamento do `WHITE_SPECIAL_PATTERN` (Boitatá):** redeclaração local no
  Jesuíta resolve no escopo; follow-up = extrair `BossPatterns` compartilhado.
- **Peso no browser (novos assets):** procedural + CC0, sem libs externas; testar
  tempo de load do export.

## 9. Fora de escopo (follow-ups)
- Ending alternativo "verdadeiro" para a derrota do Jesuíta (mantém-se o ENDING
  atual "a floresta vive... por enquanto").
- Tier 5 de ervas / nova trilha de aprimoramento.
- `BossPatterns` compartilhado (refactor de desacoplamento dos padrões de chefe).
