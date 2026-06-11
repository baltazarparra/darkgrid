# CONCEITO — Os Invasores (Caçador & Bruxo, inimigos comuns)

> **Este documento é lei visual** para os inimigos comuns das fases. Deriva da
> lei da protagonista (`docs/CONCEITO-protagonista.md`) e do plano aprovado
> (`docs/PLANO-redesign-cacador-bruxo.md`, histórico). Gerador canônico:
> `scripts/tools/gen_inimigos.py`. Prancha: `assets/sprites/inimigos_contact_sheet.png`.
> Contrato validado por `tests/unit/test_inimigos_sprite_assets.gd`.

---

## 1. O conceito

A Caipora é a dona da mata. Caçador e Bruxo são **os invasores** — humanos que
quebraram os pactos e entraram onde não deviam. Pertencem ao mesmo mundo
(horror folclórico brasileiro, pixel art chapada, sangue real), mas leem como o
**oposto** dela:

- A Caipora é laranja vibrante, vazio preto e olhos brancos redondos.
- Os invasores são **terra, couro, breu e osso** — tons mortos, sujos de mata e
  de sangue. Nada neles rouba a primeira leitura da tela.

Ambos encaram a **esquerda**: na arena o inimigo fica à direita mirando a
Caipora (posições por orientação em `ArenaFraming` — retrato aproxima a dupla).

### Lei de escala — o adulto sobre a criança

A Caipora é PEQUENA: uma entidade do tamanho de uma criança (96px, corpo
~75px). Os invasores são humanos adultos e **se agigantam sobre ela**:
**112×112** na arena (corpo ~101–104px ≈ 1.3× ela), com **variante de mapa
56×56** re-renderizada dos mesmos vetores (a Caipora anda o mapa a ~51px
visuais). Na arena os dois usam a MESMA escala de nó (1.2) — texels
uniformes; a hierarquia vem do desenho, nunca de escala fracionária por ator.
O horror é esse: o predador é maior, e mesmo assim quem manda na mata é ela.
Guardado por assert (`test_invasores_arena_sao_maiores_que_caipora`).

## 2. Travas de marca (NUNCA quebrar — viram assert no GUT)

1. **Nenhum inimigo tem olhos brancos redondos** (`#ffffff` é assinatura
   exclusiva da Caipora). Olhos de inimigo são brasas mortiças, fendas ou sombra.
2. **Nenhum inimigo usa o laranja da juba** (`#ff4500` / `#8b2a00`) nem massa
   laranja dominante. Brasa pontual é permitida; laranja-marca, não.
3. **Verde `#00fa9a` é exclusivo do cristal/Fúria.** Zero verde frio em inimigo.
4. **Acabamento chapado:** máx. 2 tons por material, outline 1px `#1a120a`,
   sem gradiente, sem dither, sem brilho glossy.
5. **Horror físico:** sangue, troféu de caça, osso, marca ritual, pano podre.
   Nunca sanitizar, nunca fofo.
6. **Silhueta primeiro:** cada inimigo lê a 32px por UMA assinatura.

## 3. Caçador — "o predador de chapéu"

Leitura a 32px: **a aba do chapéu e o cano comprido da espingarda**.

- A aba afoga o rosto num **vazio escuro**; dentro, dois brilhos
  vermelho-sangue em fenda (`#c81e14`). Sem boca, sem expressão — o humano já
  se desumanizou.
- Poncho de terra com barra esfarrapada/serrilhada, **colar de dentes/garras**
  (troféus da mata) e respingo de sangue seco na barra.
- `idle`: espingarda atravessada apontando frente-baixo, peso pronto.
- `windup` (telegraph do tiro): **pontaria** — cano nivelado no olhar, coronha
  no ombro, reflexo frio na boca do cano, corpo cravado 1px abaixo, olhos
  estreitados (mira).

| Material | Ramp |
|----------|------|
| Chapéu/couro/botas | `#241509 → #3d2614` |
| Poncho | `#4a2a1e → #6b3d24` |
| Pele (queixo mínimo, mãos) | `#8a6a4e` |
| Aço da espingarda | `#2a2624 → #8a8a92` |
| Olhos / sangue | `#c81e14` / `#8b0000` |
| Troféus de osso | `#d8c8a8` |

## 4. Bruxo — "o feiticeiro do breu"

Leitura a 32px: **o capuz torto e o cajado de osso**.

- Capuz de pico **QUEBRADO**, tombando morto pra esquerda. Dentro, vazio com
  dois **olhos de brasa mortiça em fenda** (`#c83c14`) — formato e cor opostos
  aos da Caipora.
- Manto breu-roxo esfarrapado até o chão; **talhos rituais de sangue em
  diagonal** no peito (NUNCA uma cruz — cruz é do catequizador invasor).
- **Cajado de osso** coroado por crânio de bicho pequeno com amarrado de ossos
  pendurado; mãos de **dedos de galho** (tom de osso em sombra).
- `idle`: curvado sobre o cajado fincado, dedos enroscados na haste.
- `windup` (telegraph): cajado erguido na diagonal, **fetiche ACESO** — brasa
  ritual nas órbitas do crânio + faíscas soltas —, mão livre aberta de dedos
  esticados, manto abrindo.

| Material | Ramp |
|----------|------|
| Manto/capuz | `#1c0f28 → #3a1f52` |
| Osso (cajado/crânio/dedos) | `#9c8c70 → #d8c8a8` |
| Olhos / brasa ritual | `#c83c14` + ponto vivo `#e8742c` |
| Sangue ritual | `#8b0000` |

## 5. Pipeline técnico (premium orgânico reprodutível)

`gen_inimigos.py` — mesma receita da protagonista, parametrizada por tamanho
(grade de desenho 48 separada do canvas de saída):

1. Formas orgânicas (polígonos/elipses/`limb`) supersampled 8×.
2. Downsample por área → 112×112 (arena) / 56×56 (mapa) + threshold de alpha
   (sem halos). A variante de mapa é re-render dos MESMOS vetores — nunca
   downscale NEAREST do asset grande.
3. Snap de paleta fechada **por personagem**.
4. Outline 1px `#1a120a` em toda a silhueta.

Regras de manutenção:

- **Nunca editar `enemy_*.png` / `bruxo_*.png` à mão** — toda mudança passa por
  `gen_inimigos.py` e por este documento. `gen_chars.py` apenas delega.
- Contrato de saída: 2 poses × 2 inimigos em 112×112 + 2 variantes de mapa
  56×56, nomes estáveis (`enemy_idle/windup`, `bruxo_idle/windup`,
  `enemy_map`, `bruxo_map`) — os `.tres` não mudam.
- Rodar `make gate` antes de commit; o contrato e as travas de marca são
  cobrados por `test_inimigos_sprite_assets.gd`.

## 6. O que NUNCA muda / o que pode evoluir

**Imutável:** as travas de marca (§2); chapéu+cano como assinatura do caçador;
capuz torto+cajado de osso como assinatura do bruxo; windup com mudança de
silhueta inconfundível (o telegraph é gameplay no combate de timing); inimigos
encarando a esquerda; tom GORE/TERROR.

**Evolui livremente:** rasgo do poncho/manto, quantidade de troféus/fetiches,
poses extras (walk/strike/death — exigem mexer nos `.tres`), agressividade das
faíscas do fetiche — desde que derive das assinaturas de silhueta.

**Fora deste documento:** o Curupira já tem lei própria no mesmo pipeline
(`docs/CONCEITO-curupira.md`, gerador `gen_bosses.py`); boss
(Caçador-de-Machados) e demais minibosses (mula, boitatá, saci, jesuíta)
seguem com a arte legada de `gen_chars.py` até suas próprias sessões de
redesign neste mesmo pipeline.
