# PLANO — Redesign Caçador & Bruxo ("Os que invadem a mata")

> **Objetivo:** trazer os dois monstros comuns das fases — o **Caçador**
> (espingarda) e o **Bruxo** (ritual) — para o estilo e o tom estético definidos
> pela protagonista aprovada (`docs/CONCEITO-protagonista.md`), com sprites
> premium orgânicos gerados pelo mesmo tipo de pipeline reprodutível da Caipora.
>
> Skill obrigatória durante a execução: `.agents/skills/visual-identity/SKILL.md`.
> Após a prancha de conceito ser aprovada, a direção final é consolidada em
> `docs/CONCEITO-inimigos.md` (lei visual dos inimigos), como foi feito com a
> protagonista.

---

## 1. Diagnóstico — por que redesenhar

| Asset | Hoje | Problema |
|-------|------|----------|
| `enemy_idle/windup.png` (Caçador) | 48×48, `gen_chars.py hunter()` — grade de `rect()` pixel a pixel | Paleta antiga (pele humana clara, poncho marrom genérico), rosto humano visível, formas quadradas, sem outline contínuo. Parece de outro jogo ao lado da Caipora nova. |
| `bruxo_idle/windup.png` (Bruxo) | 48×48, **cópia literal do boss** (`axe_hunter()`) | Placeholder assumido: mesmo desenho do Caçador-de-Machados (boss base). O Bruxo não tem identidade própria; manto roxo brilhante e olhos laranja competem com a marca da protagonista. |

A protagonista usa pipeline premium (`gen_caipora.py`): **formas orgânicas
vetoriais supersampled 8× → downsample por área → snap de paleta fechada →
outline 1px**. Os inimigos seguem na técnica antiga de grade. É essa distância
de acabamento — não só de paleta — que quebra a coesão.

## 2. Direção de arte

### 2.1 Princípio

A Caipora é a dona da mata. Caçador e Bruxo são **os invasores**: humanos que
quebraram os pactos. Eles pertencem ao mesmo mundo (horror folclórico
brasileiro, pixel art chapada, sangue real), mas **contrastam** com ela:

- A Caipora é **laranja vibrante + vazio preto + olhos brancos redondos**.
- Os invasores são **terra, couro, breu e osso** — tons mortos, sujos de mata e
  de sangue. Nada neles pode roubar a primeira leitura da tela.

### 2.2 Travas de marca (NUNCA quebrar)

1. **Nenhum inimigo tem olhos brancos redondos** — isso é assinatura exclusiva
   da Caipora. Olhos de inimigo são brasas mortiças, fendas ou sombra.
2. **Nenhum inimigo usa o laranja `#ff4500` / `#8b2a00` da juba** nem massa
   laranja dominante. Fogo/brasa pontual é permitido (mundo compartilhado),
   laranja-marca não.
3. **Verde `#00fa9a` é exclusivo do cristal/Fúria.** Zero verde frio em inimigo.
4. **Acabamento chapado igual ao da protagonista:** máx. 2 tons por material,
   outline escuro 1px contínuo, sem gradiente, sem dither, sem brilho glossy.
5. **Horror físico, nunca fofo:** sangue, troféu de caça, osso, marca ritual,
   pano podre. Não sanitizar.
6. **Silhueta primeiro:** se o personagem não lê em 32px como mancha + 1
   assinatura, o desenho não está pronto.

### 2.3 Caçador — "o predador de chapéu"

Humano que caça o que a mata protege. Leitura a 32px: **a aba do chapéu e o
cano comprido da espingarda**.

- **Silhueta-assinatura:** chapéu de aba larga engolindo o rosto + cano da
  espingarda atravessando a silhueta. Poncho de barra esfarrapada/serrilhada
  (eco da linguagem serrilhada do mundo, em pano de terra).
- **Rosto:** SOMBRA. A aba do chapéu afoga o rosto num vazio escuro; dentro,
  dois brilhos vermelho-sangue baixos (`fendas`, nunca círculos brancos).
  Sem boca, sem expressão — o humano já se desumanizou.
- **Horror físico:** colar de dentes/garras (troféus da mata), mancha de sangue
  seco na barra do poncho, coronha lascada.
- **Poses (contrato atual, 2 frames):**
  - `idle` — espingarda atravessada, peso pronto, aba escondendo o rosto.
  - `windup` — pontaria: cano nivelado no olhar, reflexo frio na boca do cano,
    corpo cravado 1px mais baixo. O telegraph é gameplay (combate de timing):
    a mudança de silhueta deve ser inconfundível.

**Paleta-guia (fechada, 2 tons por material, ajuste fino na prancha):**

| Material | Ramp |
|----------|------|
| Chapéu/couro | `#241509 → #3d2614` |
| Poncho/pano | `#4a2a1e → #6b3d24` |
| Pele (mínima, queixo na sombra) | `#8a6a4e` + sombra |
| Aço da espingarda | `#2a2624 → #8a8a92` (fio/reflexo) |
| Olhos/sangue | `#c81e14` (brilho), `#8b0000` (mancha) |
| Contorno | `#1a120a` (1px, mesma do mundo) |

### 2.4 Bruxo — "o feiticeiro do breu"

Identidade NOVA (hoje é cópia do boss). Quem negocia com o que não devia, do
lado errado do pacto. Leitura a 32px: **o capuz pontudo torto e o cajado de
osso com fetiche**.

- **Silhueta-assinatura:** capuz pontudo QUEBRADO/torto no meio (nunca o pico
  reto do boss) + cajado de osso coroado por um fetiche (crânio de bicho
  pequeno / amarrado de ossos). Manto esfarrapado até o chão.
- **Rosto:** vazio de breu dentro do capuz com dois olhos de **brasa mortiça em
  fenda** (`#c83c14`) — formato e cor opostos aos olhos da Caipora.
- **Horror físico:** marcas rituais de sangue no manto, dedos longos e finos
  (mão de galho), amarrados de osso pendurados no cinto/cajado.
- **Poses (contrato atual, 2 frames):**
  - `idle` — curvado sobre o cajado fincado, capuz tombado, dedos enroscados.
  - `windup` — cajado e braço erguidos, fetiche aceso (brasa ritual pontual),
    manto abrindo a silhueta. Telegraph inconfundível.

**Paleta-guia (fechada):**

| Material | Ramp |
|----------|------|
| Manto/capuz (breu-roxo podre) | `#1c0f28 → #3a1f52` |
| Osso (cajado/fetiches) | `#9c8c70 → #d8c8a8` |
| Olhos/brasa ritual | `#c83c14` + ponto `#e8742c` (mortiço, nunca `#ff4500`) |
| Sangue ritual | `#8b0000` |
| Contorno | `#1a120a` |

## 3. Pipeline técnico (premium orgânico reprodutível)

Mesma receita da protagonista, parametrizada para 48×48:

1. **Novo gerador `scripts/tools/gen_inimigos.py`** (determinístico, stdlib +
   Pillow), com `Painter` próprio parametrizado por tamanho:
   - desenho **orgânico** em polígonos/elipses/`limb()` supersampled 8×
     (384×384) — adeus `rect()` em grade;
   - downsample por área → 48×48 + threshold de alpha (sem halos);
   - **snap de paleta fechada por personagem** (cada pixel cai na cor mais
     próxima da paleta daquele inimigo);
   - **outline 1px `#1a120a`** em todo pixel opaco que toca transparência.
2. **`gen_chars.py` delega** caçador e bruxo ao novo módulo (como já delega a
   protagonista ao `gen_caipora`) e continua sendo o entrypoint único de
   regeneração. `hunter()`/`axe_hunter()` antigos ficam SOMENTE para
   `boss_idle/boss_windup.png` até a sessão própria do boss.
3. **Prancha de conceito `assets/sprites/inimigos_contact_sheet.png`**: cada
   pose em 1× e ampliada (NEAREST), lado a lado com a Caipora idle para checar
   hierarquia visual — quem manda na tela é ela.
4. **`gen_caipora.py` NÃO é tocado.** O gerador da protagonista é lei; nada de
   refatorar pipeline compartilhado nesta tarefa (risco de mudar pixels dela).

## 4. Contratos que NÃO mudam

Para não tocar cenas, colisões, zoom nem `.tres` (gotcha #7 — edição de
`.tscn` é perigosa):

- **Nomes de arquivo:** `enemy_idle.png`, `enemy_windup.png`, `bruxo_idle.png`,
  `bruxo_windup.png`.
- **Tamanho 48×48** (regra de `assets/AGENTS.md`; offset `-8` nas cenas, grid
  lógico 32, colisão 64×64 da arena e escala do mapa permanecem válidos).
- **2 animações** (`idle` loop, `windup` one-shot) em
  `criatura_sprite_frames.tres` / `bruxo_sprite_frames.tres` — intocados.
- **Consumidores intocados:** `scenes/arena/cacador.tscn`, `bruxo.tscn`,
  `scripts/exploration/map_enemy.gd`, `scripts/entities/cacador.gd`/`bruxo.gd`.
- **`boss_idle/boss_windup.png` intocados** nesta tarefa (ver §7).

## 5. Testes e validação

1. **Novo `tests/unit/test_inimigos_sprite_assets.gd`** (espelha
   `test_caipora_sprite_assets.gd`):
   - contrato 48×48 e massa visual mínima nos 4 PNGs;
   - cores-assinatura presentes (couro do caçador, breu do bruxo, brasa/sangue);
   - **travas de marca:** zero pixel branco-puro `#ffffff` (olho é da Caipora),
     zero `#ff4500` e zero `#00fa9a` nos inimigos.
2. Gotcha #12: não há `class_name` novo, mas **conferir que o total de testes
   SOBE** no sumário do GUT após adicionar o arquivo.
3. **`make gate`** (smoke + GUT) antes de cada commit.
4. **Validação visual em jogo:** screenshot da arena (caçador e bruxo em combate,
   idle e windup) e da exploração (mapa), via `scripts/tools/screenshot.gd`.
   Checklist da skill §5: a Caipora segue sendo a marca mais memorável da tela?
   A silhueta de cada inimigo lê em 32px? O windup telegrafa?
5. Sem mudança de input/timing — `/validate-controls` não é exigido; se o ajuste
   encostar em timing de windup (não deve), rodar antes do commit.

> **Ambiente:** geração exige Python + Pillow; gate exige Godot headless
> (instalável no container remoto — 4.6.3-stable roda o gate completo).
> Pillow instala via `pip install Pillow`. Só a validação visual em jogo
> (etapa 4, screenshots com display) pede o harness local/WSLg.

## 6. Etapas de execução (uma por sessão, commit por etapa)

| Etapa | Entrega | Gate |
|-------|---------|------|
| **0. Plano** (este doc) | `docs/PLANO-redesign-cacador-bruxo.md` | — |
| **1. Pipeline + Caçador** | `gen_inimigos.py` (Painter 48px + snap + outline), caçador idle/windup novos, prancha `inimigos_contact_sheet.png`, delegação em `gen_chars.py` | `make gate` + prancha aprovada |
| **2. Bruxo** | identidade nova do bruxo (idle/windup) no mesmo pipeline; prancha atualizada | `make gate` + prancha aprovada |
| **3. Testes de contrato** | `test_inimigos_sprite_assets.gd` (contrato + travas de marca); confirmar contagem de testes subiu | `make gate` |
| **4. Validação em jogo + lei visual** | screenshots arena/exploração, ajuste fino de leitura; consolidar `docs/CONCEITO-inimigos.md`; adicionar o doc novo às fontes canônicas da skill `visual-identity`; atualizar `assets/AGENTS.md` (citar o gerador novo) | `make gate` |

## 7. Fora de escopo / follow-ups

- **Boss (Caçador-de-Machados)** continua com a arte legada de `axe_hunter()` —
  divergirá visualmente do bruxo novo de propósito. Sessão futura: redesenhar
  boss e minibosses (mula, boitatá, curupira, saci, jesuíta) no mesmo pipeline,
  um por sessão.
- **Mais frames por inimigo** (walk/strike/death): exigiria mexer em `.tres` e
  estados — só depois que idle/windup novos assentarem.
- **Atmosfera de cena** (vinheta/grão) não entra aqui: o clima sombrio vem da
  cena, não de dessaturar sprite (lei da protagonista).

## 8. Riscos

| Risco | Mitigação |
|-------|-----------|
| Detalhe fino vira ruído no snap em 48px | Formas grandes primeiro; validar silhueta em preto antes de detalhe; máx. 2 tons por material |
| Windup fraco quebra o combate de timing | Mudança de silhueta obrigatória no windup (cano nivelado / cajado erguido) + validação em jogo na etapa 4 |
| Inimigo novo competir com a marca da Caipora | Travas de marca (§2.2) viram asserts no teste de assets |
| Tocar `.tscn`/`.tres` sem querer | Contratos do §4: nomes, tamanho e animações idênticos — zero mudança em cena/resource |
