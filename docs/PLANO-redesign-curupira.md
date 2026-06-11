# PLANO — Redesign Curupira ("O Parente Mais Antigo")

> **Objetivo:** trazer o boss da Fase 3 — o **Curupira**, o mais antigo protetor
> da mata — para o estilo e o tom estético definidos pela protagonista aprovada
> (`docs/CONCEITO-protagonista.md`), com sprites **AAA premium** gerados pelo
> mesmo pipeline reprodutível da Caipora e dos invasores. Primeira sessão de
> redesign de chefe do KI-012 (canvas ≥128, escala de nó de volta a 1.2).
>
> Skill obrigatória durante a execução: `.agents/skills/visual-identity/SKILL.md`.
> Após a prancha de conceito ser aprovada, a direção final é consolidada em
> `docs/CONCEITO-curupira.md` (lei visual do chefe), como foi feito com a
> protagonista e os invasores.

---

## 1. Diagnóstico — por que redesenhar

| Asset | Hoje | Problema |
|-------|------|----------|
| `curupira_idle.png` | 48×48, `gen_chars.py curupira()` — grade de `rect()` pixel a pixel | Técnica e acabamento de outra era do projeto: sem outline contínuo, 3+ tons por material, formas quadradas. |
| Cabelo | Laranja vivo `#ff6b00 → #ffa838` | **Viola a trava de marca**: laranja vibrante é assinatura exclusiva da juba da Caipora. No mapa da Fase 5 os dois ficam lado a lado e competem. |
| Rosto | Olhos verde-limão com brilho + **sorriso de dentes** | Lê como mascote travesso, não como o protetor antigo e indiferente que o `curupira.gd` descreve ("Indiferente e letal"). Quebra o tom GORE/TERROR. |
| Escala | `sprite_scale = 2.0` na arena (mundo usa 1.2) | Texels ~67% maiores que Caipora/invasores — exatamente o débito do KI-012. |
| Poses | 1 frame (`idle`) | O boss com os DOIS padrões de timing mais punitivos do jogo (RASTRO 2.5x, ASSOBIO 3x com janela mínima) não tem mudança de silhueta no windup — o telegraph é só tween de modulate/scale. `ArenaManager` já chama `play_pose(&"windup")` (arena_manager.gd:409) e o `ActorAnimator` tocaria o frame **se ele existisse** no `.tres`. |

A protagonista e os invasores usam o pipeline premium (**formas orgânicas
vetoriais supersampled 8× → downsample por área → snap de paleta fechada →
outline 1px `#1a120a`**). O Curupira segue na técnica antiga de grade. É essa
distância de acabamento — somada à violação de paleta — que quebra a coesão.

## 2. Direção de arte — "o parente mais antigo da mata"

### 2.1 Princípio

O Curupira é **parente da Caipora** (lei do projeto: o pé-pra-trás é dele, não
dela). Mesma espécie de entidade, mas mais velho, indiferente e letal. Ele deve
ler como **eco** dela, nunca como cópia:

- A Caipora é **laranja vibrante + vazio preto + olhos brancos redondos** —
  predadora pronta, eriçada.
- O Curupira é **verde profundo + vazio de breu + fendas verde-mata** — o
  protetor antigo que nem se dá ao trabalho de se eriçar. A crista
  vermelho-sangue é fogo que já queimou e apagou ("sem fogo" é lei dele:
  chama viva pertence a Saci/Mula).

O parentesco está na **linguagem** (massa serrilhada envolvendo a cabeça, rosto
vazio sem expressão humana, proporção de criança da mata); a diferença está na
paleta, na postura e nos PÉS.

Leitura a 32px: **os pés ao contrário + a crista serrilhada vermelho-sangue**.

### 2.2 Travas de marca (NUNCA quebrar — viram assert no GUT)

1. **Zero olhos brancos redondos** (`#ffffff` é assinatura exclusiva da
   Caipora). Os olhos do Curupira são **fendas** verde-mata, semicerradas.
2. **Zero laranja da juba** (`#ff4500` / `#8b2a00`) e zero massa laranja
   dominante. A crista é vermelho-sangue ESCURO, nunca laranja vivo.
3. **Zero verde `#00fa9a`** (exclusivo do cristal/Fúria). O verde do Curupira
   é verde-FOLHA (matiz amarelado, família do `COLOR_DIALOGUE_CURUPIRA`),
   nunca o verde-frio mentolado do cristal.
4. **Acabamento chapado:** máx. 2 tons por material, outline 1px `#1a120a`,
   sem gradiente, sem dither, sem brilho glossy.
5. **Horror físico:** sangue seco, cicatriz de machado, lama, garra. Nunca
   sorriso, nunca mascote.
6. **Silhueta primeiro:** se não ler a 32px como mancha + pés invertidos +
   crista, o desenho não está pronto.

### 2.3 As 5 assinaturas do Curupira

1. **PÉS AO CONTRÁRIO** — a assinatura folclórica e a lei do projeto. Dedos
   (com garras) apontando para TRÁS, calcanhares para a frente, exagerados o
   bastante para ler a 32px. Sob os pés, **pegadas invertidas de sangue/lama**
   — eco direto do padrão RASTRO (←→←→) que confunde a leitura do jogador.
2. **Crista serrilhada vermelho-sangue** — cabelo selvagem subindo em picos
   serrilhados (eco da juba dela na LINGUAGEM, não na cor): ramp escuro
   `#5a100a → #a8281e`. É brasa apagada/sangue seco, não chama — o Curupira
   é "sem fogo".
3. **Vazio de breu com fendas verde-mata** — rosto vazio emoldurado pela
   crista: sem boca, sem dentes, sem expressão humana (parente da Caipora — o
   horror é a ausência). Dois olhos em **fenda horizontal semicerrada**
   verde-folha (`#2fa838` + ponto vivo `#66d44e`, poucos pixels), a
   indiferença de quem é mais antigo que o medo. Casam com o telegraph
   overbright (`COLOR_TELEGRAPH_CURUPIRA`) e a voz verde do diálogo.
4. **Corpo de mata** — pele verde profundo (2 tons, `#14381c → #2a6b34`,
   família da aura `COLOR_AURA_CURUPIRA`), tronco curto, braços longos caídos.
   Horror físico: **talhos de machado cicatrizados** no tronco (os invasores
   tentaram — e estão mortos) e sangue seco `#8b0000` nas garras dos pés.
5. **Postura indiferente** — ele NÃO se agacha em bote como ela: fica ereto,
   peso assentado, cabeça levemente baixa, braços pendendo. A criança da mata
   parada no corredor é mais assustadora que qualquer pose de ataque.

### 2.4 Poses (idle + windup novo)

- `idle` (loop) — a postura indiferente da §2.3.5: ereto, fendas semicerradas,
  pés invertidos plantados, pegadas de sangue atrás (na direção "errada").
- `windup` (one-shot, **NOVO**) — a indiferença QUEBRA, e isso é gameplay
  (telegraph do combate de timing): agachamento súbito de mola, crista
  eriçando em picos mais altos e abertos, fendas escancarando (mas nunca
  redondas brancas), dedos abrindo em garra, pé invertido cravando o chão.
  Mudança de silhueta inconfundível. Os telegraphs por tween existentes
  (pulso verde do RASTRO, double-jump do ASSOBIO em `curupira.gd`) permanecem
  intactos e SOMAM por cima do frame — nenhum timing muda.

### 2.5 Paleta-guia (fechada, 2 tons por material, ajuste fino na prancha)

| Material | Ramp |
|----------|------|
| Pele/corpo | `#14381c → #2a6b34` (verde profundo da mata, família da aura) |
| Crista/cabelo | `#5a100a → #a8281e` (vermelho-sangue, fogo morto — nunca `#ff4500`) |
| Vazio do rosto | breu (`#0a0d08`) |
| Olhos (fendas) | `#2fa838` + ponto `#66d44e` (verde-FOLHA — nunca `#00fa9a`) |
| Garras/dedos | osso `#d8c8a8` em poucos pixels |
| Sangue (pegadas, garras, talhos) | `#8b0000` |
| Contorno | `#1a120a` (1px, mesma do mundo) |

## 3. Pipeline técnico (premium orgânico reprodutível)

Mesma receita dos invasores, parametrizada para o canvas de chefe (KI-012):

1. **Novo gerador `scripts/tools/gen_bosses.py`** (determinístico, stdlib +
   Pillow) que **importa** `Painter`/snap/outline de `gen_inimigos.py` (já
   parametrizado por tamanho) e abriga os redesigns de chefe, um por sessão —
   Curupira primeiro. Se o `Painter` precisar de um parâmetro `grid` novo
   (grade de desenho ≠ 48), a mudança é aditiva com default atual — os pixels
   de caçador/bruxo NÃO mudam (guardado por `test_inimigos_sprite_assets.gd`).
2. **Canvas 128×128 na arena** + **variante de mapa 48×48** re-renderizada dos
   MESMOS vetores (`curupira_map.png`) — nunca downscale NEAREST do asset
   grande. No mapa os bosses seguem 48×48 (KI-012).
3. **Altura visual herdada, não inventada:** a escala de nó volta a **1.2** e o
   corpo desenhado é calibrado para manter a altura visual ATUAL do contrato
   (~46px opacos × 2.0 ≈ 92px → ~76–77px desenhados × 1.2), porque
   `test_boss_scale_proportions.gd` trava: Curupira lê 0.9–1.1× a Caipora
   (criança da mata) e assenta os pés na MESMA linha de chão (±4px). O offset
   de pés da cena é recalculado pela fórmula do próprio teste.
4. **Snap de paleta fechada** do §2.5 + **outline 1px `#1a120a`**.
5. **`gen_chars.py` delega** o Curupira ao módulo novo (como já delega
   protagonista e invasores) e o `curupira()` legado é removido. Os demais
   bosses legados não são tocados.
6. **Prancha `assets/sprites/curupira_contact_sheet.png`**: idle e windup em 1×
   e ampliados (NEAREST), lado a lado com a Caipora idle e o caçador — checa o
   parentesco (≈ altura dela, criança da mata), o contraste de paleta e a
   hierarquia (quem manda na tela é ela).
7. **`gen_caipora.py` e `gen_inimigos.py` (desenhos) NÃO são tocados.**

## 4. Contratos — o que muda e o que não muda

**NÃO muda** (gameplay, identidade de cena e consumidores):

- HP (`CURUPIRA_MAX_HEALTH = 30`), padrões RASTRO/ASSOBIO, chances, danos e
  TODOS os timings de janela — redesign é visual.
- Cores de runtime: `COLOR_TELEGRAPH_CURUPIRA`, `COLOR_AURA_CURUPIRA`,
  `COLOR_DIALOGUE_CURUPIRA` (a paleta nova foi escolhida para casar com elas).
- Nome de arquivo `curupira_idle.png` (passa a 128×128) e o caminho do
  `curupira_sprite_frames.tres`.
- Roteamento de exploração, diálogo pré-boss, `boss_intro_screen`, música
  (`mus_boss_curupira`) e SFX.

**Muda, de forma controlada** (cada item com seu guardião):

| Mudança | Onde | Guardião |
|---------|------|----------|
| Canvas 48→128 (arena) | `curupira_idle.png` (+ `curupira_windup.png` novo) | `test_curupira_sprite_assets.gd` (novo) |
| `sprite_scale` 2.0 → 1.2 + offset de pés | `scenes/arena/curupira.tscn` (diff mínimo à mão — gotcha #7: conferir `git diff` do `.tscn`) | `test_boss_scale_proportions.gd` (entry atualizada na MESMA etapa) |
| Sprite do mapa | novo `curupira_map.png` 48×48; `map_enemy.gd` aponta `CURUPIRA_TEXTURE` para ele (cobre boss P3 E convertido P5 num único const; offset `-8` do mapa fica válido) | contrato 48×48 no teste novo |
| Animação `windup` | `curupira_sprite_frames.tres` ganha anim one-shot (frame único, sem loop) — `ActorAnimator`/`arena_manager.gd:409` tocam sozinhos, zero código | `/validate-controls` + teste de silhueta windup ≠ idle |

## 5. Testes e validação

1. **Novo `tests/unit/test_curupira_sprite_assets.gd`** (espelha
   `test_inimigos_sprite_assets.gd`):
   - contrato de tamanho: idle/windup 128×128, mapa 48×48, massa visual mínima;
   - assinaturas presentes: verde profundo do corpo, vermelho-sangue da
     crista, fendas verde-folha, sangue `#8b0000`;
   - **travas de marca:** zero `#ffffff`, zero `#ff4500`/`#8b2a00`, zero
     `#00fa9a`;
   - **windup telegrafa:** silhueta do windup difere da do idle acima de um
     limiar de pixels (o telegraph é gameplay).
2. **`test_boss_scale_proportions.gd`**: entry do Curupira atualizada
   (`1.2` + offset novo) na mesma etapa da troca de escala — os asserts de
   hierarquia (0.9–1.1× Caipora) e linha de pés são o guia da calibragem.
3. Gotcha #12: sem `class_name` novo em GDScript, mas **conferir que o total
   de testes SOBE** no sumário do GUT após adicionar o arquivo.
4. **`make gate`** (smoke + GUT) antes de cada commit; **`/validate-controls`**
   na etapa do windup (encosta na linguagem do telegraph; timings não mudam).
5. **Validação visual em jogo** (`scripts/tools/screenshot.gd`):
   - arena P3: idle, windup, telegraph RASTRO (pulso verde) e ASSOBIO
     (double-jump) sobre o sprite novo; boss intro (pop do modelo 128);
   - mapa P3: boss 48×48 com aura verde na célula mais profunda;
   - mapa/arena P5: Curupira convertido com `COLOR_BAPTISM_TINT` + pingos de
     batismo — o tint frio precisa continuar lendo sobre o verde novo;
   - checklist da skill §5: a Caipora segue sendo a marca mais memorável? A
     silhueta lê em 32px? O parentesco lê sem roubar a marca dela?

> **Ambiente:** geração exige Python + Pillow (`pip install Pillow`); gate
> exige Godot headless (instalável no container remoto — 4.6.3-stable roda o
> gate completo). Só a validação visual em jogo (screenshots com display) pede
> o harness local/WSLg.

## 6. Etapas de execução (uma por sessão, commit por etapa)

| Etapa | Entrega | Gate |
|-------|---------|------|
| **0. Plano** (este doc) | `docs/PLANO-redesign-curupira.md` | — |
| **1. Pipeline + idle** | `gen_bosses.py` (reuso do Painter), `curupira_idle.png` 128 + `curupira_map.png` 48, cena 1.2/offset, `map_enemy.gd` apontado, entry de escala atualizada, prancha `curupira_contact_sheet.png`, delegação em `gen_chars.py` | `make gate` + prancha aprovada |
| **2. Windup** | `curupira_windup.png` + anim `windup` no `.tres` (ActorAnimator toca sozinho); prancha atualizada | `make gate` + `/validate-controls` |
| **3. Testes de contrato** | `test_curupira_sprite_assets.gd` (contrato + travas + windup≠idle); contagem de testes subiu | `make gate` |
| **4. Validação em jogo + lei visual** | screenshots arena/mapa P3 e P5, ajuste fino de leitura; consolidar `docs/CONCEITO-curupira.md`; adicionar às fontes da skill `visual-identity`; atualizar `assets/AGENTS.md` (tabela de escala) e PLAN.md (KI-012: Curupira ✅) | `make gate` |

## 7. Fora de escopo / follow-ups

- **Demais chefes** (Mula, Boitatá, Saci, Jesuíta, Caçador-de-Machados) seguem
  com a arte legada 48×48 — uma sessão de redesign cada, no mesmo
  `gen_bosses.py`.
- **Mais frames** (walk/strike/death) — só depois que idle/windup assentarem.
- **Áudio** — `mus_boss_curupira` e `boss_death_curupira` já existem e não
  mudam.
- **Atmosfera de cena** (vinheta/grão/CanvasModulate verde da P3) não entra: o
  clima sombrio vem da cena, não de dessaturar o sprite (lei da protagonista).

## 8. Riscos

| Risco | Mitigação |
|-------|-----------|
| Crista vermelha ler como o laranja da Caipora | Ramp escuro de sangue (`#5a100a → #a8281e`), prancha lado a lado com ela, assert zero `#ff4500`/`#8b2a00` |
| Verde dos olhos colidir com o cristal/Fúria | Matiz de FOLHA (amarelado) vs. mentolado do cristal; assert zero `#00fa9a` |
| Detalhe fino (garras, pegadas, talhos) virar ruído no snap | Formas grandes primeiro; validar silhueta em preto; máx. 2 tons por material; pegadas como manchas, não desenho |
| Mudança de escala quebrar hierarquia/linha de pés | O contrato de `test_boss_scale_proportions.gd` é o guia da calibragem, atualizado na MESMA etapa; altura visual herdada (~92px), nunca reinventada |
| Tocar `Painter` quebrar caçador/bruxo | Parâmetro novo com default atual (mudança aditiva); `test_inimigos_sprite_assets.gd` trava os pixels deles |
| Editar `.tscn`/`.tres` à mão corromper a cena (gotcha #7) | Diff mínimo (2 linhas na cena; 1 bloco de anim no `.tres`), `git diff` conferido, gate roda a cena no smoke |
| Windup fraco quebrar o combate de timing | Mudança de silhueta obrigatória + assert windup≠idle + `/validate-controls` + validação em jogo |
| Tint de batismo (P5) sumir sobre o verde novo | Checagem visual dedicada na etapa 4 |
