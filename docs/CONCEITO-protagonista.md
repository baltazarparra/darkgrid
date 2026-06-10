# CONCEITO — A Caipora, Protagonista ("A Guardia da Mata")

> **Este documento é lei visual.** Todo asset, animação, partícula, key art,
> ícone ou material promocional que envolva a protagonista deriva daqui.
> Gerador canônico: `scripts/tools/gen_caipora.py`. Fonte do conceito: prancha
> aprovada em 2026-06, **"Mata Hostil — Prancha de conceito de personagem:
> Caipora, guardia perigosa da mata"**: silhueta chibi com juba-capa laranja,
> rosto-vazio de olhos brancos, chifres, corpo pequeno de folhas/cipós, cajado
> com cristal verde e variante CHAMA.

---

## 1. O conceito

A Caipora não tem rosto. Sob o capuz de folhas existe apenas **vazio negro e
dois olhos brancos, redondos, que brilham** — a última coisa que o caçador vê.
A juba laranja vibrante envolve o capuz e cai sobre os ombros como uma capa
viva, quase maior que o corpo. Chifres rompem o cabelo. Na mão, um cajado reto
coroado por um **cristal verde** — o único frio numa criatura de fogo e terra.

**Proporção chibi (lei):** cabeça + juba ≈ 55–60% da altura do sprite. O corpo
é curto, menor que a juba-capa, com pés descalços simples. A fofura é isca: o
rosto-vazio é o horror.

Ela não é mascote. É a dona da mata, e a mata cobra em sangue. O clima sombrio
do jogo vem da atmosfera da cena (vinheta, grão, color-grade) — não de
dessaturar o sprite.

## 2. Assinaturas visuais (as 5 travas do design)

1. **Juba-capa laranja** — massa laranja vibrante volumosa que envolve o capuz
   por cima, dos dois lados e pelas costas, quase até o chão. É A
   silhueta: a 32px, a protagonista é "a mancha laranja de olhos brancos". No
   strike estica horizontal (velocidade); no windup eriça pra cima (ameaça);
   no recover assenta.
2. **Rosto-vazio de olhos brancos** — elipse de vazio (`VOID`) emoldurada pelo
   capuz; **dois olhos circulares brancos IGUAIS, sem halo** (`EYE_WHITE`
   puro). Sem boca, sem traços: o horror é a ausência. No windup arregalam;
   no strike viram fendas.
3. **Chifres rompendo a juba** — dois chifres curvos marrons emergindo do
   cabelo em "V", assimétricos (o do lado da juba é mais longo). As pontas
   SEMPRE ultrapassam a silhueta da juba (ganham outline e leitura).
4. **Cajado do cristal verde** — haste reta e fina coroada por cristal
   facetado esmeralda (`CR`/`CR_HL`). É a arma: ergue e carrega no windup
   (flare + raios), varre com **smear verde de 2 tons** no strike. O verde do
   cristal é o ÚNICO acento frio e a cor do crítico
   (`Constants.COLOR_PARTICLE_SPARK`).
5. **Vestes vivas + pés descalços** — túnica de folhas verde média com folhas
   avulsas no peito e na barra denteada, pés descalços marrons. **PÉS NORMAIS
   PRA FRENTE** — o pé-pra-trás é do Curupira (parente), não dela.

## 3. Paleta (fechada — fonte: `gen_caipora.py`, 2 tons por material)

| Material | Ramp |
|----------|------|
| Juba (base) | `#8b2a00 → #ff4500` (laranja vibrante da prancha) |
| Juba (CHAMA) | `#ff6808 → #ffb032` + coração `#ffefb2` |
| Pele / chifres / cajado | `#482710 → #654321` (um marrom só) |
| Folha (túnica/cipós) | `#004618 → #006400` |
| Vazio do rosto | `#000000` |
| Olhos | `#ffffff` puro (sem halo) |
| Cristal | `#00fa9a → #8affcc → #ffffff (brilho)` |
| Sangue/acento hostil | `#8b0000` |
| Contorno | `#1a120a` (1px, toda a silhueta) |

**Acabamento chapado (lei):** flat fill + contorno escuro de 1px na silhueta;
máximo 2 tons por material. Sem rim light, sem dither, sem selout graduado.
O clima sombrio vem da atmosfera/grading da cena, não do sprite. O verde do
cristal segue sendo o único acento frio.

## 4. Linguagem corporal por frame

| Frame | Corpo | Juba | Cajado |
|-------|-------|------|--------|
| `idle` | Peso pronto | Coroa o capuz e cai até o chão | Fincado vertical, cristal acima dos chifres |
| `walk_1/2` | Passada em tesoura | Bounce com a fase | Carregado, inclinado ~10° |
| `windup` | Agachada, mola comprimida | Eriçada pra cima | Erguido na diagonal, **cristal carregando** (flare + raios), olhos arregalados |
| `strike` | Afundo, lean 5px | Esticada horizontal atrás | Varrido à frente: **smear verde CR→CR_HL**, olhos em fenda |
| `recover` | Assentando o peso | Dobrando de volta | Descendo pra fincar |

## 5. Pipeline técnico (o "premium" reprodutível)

`gen_caipora.py`, determinístico, stdlib + Pillow:

1. **Desenho vetorial supersampled 8×** (768×768): membros capsulares, juba por
   lóbulos ao longo de spline + tufos afilados, polígonos orgânicos.
2. **Downsample por área → 96×96** + threshold de alpha (sem halos).
3. **Snap de paleta**: cada pixel cai na cor mais próxima (paleta fechada).
4. **Outline 1px**: todo pixel opaco que toca transparência vira `OUTLINE` —
   contorno escuro contínuo na silhueta inteira, como na referência.

Regras de manutenção:
- **Nunca editar os PNGs `player_*` à mão** — toda mudança visual da
  protagonista passa por `gen_caipora.py` e por este documento.
- **`gen_chars.py` NUNCA toca os `player_*`** — protagonista só sai do gerador
  canônico.
- Contrato de saída: 6 poses × 2 variantes, 96×96, validado por
  `tests/unit/test_caipora_sprite_assets.gd`.

## 6. O que NUNCA muda / o que pode evoluir

**Imutável:** rosto-vazio com dois olhos brancos circulares iguais; juba
laranja como silhueta dominante envolvendo o capuz e fluindo PRA TRÁS;
proporção chibi (cabeça + juba ≈ 55–60% da altura); chifres rompendo a juba;
cristal verde como único acento frio, cor do crítico e do flash de janela
perfeita; acabamento flat + outline 1px; pés normais pra frente; postura de
predadora; tom GORE/TERROR — a mata é hostil, a Caipora é perigosa, nunca
suavizar.

**Evolui livremente:** densidade de folhas (upgrades podem vesti-la mais),
intensidade da juba e do cristal, partículas, key art em resolução maior —
desde que derive das 5 assinaturas.

**Fúria (T1–T6) manifesta no cristal:** sem sprite de arma separado — o cajado
é parte do corpo. `furia_visual.gd` ancora partículas no cristal: glow verde
que escala com o tier + identidade de lore por tier (fumaça, aura dourada,
breu, osso, carne viva). A CHAMA soma a chama viva ao conjunto.

**CHAMA (meta-progressão) = "juba em brasa":** a variante `player_*_chama.png`
(`caipora(..., chama=True)`) acende a juba — ramp quente (`#ff6808 → #ffb032`)
no lugar do laranja base, coração claro `F_CORE` na coroa e brasas orbitando.
Mesma geometria, outro estado: a fúria antiga da mata acordou. Selecionada em
runtime por `CaiporaSkin` (exploração, arena e TitleWalker).

> Direções anteriores ("Predadora-Rainha da Mata", "Caipora Brasa" /
> `docs/PLANO-redesign-caipora-pop-dark.md`) ficam como histórico; em qualquer
> conflito, vale este documento.
