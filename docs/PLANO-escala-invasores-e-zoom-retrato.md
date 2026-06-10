# PLANO — Escala dos Invasores & Zoom de Combate em Retrato

> **Objetivo:** corrigir a hierarquia de escala — a Caipora é uma entidade
> pequena, do tamanho de uma criança (lore e proporção chibi da prancha);
> caçadores e bruxos são humanos adultos e devem se **agigantar sobre ela** —
> e aproximar o combate em modo retrato (zoom + atores mais próximos) para a
> ação ler grande no celular.
>
> Deriva de: `docs/CONCEITO-protagonista.md`, `docs/CONCEITO-inimigos.md`.
> Skill obrigatória: `.agents/skills/visual-identity/SKILL.md`.

---

## 1. Diagnóstico (auditado no código)

### Escala dos atores hoje

| Ator | Sprite | Escala na arena | Altura visual ≈ |
|------|--------|-----------------|-----------------|
| Caipora | 96×96 (corpo ~75px) | 1.2 (`caipora_combat.tscn`) | **~90px** |
| Caçador/Bruxo | 48×48 (corpo ~44px) | 1.0 | **~44px** |

A guardiã-criança tem o **dobro** do humano adulto — o inverso da lore. O
horror correto é o oposto: o invasor se agiganta sobre ela, e mesmo assim quem
manda na mata é ela.

### Enquadramento da arena hoje

- Atores fixos: Caipora `(160, 240)`, inimigo `(480, 240)` — 320px de distância.
- Câmera: fit *contain* de `STAGE_SIZE = 560×340`, `STAGE_FILL 0.92`, clamp
  0.5–2.0, snap de texel inteiro (`PixelScale.snap_contain`).
- **Em retrato (~393px) a largura manda:** zoom ≈ 0.67 → ação pequena, com
  vazio enorme entre os dois atores.
- **Armadilha:** bolhas de timing têm faixas hardcoded — 1ª bolha em
  `enemy.position + (0, -78)`; especiais do boss em `BOSS_BUBBLE_X (70..570)` /
  `BOSS_BUBBLE_Y (80..370)`. Zoom-in em retrato SEM derivar essas faixas do
  retângulo visível joga bolha pra fora da tela e quebra o combate de timing.

## 2. Direção — nova lei de escala

### 2.1 Escada de tamanhos (substitui a regra atual de `assets/AGENTS.md`)

| Asset | Canvas | Lógica |
|-------|--------|--------|
| Tiles/itens | 32×32 | grid lógico |
| Bosses/minibosses legados | 48×48 | até a sessão de redesign de cada um |
| **Caipora** | **96×96** (corpo ~75px) | a guardiã é PEQUENA — criança da mata; imponência vem da silhueta/juba, não do tamanho |
| **Invasores comuns (caçador/bruxo)** | **112×112** (corpo ~100–106px) | humanos adultos: ~1.35–1.4× a altura dela |
| Bosses redesenhados (futuro) | ≥128×128 | sempre ≥ comuns |

- A frase "Caipora maior que os caçadores" em `assets/AGENTS.md` e `PLAN.md`
  está ERRADA sob a nova direção e será corrigida nos docs.
- Mesma escala de nó na arena para ela e para os invasores (**1.2 ambos**):
  texels uniformes entre os atores; a hierarquia vem do canvas/desenho, nunca
  de escala fracionária diferente por ator.

### 2.2 O que isso muda na leitura

- Arena: invasor ~120–127px visuais vs Caipora ~90px — o caçador aponta a
  espingarda DE CIMA pra baixo; o bruxo se curva sobre ela como uma torre
  torta. O telegraph fica maior e mais legível de graça.
- Mapa (exploração): invasores usam a MESMA textura 112 em `scale 1.0` —
  ficam maiores que a Caipora (96) também no mapa, sem variante extra de
  asset e sem mexer nos `.tres`.
- Travas de marca, paletas e silhuetas de `docs/CONCEITO-inimigos.md`
  permanecem intactas — é a mesma arte, redesenhada no canvas maior (mais
  resolução para poncho rasgado, troféus, fetiche e crânio).

## 3. Combate em retrato — zoom + aproximação

Free orientation é lei (gotcha #10): tudo reage a `size_changed`, retrato E
paisagem.

1. **Posições orientation-aware:** extrair o enquadramento para um helper puro
   testável (`ArenaFraming`, padrão `PixelScale`): paisagem mantém
   `160/480`; retrato aproxima os atores (~`210/430`, ±220px) — o vazio
   central some.
2. **Fit por ACTION_SIZE em retrato:** o *contain* passa a usar um retângulo
   de ação mais estreito em retrato (~`400×340` em vez de `560×340`) → zoom
   sobe de ~0.67 para ~0.9–1.0 (com snap de texel e teto 2.0 preservados).
   Combate ~40–50% maior na tela. O corte lateral do palco é intencional;
   `ArenaBackdrop` precisa cobrir o enquadramento (verificar sangria do
   fundo — sem fresta transparente).
3. **Bolhas derivadas do retângulo visível (CRÍTICO):** `BOSS_BUBBLE_X/Y`,
   spread da bolha dupla e a âncora da 1ª bolha deixam de ser absolutos e
   passam a derivar de `camera.position ± vp/(2·zoom)` (com padding do D-pad
   já existente). Nada spawna fora da tela em nenhuma orientação.
4. **Âncora da 1ª bolha acompanha a altura nova do inimigo:** `-78` fixo vira
   offset derivado da altura visual do sprite (bolha acima da cabeça do
   invasor de 112px, dentro do rect visível).
5. **Rotação no meio do combate:** atores reposicionam no `size_changed`
   (mesmo hook do `_update_camera_fit`); bolhas já vivas mantêm posição
   (vida ~1–2s, janela curta) — spawns seguintes usam o rect novo.
6. **Ajustes dependentes:** offsets de pé (linha de chão y=240 comum aos
   dois atores — recalcular `offset` dos `AnimatedSprite2D`), colisão 64×64
   de `cacador/bruxo.tscn` → ~96×112, lunge da Caipora (+32px) e squash do
   `ActorAnimator` permanecem.

## 4. Contratos e consumidores

| Item | Estado |
|------|--------|
| Nomes de PNG (`enemy_*`, `bruxo_*`) e `.tres` | **intocados** (textura troca de tamanho por baixo) |
| `test_inimigos_sprite_assets.gd` | contrato 48→112, massa visual recalibrada; travas de marca idênticas |
| `cacador.tscn` / `bruxo.tscn` | offset do sprite + colisão (edição mínima e conferida no diff — gotcha #7) |
| `map_enemy.gd` | invasores `scale 1.0` (112px no mapa); bosses legados intocados |
| Bosses/minibosses (48px) | **fora de escopo** — ficarão menores que os comuns até suas sessões de redesign (registrar em PLAN.md como pendência conhecida) |
| `gen_caipora.py` / sprites dela | **intocados** (lei) |

## 5. Testes e validação

1. `test_inimigos_sprite_assets.gd` atualizado (112×112 + massa mínima maior).
2. **Novo `test_arena_framing.gd`** (helper puro): retrato aproxima atores e
   sobe o zoom; paisagem preserva o enquadramento atual; faixas de bolha
   sempre contidas no rect visível nas duas orientações (393×852, 852×393,
   tablet 1180×820).
3. `make gate` por commit; conferir contagem de testes SUBIU (gotcha #12).
4. **`/validate-controls`** (mexe em arena/timing) e **`/validate-platforms`**
   (mexe em câmera/UI) antes dos commits das etapas 1–2.
5. Validação visual via Xvfb: screenshots da arena em retrato E paisagem
   (fases 1–2) + prancha de conceito com Caipora e invasor na MESMA escala de
   jogo (1.2/1.2) para aprovar a hierarquia; conferir pés na linha de chão e
   bolha acima da cabeça.

## 6. Etapas de execução (uma por sessão, commit por etapa)

| Etapa | Entrega | Gate |
|-------|---------|------|
| **0. Plano** (este doc) | `docs/PLANO-escala-invasores-e-zoom-retrato.md` | — |
| **1. Hierarquia de escala** | `gen_inimigos.py` em 112×112 (corpo ~100–106px, geometria reescalada), prancha em escala de jogo, offsets/colisão das cenas, `map_enemy` scale, testes de contrato atualizados | gate + `/validate-controls` + prancha aprovada |
| **2. Enquadramento retrato** | `ArenaFraming` (posições + ACTION_SIZE + faixas de bolha derivadas do rect visível), `size_changed`, `test_arena_framing.gd` | gate + `/validate-controls` + `/validate-platforms` |
| **3. Lei e docs** | `CONCEITO-inimigos.md` (lei de escala §2.1), `assets/AGENTS.md` (escada de tamanhos, remover "maior que os caçadores"), `PLAN.md` (correção + pendência dos bosses) | gate |
| **4. Validação em jogo** | screenshots retrato/paisagem fases 1–2, ajuste fino de pés/bolhas/zoom | gate |

## 7. Riscos

| Risco | Mitigação |
|-------|-----------|
| Bolha de timing fora da tela em retrato (boss) | Faixas derivadas do rect visível + teste unit por orientação — é o item mais crítico do plano |
| Pés desalinhados na linha de chão | Offset recalculado a partir do foot_y real de cada canvas + screenshot de validação |
| Boss menor que os comuns (interim) | Assumido e documentado; resolve nas sessões de redesign dos bosses no mesmo pipeline |
| Corte lateral do palco em retrato expor borda do fundo | Conferir sangria do `ArenaBackdrop` no enquadramento novo (test_arena_backdrop + screenshot) |
| Rotação no meio do turno | Reposicionamento no `size_changed`; bolhas vivas mantêm posição (janela curta) |
| Texels mistos entre atores | Escala de nó IGUAL (1.2) para Caipora e invasores |
