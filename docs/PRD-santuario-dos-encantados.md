# PRD — Santuário dos Encantados: Bosses Pacíficos no Acampamento

> **caipora** — Brazilian Folk Horror Roguelike
> **Status:** 📋 Planejado (este documento)
> **Document Version:** 1.0
> **Depende de:** Fase 9 (Hub Jogável — concluída), redesigns premium dos bosses (KI-012)
> **Lei visual:** `.agents/skills/visual-identity/SKILL.md` + `docs/CONCEITO-{mula,curupira,saci,jesuita}.md`

---

## 1. Visão Geral

Mudança core no significado da vitória: **a Caipora não mata os encantados — ela os
liberta**. O golpe final quebra o pacto corrompido; o corpo corrompido cai (o combate
continua violento e sangrento — nada é suavizado), mas o espírito do encantado se recolhe
ao único lugar que a corrupção não alcança: o **Acampamento**.

A cada boss libertado, o encantado passa a **viver pacificamente no acampamento** — e a
clareira sofre uma **grande transformação visual**, cumulativa, coerente com a natureza
de cada um. O acampamento evolui de uma fogueira solitária na penumbra para um
**santuário dos encantados**: o último pedaço de mata viva, guardado pelos espíritos que
a Caipora trouxe de volta.

**Tom:** os encantados em paz NÃO são mascotes. São entidades antigas descansando —
presenças grandes, imóveis, de olhos meio acesos, que assentam peso ao redor do fogo.
A calma deles é a calma de predadores saciados. O horror continua lá fora; aqui ele
apenas **respira**.

### O que muda no loop

- **Dentro da run:** nada muda mecanicamente — o boss derrotado já não reaparece na fase
  (`defeated_enemy_ids`). O que muda é o que o jogador encontra na próxima visita ao
  acampamento: o encantado está lá, em paz, e a clareira mudou.
- **Entre runs:** a libertação é **meta-persistente E definitiva** (como
  `phase_reached`): uma vez libertado, o encantado vive no acampamento para sempre —
  inclusive no santuário pós-derrota — e **sai da fase para sempre**. Em runs novas o
  guardião não está mais lá: a toca dele virou passagem (§4.2). Os bosses só voltam às
  fases se o jogador **resetar o progresso**.
- **Na Fase 5:** o Jesuíta nunca é libertado — está sempre lá. E as "cascas batizadas"
  dos quatro encantados continuam servindo ao altar (são simulacros, não os espíritos —
  ver reconciliação abaixo), então a fase final **mantém a dificuldade cheia** mesmo com
  o santuário completo.

### Decisões de design (travadas com o autor, 2026-06-11)

| # | Decisão | Travado | Alternativa rejeitada |
|---|---------|---------|----------------------|
| 1 | Persistência | **Meta** (entre runs, no save) — o santuário acumula | Por run: o acampamento resetaria a cada morte, matando o impacto |
| 2 | Jesuíta no santuário | **NUNCA** — não é encantado da mata; é o colonizador | Incluí-lo diluiria o conceito (e o final dele já é a FINAL_CHOICE) |
| 3 | Bosses nas fases em runs novas | **Saem para sempre** ao serem libertados; só voltam com reset de progresso | Mantê-los como "eco da corrupção" — a libertação tem que valer |

### Reconciliação com a Fase 5 (a Igreja)

O Jesuíta abre a P5 dizendo que *converteu* os encantados — e os mini-bosses da igreja
SÃO os quatro chefes. Com os espíritos livres no santuário, a leitura canônica passa a
ser: **o que serve ao altar são cascas batizadas** — simulacros ocos que o Jesuíta
moldou com espelhos e água benta, não os espíritos verdadeiros. Isso *fortalece* o
horror da fase (ele profanou até a forma deles). Ação: registrar a leitura nos docs de
lore; opcionalmente (Etapa 3) uma linha de flavor no diálogo da P5 reforça
("essas cascas não são eles. eu sei onde eles estão.").

---

## 2. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Libertação registrada** | Derrotar um boss (P1–P4) grava o encantado como libertado, persistido no save |
| 2 | **O guardião sai da fase** | Em runs novas o boss libertado não spawna; P3/P4 avançam pela passagem na toca dele; jogo completável com 0–4 libertados; bosses só voltam com reset de progresso |
| 3 | **Encantado no acampamento** | Cada encantado libertado aparece no hub em pose de descanso, animado, com aura calma |
| 4 | **Grande upgrade visual por boss** | Cada libertação transforma a cena do acampamento de forma cumulativa e imediatamente perceptível |
| 5 | **Rito de chegada** | A primeira visita ao hub após cada libertação tem um beat de revelação (uma vez por encantado) |
| 6 | **Identidade preservada** | A Caipora continua a marca mais forte da tela; pixel art chapada; horror material; verde com parcimônia |
| 7 | **Sem regressão** | Loop, compra de ervas, saída, HUD, retrato/paisagem, Fase 5 e save v3 intactos; gate verde |

---

## 3. Design Visual — A Transformação por Encantado

Cada encantado tem (a) uma **presença** — o próprio boss em idle pacífico num ponto fixo
da borda da clareira — e (b) uma **transformação de cena** — o "grande upgrade visual"
que muda o acampamento inteiro. Tudo com as ferramentas existentes (`CPUParticles2D`,
`ForestLight`, `MapObject`, tweens), pixel art chapada, sem shader novo.

### 3.1 Mula sem Cabeça (P1) — *O Fogo Dela*

- **Presença:** a Mula deitada/assentada na borda norte da clareira, perto do fogo.
  O fogo do pescoço queima **baixo e manso** — chama âmbar lenta (a fúria virou brasa).
- **Transformação:** a fogueira central vira uma **pira ritual**: chama maior, luz mais
  quente e de raio maior, **brasas flutuando sobre a clareira inteira** (CPUParticles2D
  de baixa densidade). O acampamento sai da penumbra fria — agora tem o fogo dela.

### 3.2 Boitatá (P2) — *A Luz que Ronda*

- **Presença:** o Boitatá **enrodilhado ao longo da borda leste**, corpo serpenteando
  entre os troncos da mata, cabeça pousada — a cobra de fogo virou muralha.
- **Transformação:** **perímetro de fogos-fátuos**: orbes de luz pálida (ForestLight em
  cadeia, pulso lento e dessincronizado) circundam a clareira; um aro tênue de luz
  desenha o limite onde a corrupção não entra. O acampamento agora é **protegido**.

### 3.3 Curupira (P3) — *A Mata Volta a Crescer*

- **Presença:** o Curupira **de cócoras sobre um tronco** na borda sudoeste, imóvel,
  olhos acesos vigiando a mata — o guardião mais antigo de sentinela.
- **Transformação:** **vida verde brota na clareira**: samambaias, musgo e cipó
  (decorações `MapObject` na paleta da flora existente) entre os tiles; densidade de
  vaga-lumes do `AmbientLife` aumenta; pequenas marcas ritualísticas no chão ao redor
  do fogo. **Atenção à lei visual:** o verde entra como acento de cena (flora já
  existente no jogo), nunca competindo com o cristal da Fúria nem com a leitura da
  Caipora.

### 3.4 Saci Pererê (P4) — *O Vento no Acampamento*

- **Presença:** o Saci **sentado de pernas cruzadas** na borda sudeste, **fumando um
  cachimbo próprio** — espelho deliberado do cachimbo da Caipora ao pé do fogo: os dois
  fumam o mesmo silêncio. A carapuça vermelha tem um brilho baixo.
- **Transformação:** **o vento entra**: redemoinhos de folhas (CPUParticles2D) cruzam a
  clareira de tempos em tempos; rajadas curtas balançam as partículas da pira e dos
  fogos-fátuos. O acampamento, antes parado, agora **se move** — está vivo.

### 3.5 Estado final (4 encantados)

Pira alta + perímetro de luz + mata viva + vento: o santuário completo. É a imagem de
marketing do meta-progresso — e o contraste com a primeira visita (fogueira baixa,
escuro, vazio) é o "grande impacto" pedido.

### 3.6 Leis de leitura (checklist da skill visual-identity)

- A Caipora continua a marca mais memorável: encantados **em repouso, mais escuros que
  em combate** (modulate levemente abatido), sem roubar o primeiro olhar.
- Silhuetas leem em miniatura; paleta de cada boss preservada (são os mesmos vetores
  dos sprites premium); 1px outline; **sem gradiente suave, sem glow difuso de shader**
  — luz é `ForestLight` (já canônica) e partícula é pixel.
- Jogabilidade legível: presenças e transformações ficam **fora dos tiles andáveis**
  (borda da clareira / camadas de partícula), sem tocar walkability nem cobrir os cards
  do `HubShop` (CanvasLayer 10) ou o beacon de saída (layer 9).
- Orçamento mobile: tudo `CPUParticles2D` de baixa contagem, respeitando
  `Constants.particle_amount_scale`; zero shader novo; zero textura nova grande.

---

## 4. Arquitetura

### 4.1 Persistência — `MetaProgression` (save v3 → v4)

```gdscript
# MetaProgression
var freed_bosses: Array[int] = []   # fases dos encantados libertados (P1–P4), ordenadas
var spirits_seen: Array[int] = []   # ritos de chegada já exibidos no acampamento

func free_boss(phase: int) -> void:   # idempotente; ignora P5/inválidas; persiste
func is_boss_freed(phase: int) -> bool:
func has_seen_spirit(phase: int) -> bool:
func mark_spirit_seen(phase: int) -> void:   # exige libertado; idempotente; persiste
```

- **Gravação:** chamada direta `MetaProgression.free_boss(GameState.active_phase)` em
  `arena_manager._on_actor_died`, junto do bounty e do `phase_reached` (que já mutam o
  `MetaProgression` ali). **Não** é listener de `SignalBus.boss_died`: testes emitem
  esse sinal cru (`test_audio_director`) e um listener persistiria save como efeito
  colateral de qualquer emissão. Fase 5 (Jesuíta) é ignorada por design. Os mini-bosses
  da P5 spawnam como comuns (`active_combat_is_boss == false`) — sem falso positivo.
- **Migração v3→v4:** derivar de `phase_reached` — boss da fase N libertado se
  `phase_reached ≥ N+1` (limitado a P1–P4), entrando como libertado E como já visto
  (`spirits_seen`), para saves veteranos não tomarem 4 ritos de chegada em sequência.
  Trade-off documentado: P1/P2 têm tile de saída, então a derivação é generosa com quem
  avançou sem derrotar Mula/Boitatá. Migração coberta por teste.
- **Reset:** `reset_save()` limpa ambas as listas (junto do resto) — os guardiões voltam
  às fases.

### 4.2 A fase sem guardião — o boss sai do mapa

Quando o boss da fase está libertado (`MetaProgression.freed_bosses`):

- **Geração:** `MapConfig` ganha `boss_freed: bool`, preenchido na **construção** do
  config a partir do `MetaProgression` (o `MapGenerator` segue puro e determinístico —
  a flag é dado de entrada, não consulta de autoload). Com a flag ligada: o boss não é
  colocado; nas fases **sem tile de saída** (P3/P4, `has_exit=false`), a **cela do boss
  vira o tile de saída** — mesma posição mais profunda, mesma garantia de rota limpa
  (`_ensure_clean_path` passa a proteger a rota até a saída, como protegia a rota até o
  boss). Os guardas do boss viram **guardas da passagem** (`BOSS_GUARD_MIN` mantido,
  ancorado na saída). P1/P2 já têm saída — o boss simplesmente não spawna.
- **Roteamento:** o avanço por tile de saída já passa pelo hub
  (`advance_phase_via_hub`). P3 e P4 ganham `next_screen_on_exit` no `_build_profile()`
  (P3→`EXPLORATION_PHASE4`, P4→`EXPLORATION_PHASE5`), consumido apenas quando a saída
  existe. `BossIntro`/diálogo pré-boss não disparam — não há encontro de boss. O marco
  `phase_reached` já está gravado de runs anteriores (não há como ter boss libertado
  sem ele), então nenhum unlock depende do encontro que deixou de existir.
- **Lore no mapa:** onde o guardião vivia, fica a passagem — o `exit_marker` pulsante
  na alcova mais funda, opcionalmente com uma marca ritual de paz (decoração
  `MapObject`) ao lado. A mata reconhece quem a libertou.
- **Economia:** o bounty do boss some das runs seguintes — **aceito**: a rota encurta,
  as fases fundas pagam mais por kill comum, e a meta passa a ser libertar os quatro e
  encarar a Igreja direto. Conferir o feel no playtest da Etapa 1.
- **Reset:** `reset_progress()` limpa `freed_bosses` → os guardiões voltam às fases.

### 4.3 A presença — `CampSpirit`

| Arquivo | Papel |
|---------|-------|
| `scripts/hub/camp_spirit.gd` **(novo)** | `class_name CampSpirit extends Node2D` — presença de um encantado em repouso |
| `scripts/hub/hub_manager.gd` | `_spawn_spirits()` + transformações de cena, chamado após `_spawn_camp_identity()` |

`CampSpirit.setup(def)` monta por código (gotcha #7 — nada de mexer em `.tscn`):

- `AnimatedSprite2D` com o `*_sprite_frames.tres` do boss, animação `idle`, velocidade
  reduzida (~0.6×) — o descanso é mais lento que o combate.
- **Respiração:** tween de loop sutil em `scale.y` (±2%) — vivo, não estátua.
- **Aura calma:** as cores da `_spawn_shadow_aura()` de cada boss, recicladas em
  partículas de densidade/velocidade mínimas (a sombra de combate virou cinza de pira).
- **Modulate de repouso** (levemente abatido) — ver §3.6.
- Tudo dirigido por um **`SPIRIT_DEFS` data-driven** (uma tabela única no topo do
  `hub_manager.gd` ou do `camp_spirit.gd`): fase → frames, escala, tile-âncora na borda,
  flip, cor de aura, fala do rito. Sem números mágicos espalhados.

**Escala/posição:** sprites premium de arena têm 128–192px (4–6 tiles de 32px) — como
**set pieces** na borda da mata isso é desejável (imponência), com escala por encantado
na `SPIRIT_DEFS` (ex.: Mula deitada ~0.7, Curupira ~0.6). Âncoras fixas na moldura de
parede da clareira (16×12 em grid `Constants.GRID_WIDTH×GRID_HEIGHT`), escolhidas para
caberem no quadro tanto em retrato quanto em paisagem (validar com a ferramenta de
preview, §5 Etapa 2). Walkability intocada — todos os tiles-âncora já são parede/mata.

### 4.4 A transformação — camadas de cena por encantado

`hub_manager._apply_sanctuary_layers()` itera `freed_bosses` e aplica cada camada
(funções pequenas e independentes): `_layer_mula_pyre()`, `_layer_boitata_wisps()`,
`_layer_curupira_flora()`, `_layer_saci_wind()`. Cumulativas e idempotentes por
construção (cada uma roda no máximo uma vez por `_ready`). A pira da Mula **modifica**
a fogueira existente (escala da chama + energia/raio da `ForestLight` + emissor de
brasas extra) em vez de duplicá-la.

### 4.5 O rito de chegada (reveal, uma vez por encantado)

Na entrada do hub, para cada libertado **sem** `spirits_seen`:

1. Beat curto (~2s, skippável por toque/tecla como o diálogo): a clareira escurece um
   instante (tween no `CanvasModulate`/modulate da cena, **não** mexe na `Atmosphere`),
   o espírito surge com fade-in + explosão curta de brasas, a camada de cena dele liga
   junto.
2. **Uma linha de flavor** no padrão das transições ("a mula descansa. o fogo dela é
   teu agora."), tom seco, sem suavizar.
3. Stinger SFX novo via `gen_sfx.py` (parente do `sting_arena_enter`, resolvido para
   baixo — chegada, não ameaça).
4. `spirits_seen[phase] = true` + save. Com 2+ libertações pendentes (caso raro:
   save migrado fora da janela, debug), os ritos enfileiram.

Durante o beat o input de movimento fica travado (`_locked`, mecanismo já existente).

---

## 5. Roadmap de Execução (etapas com gate)

Estilo incremental e test-gated. Cada etapa fecha com `make gate` verde e jogo jogável
ponta-a-ponta. **Lembrete obrigatório:** `class_name` novo (`CampSpirit`) exige
`godot --headless --import` antes do `make test`, e conferir que a CONTAGEM de testes
subiu (gotcha #12 — GUT mente verde em arquivo que não parseia).

### Etapa 0 — Memória dos encantados (persistência, sem visual)
- `freed_bosses`/`spirits_seen` + `free_boss()` no `MetaProgression`; chamada direta no
  `arena_manager._on_actor_died` (ignora fase 5); save v4 + migração v3→v4 derivada de
  `phase_reached`; `reset_save()` limpa.
- **Gate:** `test_meta_progression` estendido (free/idempotência/clamp P1–P4/round-trip
  do save/migração/reset); P5 e mini-bosses não registram.

### Etapa 1 — A fase sem guardião (o boss sai do mapa)
- `MapConfig.boss_freed` (entrada de dado; gerador segue puro) + `MapGenerator`: sem
  boss; em P3/P4 a cela do boss vira tile de saída com rota limpa garantida; guardas
  ancorados na passagem. `next_screen_on_exit` de P3/P4 no `_build_profile()`; marca
  ritual de paz opcional na alcova.
- **Gate:** invariantes do gerador parametrizados por `boss_freed` × fase × seed (sem
  boss no grid, saída válida/única/alcançável do spawn, contagem de inimigos, rota
  limpa); roteamento P3→P4 e P4→P5 por saída via hub; run ponta-a-ponta com 0 e com 4
  libertados (P5 sempre com Jesuíta e cascas batizadas). `/validate-controls` (mexe em
  exploração).

### Etapa 2 — Os encantados no acampamento (presenças)
- `camp_spirit.gd` + `SPIRIT_DEFS` (frames, escala, âncora, flip, aura, fala);
  `hub_manager._spawn_spirits()`; idle lento + respiração + aura calma + modulate de
  repouso.
- **Gate:** `test_camp_spirit.gd` (setup por fase, contrato de frames, sem fase 5) +
  `test_hub_builds` estendido (hub monta com 0–4 espíritos; walkability/saída/compras
  intactas).

### Etapa 3 — A transformação do acampamento (o grande impacto)
- As 4 camadas de cena (§4.4), cumulativas, data-driven; pira modifica a fogueira
  existente; densidades respeitando `particle_amount_scale`.
- **Ferramenta de preview** `scripts/tools/preview_camp_spirits.gd` (padrão
  `preview_combat_dpad.gd`/`preview_final_scenes.gd`): captura o acampamento sob Xvfb
  nos 5 estados (0–4 libertados), retrato E paisagem — é o gate visual de leitura
  (Caipora ainda domina? cards legíveis? âncoras no quadro?).
- **Gate:** `make gate` + capturas revisadas + `/validate-platforms` (mexe em cena com
  câmera/safe-area).

### Etapa 4 — O rito de chegada + narrativa + áudio
- Reveal por encantado (§4.5) com fila, skip e trava de input; falas na `SPIRIT_DEFS`;
  stinger novo no `gen_sfx.py` (regen determinístico — conferir que faixas vizinhas
  ficam byte-idênticas); `spirits_seen` persistido.
- Lore P5: nota canônica das "cascas batizadas" nos docs (+ linha de flavor opcional no
  diálogo da P5, decisão do autor).
- Atualizar `PLAN.md` (seção + Known Issues se surgir algo) e `AGENTS.md` se houver
  gotcha novo.
- **Gate:** `make gate` verde; playtest do loop completo; teste do rito (dispara uma
  vez, persiste, enfileira, skippa).

---

## 6. Impacto em Arquivos

| Arquivo | Mudança |
|---------|---------|
| `scripts/core/meta_progression.gd` | `freed_bosses`/`spirits_seen`, `free_boss()`/`mark_spirit_seen()`, save v4 + migração |
| `scripts/arena/arena_manager.gd` | `free_boss(active_phase)` na morte de boss (junto do bounty/`phase_reached`) |
| `scripts/exploration/map_config.gd` | `boss_freed: bool` (preenchido do `MetaProgression` na construção) |
| `scripts/exploration/map_generator.gd` | sem boss quando libertado; saída na cela do boss (P3/P4); guardas na passagem; rota limpa até a saída |
| `scripts/exploration/exploration_manager.gd` | `next_screen_on_exit` para P3/P4 (usado só quando a saída existe) |
| `scripts/hub/camp_spirit.gd` **(novo)** | presença do encantado em repouso (`CampSpirit`) |
| `scripts/hub/hub_manager.gd` | `SPIRIT_DEFS`, `_spawn_spirits()`, camadas de santuário, rito de chegada |
| `scripts/tools/gen_sfx.py` | stinger de chegada do espírito |
| `scripts/tools/preview_camp_spirits.gd` **(novo)** | capturas Xvfb dos 5 estados do santuário |
| `docs/PRD-fase-final-igreja.md` (ou doc de lore) | nota canônica das cascas batizadas |
| `tests/unit/test_map_generator.gd`, `test_exploration_phase{3,4}.gd`, `test_meta_progression.gd`, `test_hub_builds.gd`, `test_camp_spirit.gd` **(novo)** | cobertura das etapas |

Sem mudança em: economia/ervas (`purchase_upgrade`), arena/timing, Fase 5 (Jesuíta +
cascas batizadas intactos), `boss_intro_screen` (só deixa de ser chamado em fase sem
guardião), finais.

---

## 7. Riscos & Mitigações

| Risco | Mitigação |
|-------|-----------|
| **Softlock**: fase sem boss ficar sem rota de avanço | Saída na cela do boss com `_ensure_clean_path` + invariantes "saída alcançável do spawn" por fase × seed no GUT |
| Runs ficarem curtas/economia frouxa com 4 libertados | Aceito por design (a libertação tem que valer); fases fundas pagam mais por kill; conferir feel no playtest da Etapa 1 e ajustar `COMMON_FRAGMENT_REWARD` se preciso |
| Encantados roubarem a leitura da Caipora (lei de marca) | Repouso abatido (modulate), bordas da clareira, gate visual por preview nos 5 estados |
| Poluição visual/perf no mobile com 4 camadas ativas | Densidades mínimas, `particle_amount_scale`, medir com `?perf` no estado 4/4 |
| Conflito de lore com a P5 (bosses "convertidos") | Retcon canônico das cascas batizadas (doc) + flavor opcional |
| Save v3→v4 corromper progresso veterano | Migração derivada de `phase_reached` + `spirits_seen` pré-marcado + teste de round-trip |
| Âncoras fora do quadro em retrato (~393px) | Âncoras validadas nas capturas retrato/paisagem; `/validate-platforms` |
| Rito de chegada empilhar com o fluxo de compra/saída | `_locked` durante o beat; fila; skip; teste dedicado |
| GUT verde-mentiroso com `class_name` novo | `--import` antes do test + conferir contagem (gotcha #12) |

---

## 8. Fora do Escopo (follow-ups)

- Interação com os encantados (falas ao se aproximar, bênçãos/buffs por espírito).
- Música do hub evoluindo por encantado (camada de stem por libertação).
- Marca visual do Jesuíta poupado (FINAL_CHOICE) em algum canto do santuário.
- Key art / página do itch usando o santuário completo como imagem de meta-progresso.
