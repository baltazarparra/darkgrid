# PRD — Áudio v2: "O Batuque da Mata"

> **caipora** — Brazilian Folk Horror Roguelike
> **Status:** 📝 Proposta (pronto para revisão)
> **Document Version:** 1.0
> **Depende de:** sistema de áudio existente (`AudioDirector`, `SfxSystem`, `gen_sfx.py`)
> **Relacionado:** PLAN.md §12 (identidade sonora pós-MVP)

---

## 1. Visão Geral

O caipora já tem **fundação de áudio madura**: 4 buses com limiter, `AudioDirector`
persistente (crossfade, ducking, stingers, autoplay unlock), `SfxSystem` com variantes
anti-repetição, e ~50 assets 100% procedurais com DNA de maracatu. O que falta não é
infraestrutura — é **direção, reatividade e acabamento**.

Hoje o áudio é *funcional*: cada tela tem sua faixa, cada evento tem seu som. Mas é
*estático*: a música não sabe se você está a um golpe da morte ou dominando a luta; a
mata não reage à sua presença; o mix nunca passou por um padrão de loudness; e o pulso
do maracatu — num jogo cujo coração é **apertar Espaço no frame certo** — não conversa
com o ritmo do combate.

Esta PRD define o **conceito sonoro autoral** do jogo e o eleva de "tem som" para
"a experiência sonora É o jogo". Tudo permanece **procedural, reproduzível e original**
(`gen_sfx.py` é a única fonte de assets — zero samples externos, zero licenciamento).

**Tom:** O batuque não acompanha a violência. O batuque *é* a violência. Quando a
Caipora sangra, a mata inteira percute mais fundo.

**Filosofia:** *"Num jogo de timing, o som não é feedback — é a linguagem em que o
jogo fala com as mãos do jogador."*

---

## 2. Estado de Partida (verificado)

### Arquitetura (não muda — é a base)

- **Buses** (`default_bus_layout.tres`): `Master` (HardLimiter) ← `SFX` / `Music` / `Ambience`.
- **`AudioDirector`** (`scripts/core/audio_director.gd`, autoload): volume por bus
  persistido em `user://settings.cfg`, crossfade de música (par A/B), ambiência por tela,
  9 stingers por sinal, ducking manual por tween (`duck()`), unlock de autoplay HTML5,
  `_force_loop()` em runtime (porque `.import` é gitignored).
- **`SfxSystem`** (`scripts/systems/sfx_system.gd`, por arena): players descartáveis,
  round-robin de variantes por convenção de nome (`hit.wav` → `hit_2.wav`/`hit_3.wav`),
  jitter de pitch ±5% e volume ±1 dB.
- **Testes**: `test_audio_director.gd`, `test_sfx_variants.gd` no gate (`make test`).

### Assets (todos gerados por `scripts/tools/gen_sfx.py`, 1113 linhas, stdlib pura)

| Categoria | Qtde | Formato | Peso |
|-----------|------|---------|------|
| SFX combate/UI | 7 sons × 3 variantes | WAV mono 16-bit 22050 Hz | 304 KB |
| Ambiência | 5 loops | WAV mono 22050 Hz | 2.0 MB |
| Música | 23 faixas | WAV mono 11025 Hz (lo-fi intencional) | 3.0 MB |
| Stingers | 9 one-shots | WAV mono 22050 Hz | 452 KB |
| **Total** | | | **5.7 MB** |

Paleta tímbrica existente: **alfaia, caixa, ganzá, agogô, gonguê, assovio** + bitcrush
8-bit como cola estética.

### Lacunas (o que esta PRD ataca)

1. **Música estática** — um loop por contexto; nenhuma camada reage a HP, fase do boss
   ou intensidade. O comentário "stems de maracatu" no `AudioDirector` nunca virou stems.
2. **Mix sem padrão** — nenhum alvo de loudness; faixas com volumes percebidos díspares;
   `MASTER_TRIM_DB = -6.0` é um band-aid global.
3. **Sem espaço acústico** — zero reverb/delay nos buses; a igreja (P5) soa tão seca
   quanto a mata aberta. O bus layout não tem bus de send.
4. **Eventos mudos** — passos, ervas/cachimbo, hover de UI, dano recebido vs. causado
   (mesmo `hit.wav`), HP crítico, sons por criatura/boss (todas as criaturas morrem
   com o mesmo `death.wav`).
5. **Pulso desconectado** — o maracatu tem BPM, o combate tem janelas de timing, e os
   dois nunca se encontram.
6. **Síntese v1** — sem filtros ressonantes, sem reverb de síntese, sem stereo; as
   faixas longas são repetitivas dentro do próprio loop.

---

## 3. Conceito Sonoro — "O Batuque da Mata"

Três pilares. Toda decisão de áudio (nova faixa, novo SFX, novo efeito de bus) deve ser
justificável por pelo menos um deles. Se não for, não entra.

### Pilar 1 — A mata respira (ambiência viva, silêncio como arma)

A floresta é um organismo hostil. A ambiência não é "fundo": ela tem **eventos
esparsos aleatórios** (galho quebrando, pássaro que cala, sopro que passa perto) e
**reage ao estado do jogador**. O silêncio é deliberado: antes do boss aparecer, a
mata **cala** — e o jogador sente que algo está errado antes de ver.

### Pilar 2 — O batuque é o coração (música adaptativa, percussão como linguagem)

O maracatu de baque virado é a espinha. A música é construída em **stems verticais**
(terreiro: alfaia → caixa → agogô → melodia) que entram e saem conforme a intensidade
do combate. HP crítico despe a música até restar **só a alfaia e o batimento** —
o coração da Caipora e o coração do jogo são o mesmo tambor. Telegraphs dos inimigos
caem **no tempo do baque** sempre que possível: o jogador que escuta, esquiva.

### Pilar 3 — O grão é a assinatura (lo-fi 8-bit como estética, não limitação)

Bitcrush, 22 kHz, mono percussivo: o som de fita podre encontrada numa casa abandonada
na beira do rio. O grão unifica orgânico (percussão de terreiro) e chiptune. **Regra
dura:** nenhum asset externo, nenhum sample — tudo nasce de `gen_sfx.py`, com seed,
reproduzível. Originalidade por construção.

### Padrão técnico (o "conceito bem definido" em números)

| Regra | Valor | Por quê |
|-------|-------|---------|
| Loudness música/ambiência | −16 LUFS ±1 (integrado) | uniformidade entre faixas; browser/mobile |
| Loudness SFX (pico) | −3 dBFS, RMS −12 a −9 | punch sem disputar com o limiter |
| Stingers | −2 dB acima da música | devem furar o mix por definição |
| True peak global | ≤ −1 dBFS por asset | headroom pro HardLimiter nunca trabalhar |
| Frequências | SFX donos de 2–6 kHz; música cede (EQ no bus) | inteligibilidade do timing |
| Sample rate | SFX/amb/sting 22050 Hz; música 11025 Hz | grão lo-fi + peso (browser-first) |
| BPM canônico | tabela por fase em `gen_sfx.py` (fonte única) | beat-sync (RF-A06) lê de lá |
| Naming | `mus_`/`amb_`/`sfx (raiz)`/`sting_` + `_2`/`_3` variantes | convenção já consolidada |
| Orçamento de peso | áudio total ≤ 9 MB | wasm já pesa 37 MB; carga < 10s (PRD-fase-5) |

---

## 4. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Direção definida** | Padrão técnico documentado e verificável por script (`make audio-check`) |
| 2 | **Música adaptativa** | Stems reagem a HP/boss-fase em < 1 compasso, sem corte audível |
| 3 | **Mix com espaço** | Reverb por contexto (igreja ≠ mata); SFX sempre legíveis sobre a música |
| 4 | **Cobertura total** | Zero eventos de gameplay mudos; morte de cada boss soa única |
| 5 | **Pulso compartilhado** | Telegraphs quantizados ao beat (atrás de flag, validado com `/validate-controls`) |
| 6 | **Zero regressão** | `make gate` verde; peso ≤ 9 MB; sem novos stalls de carga no HTML5 |

---

## 5. Requisitos Funcionais

### RF-A01 — Padrão de loudness + ferramenta de verificação

- Novo script `scripts/tools/check_audio.py` (stdlib): mede pico, RMS e LUFS aproximado
  (K-weighting simplificado) de cada `.wav` em `assets/audio/` e compara com a tabela §3.
- Novo target `make audio-check` (e incluído em `make gate`? — não: gate fica rápido;
  `audio-check` roda em `make audio`, ver RF-A02).
- Saída: tabela com ✅/❌ por asset. Falha (exit ≠ 0) se qualquer asset estourar o padrão.

### RF-A02 — Motor de síntese v2 (`gen_sfx.py`)

Upgrade do gerador, mantendo stdlib pura e seeds determinísticas:

- **Filtros biquad** (low-pass/high-pass/band-pass ressonantes) — timbres com corpo,
  sem o "zumbido cru" de osciladores nus.
- **Reverb de síntese** (Schroeder: combs + all-pass) — caudas curtas *impressas nos
  assets* de stinger/ambiência (o reverb de bus do RF-A03 é para o espaço; este é para
  o corpo do som).
- **Delay/eco** com feedback — assovio da Caipora ganha eco de mata.
- **Normalização para o padrão RF-A01** embutida no `_write()` (peak + RMS alvo por
  categoria) — o gerador nunca produz asset fora do padrão.
- **Humanização rítmica** nas faixas: micro-variação de velocity/timing por compasso +
  fills a cada N compassos — mata a repetição interna dos loops longos.
- Novo target `make audio` = regenerar tudo + `audio-check` + `--headless --import`.
- **Regenerar todos os assets existentes** com o motor v2 (mesmos nomes, mesma API).

### RF-A03 — Espaço acústico: buses de efeito por contexto

- `default_bus_layout.tres` ganha bus **`Reverb`** (send ← SFX/Music/Ambience parciais,
  → Master) com `AudioEffectReverb`.
- `AudioDirector` ganha **perfis de espaço** por tela, trocados no `_apply_screen_audio`:
  - `MATA` — reverb quase seco, room pequeno (folhagem absorve);
  - `IGREJA` — room grande, wet alto, damping baixo (pedra fria; Fase 5 inteira);
  - `ARENA` — médio, pré-delay curto (clareira).
- EQ no bus `Music`: shelf suave cortando 2–6 kHz (~−3 dB) — a faixa cede espaço para
  o estalo da caixa dos SFX de timing (Pilar do padrão §3).
- Ducking existente (`duck()`) permanece; ganha chamada extra no `timing_perfect`
  (o mundo cala 350 ms para o crítico soar enorme).

### RF-A04 — Música adaptativa vertical (stems)

A mudança de maior impacto. Cada contexto de combate deixa de ser 1 loop e vira
**3 stems sincronizados** (mesmo BPM, mesma duração, mesmo seed de compasso):

- `mus_arena_pN_base.wav` — alfaia + gonguê (sempre toca);
- `mus_arena_pN_mid.wav` — caixa + ganzá (entra em combate ativo);
- `mus_arena_pN_top.wav` — agogô + melodia chiptune (entra em alta intensidade).

Implementação:

- `AudioDirector` ganha `MusicStems`: 3 players sincronizados (mesmo `play()` frame,
  volumes individuais tweenados). API: `set_intensity(level: int)` (0–2).
- **Fontes de intensidade** (via `SignalBus`, sem acoplar arena→áudio):
  - entrada na arena → nível 1; boss → nível 2 direto;
  - HP da Caipora < 30% → **modo coração**: mid/top caem, base continua + camada
    `heartbeat` (RF-A05); voltar acima de 30% restaura;
  - fase 2 do boss → nível 2 + pitch da base +1 semitom (já existe sinal de fase?
    verificar; senão, usar `boss_special_telegraph` como proxy é incorreto — expor
    sinal novo `boss_phase_changed`).
- Exploração e telas de menu/hub **continuam single-loop** (intensidade não se aplica).
- Fallback graceful: se os stems não existem, toca o loop único atual (mesmo padrão
  `ResourceLoader.exists` já usado).
- Escopo de assets: stems **apenas para `mus_arena_p1..p5` e os 5 bosses** (30 arquivos);
  peso controlado pelo orçamento §3 (música a 11025 Hz mono).

### RF-A05 — Cobertura de eventos mudos

Novos SFX (todos com 3 variantes, todos da paleta §3):

| Som | Evento | Timbre |
|-----|--------|--------|
| `step_grass` / `step_stone` | passo na exploração (grama / igreja) | ganzá abafado / tarol de borda |
| `hurt_caipora` | Caipora recebe dano (≠ `hit.wav`, que é dano causado) | alfaia surda + sopro |
| `heartbeat` | loop HP < 30% (camada no modo coração, bus Ambience) | alfaia dupla 60 BPM |
| `herb_pickup` / `pipe_smoke` | colher erva / fumar cachimbo (upgrade) | chocalho + sopro grave |
| `ui_hover` | foco/hover em botão | tick de agogô, −12 dB |
| `boss_death_N` | morte de cada boss (5 sons únicos) | leitmotif invertido do boss |
| `criatura_death_dry` | morte de criatura comum (substitui uso genérico) | variação do `death` atual |
| `mata_event_1..4` | eventos esparsos da ambiência (galho, pássaro, sopro, cigarra que para) | ver RF-A07 |

Wiring: `SfxSystem` (combate) e `AudioDirector` (UI/exploração) via sinais existentes;
não criar referências diretas arena↔áudio.

### RF-A06 — Pulso compartilhado (beat-sync) `[flag: BEAT_SYNC]`

- `gen_sfx.py` exporta tabela `BPM_BY_TRACK` → gerada como
  `scripts/core/audio_beat_map.gd` (const dictionary, **commitado**, não gitignored —
  diferente do `build_info.gd`).
- `AudioDirector` expõe `time_to_next_beat() -> float` (posição do player ativo +
  `AudioServer.get_time_since_last_mix()` para compensar latência).
- Arena: o **início do wind-up** dos telegraphs de inimigos comuns é adiado até o
  próximo beat (espera máx. 1 beat; janela de timing **não muda de duração**).
- **Atrás de constante `BEAT_SYNC_ENABLED := false`** até validação: mexe em timing →
  obrigatório `/validate-controls` + sessão de playtest antes de ligar (mesmo
  protocolo do `GRADING_ON_WEB`).
- Bosses ficam de fora na v1 (padrões coreografados demais para quantizar).

### RF-A07 — A mata respira (ambiência reativa + silêncio dramático)

- `AudioDirector` ganha agendador de **eventos esparsos**: a cada 8–20 s (random),
  toca um `mata_event_*` em volume baixo, apenas em telas de exploração.
- **Silêncio pré-boss**: ao sinal `boss_intro_started`, a ambiência corta em fade
  rápido (0.3 s) ANTES do stinger de revelação — 1.5 s de mata muda; o sino/berro
  do boss nasce do silêncio. (Hoje o stinger toca por cima da ambiência cheia.)
- **Game over**: tudo morre menos um agudo fino (zumbido pós-trauma, 2 s) antes do
  `sting_game_over` — a morte da Caipora ensurdece a mata.

### RF-A08 — Opções de áudio completas

- `options_panel.gd`: já tem sliders por bus; adicionar slider **Reverb** (wet do bus
  novo) só se couber sem redesenho — senão fica fora (decisão de UI, não de áudio).
- Persistência: novas chaves na seção `audio` do `settings.cfg` (padrão existente).

---

## 6. Requisitos Não-Funcionais

- **RNF-1 — Peso:** áudio total ≤ 9 MB pós-RF-A04/A05 (hoje 5.7 MB; stems são o maior
  acréscimo). Se estourar: avaliar OGG Vorbis **apenas para música** (Godot suporta;
  loop via `AudioStreamOggVorbis.loop = true` em runtime, mesmo padrão do
  `_force_loop`). Custo: `ffmpeg` como dependência do `make audio` (não do jogo).
  Decisão adiada até medir.
- **RNF-2 — Reprodutibilidade:** `make audio` com as mesmas seeds gera bytes idênticos.
  Nenhum asset de áudio editado à mão.
- **RNF-3 — Performance Web:** stems = +2 players de música persistentes (total 5) —
  custo desprezível; eventos esparsos reusam o padrão de player descartável. Nada de
  decodificação OGG por SFX curto (WAV decode é trivial).
- **RNF-4 — Zero acoplamento novo:** arena/exploração continuam falando com áudio
  **somente via SignalBus**. Nenhum `get_node` cruzado.
- **RNF-5 — Graceful degradation:** todo asset novo é opcional em runtime
  (`ResourceLoader.exists`) — o jogo nunca quebra por asset faltante, padrão atual.

---

## 7. Etapas de Execução

Uma etapa por sessão (protocolo do projeto), cada uma commitável e com gate verde:

| Etapa | Entrega | Toca em |
|-------|---------|---------|
| **E1** | Padrão + `check_audio.py` + `make audio`/`audio-check` | Makefile, tools |
| **E2** | Motor de síntese v2 + regeneração de TODOS os assets atuais | `gen_sfx.py`, assets |
| **E3** | Bus Reverb + perfis de espaço + EQ Music + duck no perfect | bus layout, AudioDirector |
| **E4** | Stems adaptativos (arena + bosses) + modo coração | gen_sfx, AudioDirector, SignalBus |
| **E5** | SFX novos (RF-A05) + wiring por sinais | gen_sfx, SfxSystem, AudioDirector |
| **E6** | Mata viva: eventos esparsos + silêncio pré-boss + game over | AudioDirector |
| **E7** | Beat-sync atrás de flag + `/validate-controls` + playtest | arena, timing ⚠️ |
| **E8** | Medição em dispositivo (peso/carga/FPS) + decisão OGG + ligar flags | export |

E7 é a única etapa que toca timing de combate — isolada de propósito, pode ser
cortada sem afetar as demais.

---

## 8. Critérios de Aceitação

1. `make audio` regenera o catálogo inteiro; `make audio-check` passa 100%.
2. `make gate` verde em todas as etapas; testes novos:
   - `test_audio_director.gd`: intensidade de stems (0→1→2→coração), perfis de reverb
     por tela, beat map carregado;
   - `test_sfx_variants.gd`: novos sons com 3 variantes registradas.
3. Na arena: com HP < 30%, mid/top silenciam e o heartbeat entra em ≤ 1 compasso;
   curar acima de 30% restaura.
4. Na igreja (P5), bater Espaço produz cauda de reverb audivelmente diferente da mata
   (P1) — validação por escuta em dispositivo, registrada no REPORT.
5. Silêncio pré-boss perceptível (ambiência −40 dB antes do stinger de revelação).
6. Peso total de `assets/audio/` ≤ 9 MB; carga itch.io sem regressão (< 10 s).
7. `/validate-controls` e `/validate-platforms` verdes antes de qualquer merge que
   toque E7.

---

## 9. Riscos & Mitigações

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Stems dessincronizam no browser (latência de mix) | música vira mingau | iniciar os 3 players no mesmo frame com o MESMO stream length; medir drift em E8; se driftar, fundir stems em pares |
| Beat-sync piora o game-feel | combate mais lento/previsível | flag desligada por padrão; espera máx 1 beat; cortável (E7 isolada) |
| Reverb de bus caro no mobile | FPS em celular fraco | `AudioEffectReverb` é leve, mas medir em E8; perfil MATA quase seco já é o caso comum |
| Peso estoura 9 MB | carga lenta itch.io | RNF-1: rota OGG p/ música (−80% de peso) já desenhada |
| Regenerar assets v2 muda sons que o usuário já aprovou (hub samba lofi, assovio dessirenizado) | regressão estética | E2 regenera com A/B: commits separados por categoria; escuta antes de commitar; faixas ajustadas à mão no passado (seeds) são preservadas |
| MCP/`.import` | loops quebrados pós-import | manter `_force_loop` runtime (padrão atual); nunca depender de flags de import |

---

## 10. Fora de Escopo (v2)

- Áudio posicional/espacial (`AudioStreamPlayer2D`) — arena cabe numa tela; pan não
  agrega o suficiente pelo custo de revisar todo o wiring.
- Voz/vocalizações gravadas — quebra a regra "tudo procedural".
- Trilha dinâmica horizontal (transições por seção musical) — vertical primeiro;
  horizontal só se os stems provarem valor.
- Modo surdo/acessibilidade visual de cues sonoros — vale PRD próprio (cues visuais
  já existem nos telegraphs).

---

## 11. Glossário

- **Stem** — camada isolada de uma mesma música (mesmo BPM/duração), mixada em runtime.
- **Stinger** — one-shot musical que marca um evento (vitória, baú, revelação).
- **Ducking** — abaixar música/ambiência momentaneamente para um som furar o mix.
- **LUFS** — unidade de loudness percebida; padrão de normalização entre faixas.
- **Baque virado** — batida do maracatu pernambucano; base rítmica do jogo.
