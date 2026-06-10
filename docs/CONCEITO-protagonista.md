# CONCEITO — A Caipora, Protagonista ("A Guardia da Mata")

> **Este documento é lei visual.** Todo asset, animação, partícula, key art,
> ícone ou material promocional que envolva a protagonista deriva daqui.
> Gerador canônico: `scripts/tools/gen_caipora.py`. Fonte do conceito: arte de
> referência aprovada em 2026-06 (criatura encapuzada de juba vermelha, rosto
> vazio de olhos brancos, chifres, manto de folhas e cajado de cristal verde).

---

## 1. O conceito

A Caipora não tem rosto. Sob o capuz de folhas existe apenas **vazio negro e
dois olhos brancos, redondos, que brilham** — a última coisa que o caçador vê.
A juba vermelho-sangue cai sobre os ombros como uma capa viva. Chifres escuros
rompem o capuz. Na mão, um cajado de madeira retorcida coroado por um **cristal
verde** que pinga luz — o único frio numa criatura de sangue e terra.

Ela não é mascote. É a dona da mata, e a mata cobra em sangue.

## 2. Assinaturas visuais (as 5 travas do design)

1. **Juba-capa de sangue** — massa vermelha volumosa que envolve o capuz dos
   dois lados e flui pelas costas quase até o chão. É A silhueta: a 32px, a
   protagonista é "a mancha vermelha de olhos brancos". No strike estica
   horizontal (velocidade); no windup eriça pra cima (ameaça); no recover
   assenta.
2. **Rosto-vazio de olhos brancos** — elipse de vazio (`VOID`) emoldurada pelo
   capuz; dois olhos circulares brancos com halo esverdeado (`EYE_GLOW` →
   `EYE_WHITE`). O olho da frente é maior (encara a presa). Sem boca, sem
   traços: o horror é a ausência. No windup arregalam; no strike viram fendas.
3. **Chifres do capuz de folhas** — dois chifres curvos de madeira escura
   rompendo a linha do capuz, assimétricos (o da frente é mais longo). As
   pontas SEMPRE ultrapassam a silhueta da juba (ganham outline e leitura).
4. **Cajado do cristal verde** — madeira retorcida com nós, coroada por cristal
   facetado esmeralda (`CR`/`CR_HL`) que goteja faíscas. É a arma: ergue e
   carrega no windup (flare + raios), varre com **smear verde de 3 tons**
   no strike, pinga no recover. O verde do cristal é o ÚNICO acento frio e a
   cor do crítico (`Constants.COLOR_PARTICLE_SPARK`).
5. **Vestes vivas + pés descalços** — poncho de folhas escuras em 3 fileiras
   recortadas, bolsa de couro no quadril (ela colhe o que a mata dá), pés
   descalços marrons. **PÉS NORMAIS PRA FRENTE** — o pé-pra-trás é do Curupira
   (parente), não dela.

## 3. Paleta (fechada — fonte: `gen_caipora.py`, 20 cores)

| Material | Ramp |
|----------|------|
| Juba (base) | `#440b10 → #8e1c12 → #ce3208` (fosca, sangue seco) |
| Juba (CHAMA) | `#440b10 → #ce3208 → #ff6808 → #ffb032` + coração `#ffefb2` |
| Pele | `#46281c → #74462c → #a86c40` (rim) |
| Folha | `#0a130e → #162717 → #304e26 → #5c7a38` (rim) |
| Madeira (cajado/chifre/bolsa) | `#1f1210 → #41261d` (+ `#46281c` como realce de couro) |
| Vazio do rosto | `#0a0712` |
| Olhos | halo `#c8e8d4` + núcleo `#ffffff` |
| Cristal | `#0a130e (faceta escura) → #1da75c → #8af0b0 → #ffffff (brilho)` |

**Regra da luz dupla:** a criatura carrega duas luzes próprias — a quente da
juba (rim light no topo/dorso, mais forte na CHAMA) e a fria do cristal (rim
verde em dither, lado do cajado). Nenhuma outra cor saturada entra no sprite.

## 4. Linguagem corporal por frame

| Frame | Corpo | Juba | Cajado |
|-------|-------|------|--------|
| `idle` | Inclinada 2px, peso pronto | Arco de cometa até o chão | Fincado vertical, cristal na altura dos chifres |
| `walk_1/2` | Passada em tesoura | Bounce com a fase | Carregado, inclinado ~10° |
| `windup` | Agachada, mola comprimida | Eriçada pra cima | Erguido na diagonal, **cristal carregando** (flare + raios), olhos arregalados |
| `strike` | Afundo, lean 7px | Esticada horizontal atrás | Varrido à frente: **smear verde CR→CR_HL→branco**, olhos em fenda |
| `recover` | Assentando o peso | Dobrando de volta | Descendo pra fincar, cristal **pingando** 3 gotas |

## 5. Pipeline técnico (o "premium" reprodutível)

`gen_caipora.py`, determinístico, stdlib + Pillow:

1. **Desenho vetorial supersampled 8×** (768×768): membros capsulares, juba por
   lóbulos ao longo de spline + mechas afiladas, polígonos orgânicos.
2. **Downsample por área → 96×96** + threshold de alpha (sem halos).
3. **Snap de paleta**: cada pixel cai na cor mais próxima (paleta fechada).
4. **Selout**: borda externa escurecida (1px) — coesão contra qualquer fundo.
   Materiais emissivos (fogo, olhos, cristal) ficam de fora.
5. **Rim light duplo procedural**: quente (juba, bordas superiores + dorsais em
   dither) e frio (cristal, bordas do lado do cajado em dither). O rim vence o
   outline na borda iluminada.
6. **Dither de bandas na juba**: xadrez na fronteira entre tons do ramp —
   cabelo orgânico, não listras (na CHAMA o ramp inteiro de fogo participa).

Regras de manutenção:
- **Nunca editar os PNGs `player_*` à mão** — toda mudança visual da
  protagonista passa por `gen_caipora.py` e por este documento.
- **`gen_chars.py` NUNCA toca os `player_*`** — protagonista só sai do gerador
  canônico.
- Contrato de saída: 6 poses × 2 variantes, 96×96, validado por
  `tests/unit/test_caipora_sprite_assets.gd`.

## 6. O que NUNCA muda / o que pode evoluir

**Imutável:** rosto-vazio com olhos brancos circulares; juba vermelha como
silhueta dominante fluindo PRA TRÁS; chifres rompendo o capuz; cristal verde
como único acento frio e cor do crítico; pés normais pra frente; postura de
predadora; tom GORE/TERROR — a mata é hostil, a Caipora é perigosa, nunca
suavizar.

**Evolui livremente:** densidade de folhas (upgrades podem vesti-la mais),
intensidade da juba e do cristal, partículas, key art em resolução maior —
desde que derive das 5 assinaturas.

**CHAMA (meta-progressão) = "juba em brasa":** a variante `player_*_chama.png`
(`caipora(..., chama=True)`) acende a juba — ramp de fogo no lugar do sangue
seco, coração `F_CORE`, brasas orbitando e rim light térmico mais largo. Mesma
geometria, outro estado: a fúria antiga da mata acordou. Selecionada em runtime
por `CaiporaSkin` (exploração, arena e TitleWalker).

> Direções anteriores ("Predadora-Rainha da Mata", "Caipora Brasa" /
> `docs/PLANO-redesign-caipora-pop-dark.md`) ficam como histórico; em qualquer
> conflito, vale este documento.
