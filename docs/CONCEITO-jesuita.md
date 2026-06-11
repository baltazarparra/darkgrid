# CONCEITO — Jesuíta Bandeirante Catequizador, Boss Final ("O Padre-Guerreiro")

> **Este documento é lei visual** para o Jesuíta. Deriva da lei da protagonista
> (`docs/CONCEITO-protagonista.md`) e da lei dos invasores
> (`docs/CONCEITO-inimigos.md`). Gerador canônico: `scripts/tools/gen_bosses.py`.
> Prancha: `assets/sprites/jesuita_contact_sheet.png`. Contrato validado por
> `tests/unit/test_jesuita_sprite_assets.gd`.

---

## 1. O conceito

O Jesuíta é **o invasor final**: o padre-guerreiro fanático que "converteu" os
encantados com espelhos e água benta (a lore do diálogo permanece) e que agora
**luta com as próprias mãos** — uma baioneta consagrada em cada punho. É o
arquétipo do padre-combatente traduzido para a lei dos invasores:

- A Caipora é **laranja vibrante + vazio preto + olhos brancos redondos**.
- O Jesuíta é **uma TORRE de batina-breu + cruz de ouro + fendas douradas** —
  o sagrado colonial como arma de invasão.

Como todo invasor, ele se desumanizou: o rosto esquálido afunda na sombra das
órbitas e o que sobra são **frestas douradas de zelote** — nunca olhos
redondos, nunca óculos, nunca expressão humana.

Leitura a 32px: **a torre de batina-breu com a cruz de ouro acesa + as
baionetas cruciformes gêmeas**.

> **Nota de IP:** o Jesuíta evoca o ARQUÉTIPO do padre-guerreiro de lâminas
> gêmeas, mas é design autoral dentro da lei visual do caipora. NUNCA
> reproduzir trade dress de personagens de terceiros (rosto, cicatriz, óculos,
> uniforme ou iconografia específica de obras alheias).

### Lei de escala — o adulto que se agiganta

A Caipora é PEQUENA (96px, corpo ~79px). O Jesuíta é humano adulto e o chefe
final: **128×128** na arena com corpo ~103px (>1.25× ela; 0.85–1.15× o caçador
comum — guardado por `test_jesuita_sprite_assets.gd` e
`test_boss_scale_proportions.gd`), escala de nó **1.2** (texels uniformes —
KI-012) e pés na linha de chão dela. **Variante de mapa 48×48** re-renderizada
dos mesmos vetores (`jesuita_map.png`, figura ~45px — o adulto preenche o tile
que a criança-Curupira ocupa com folga). Antes desta sessão o boss final
aparecia no mapa da Fase 5 com o sprite do caçador-de-machados
(`map_enemy.gd` sem case `"jesuita"`) — corrigido.

## 2. Travas de marca (NUNCA quebrar — viram assert no GUT)

1. **Zero olhos brancos redondos** (`#ffffff` é da Caipora). As fendas dele
   são **douradas**, estreitas, fundas — o zelote olha por frestas.
2. **Zero laranja da juba** (`#ff4500` / `#8b2a00`).
3. **Zero verde `#00fa9a`** (exclusivo do cristal/Fúria).
4. **Acabamento chapado:** máx. 2 tons por material, outline 1px `#1a120a`,
   sem gradiente, sem dither, sem brilho glossy.
5. **A CRUZ é dele** (lei dos invasores: cruz é do catequizador — o bruxo
   nunca usa cruz). Ouro litúrgico no peito e nas guardas das lâminas.
6. **Horror físico:** barra da batina ensanguentada, lâminas molhadas de
   sangue e água benta, papéis de oração marcados a sangue.
7. **Silhueta primeiro:** torre de breu + cruz + lâminas gêmeas a 32px.

## 3. As 5 assinaturas do Jesuíta

1. **A torre de batina-breu** — a maior mancha escura do jogo: batina dos
   ombros ao chão, barra esfarrapada e ensanguentada, gibão de couro nos
   ombros (o sagrado veste couro de guerra), gola erguida emoldurando a
   cabeça.
2. **Baionetas consagradas GÊMEAS** — uma em cada punho: folha reta e longa,
   **guarda cruciforme de ouro larga** + punho curto e pomo — cada arma lê
   como uma cruz de aço. Molhadas de água benta (`HOLY`) e de sangue.
3. **Cruz de ouro litúrgico no peito** — o ouro casa com o telegraph
   (`COLOR_TELEGRAPH_JESUITA`), a aura de incenso e a voz dourada do diálogo.
4. **Fendas douradas de zelote** — rosto esquálido com tonsura, mandíbula
   encovada, faixa de sombra nas órbitas e duas frestas `EYE_GOLD` com ponto
   vivo. Colarinho clerical mínimo.
5. **Papéis de oração** — tiras de papel marcadas a sangue amarradas nas
   guardas, tremulando quando a conversão começa.

## 4. Poses

- `idle` — a torre parada: lâminas baixas com as pontas pro chão, fendas
  semicerradas. Quem já converteu uma floresta inteira não levanta guarda.
- `windup` (telegraph, gameplay) — **o X de aço abre**: a lâmina da frente
  NIVELA na Caipora (mesma linguagem da pontaria do caçador), a outra ergue
  atrás; fendas escancaram, papéis tremulam, a barra crava no chão. Silhueta
  inconfundivelmente mais larga (assert no GUT). Os telegraphs por tween
  (cadeia herdada do Saci + branco do Boitatá em `jesuita.gd`) somam por cima.

## 5. Paleta (fechada — fonte: `gen_bosses.py`, 2 tons por material)

| Material | Ramp |
|----------|------|
| Batina/gola | `#100e14 → #262230` (breu azulado — nunca o roxo do bruxo) |
| Gibão (ombros) | `#241509 → #3d2614` (couro dos invasores) |
| Pele esquálida | `#665c4e → #968a78` |
| Fendas de zelote | `#ffc45a` + ponto `#fff4cd` (nunca branco puro) |
| Ouro litúrgico (cruz/guardas/pomos) | `#967832 → #d4b462` |
| Aço das baionetas | `#2a2624 → #8a8a92` |
| Água benta | `#c8deec` (família do `COLOR_BAPTISM_DROP`) |
| Papel de oração | `#d8c8a8` |
| Sangue | `#8b0000` |
| Colarinho | `#dededa` |
| Contorno | `#1a120a` (1px, toda a silhueta) |

## 6. Pipeline técnico

Mesma receita premium de `gen_bosses.py` (Curupira): vetores orgânicos
supersampled 8× → downsample por área → snap de paleta fechada → outline 1px.
Arena 128×128 + mapa 48×48 re-renderizado dos MESMOS vetores
(`JESUITA_MAP_GRID`/`JESUITA_MAP_SHIFT`) — nunca downscale NEAREST.

Regras de manutenção:
- **Nunca editar `jesuita_*.png` à mão** — toda mudança passa por
  `gen_bosses.py` e por este documento. `gen_chars.py` apenas delega.
- Contrato de saída: `jesuita_idle/windup` 128×128 + `jesuita_map` 48×48;
  `jesuita_sprite_frames.tres` com `idle` (loop) e `windup` (one-shot).
- Rodar `make gate` antes de commit.

## 7. O que NUNCA muda / o que pode evoluir

**Imutável:** as travas de marca (§2); torre de batina + cruz + baionetas
gêmeas como assinatura; fendas douradas (nunca redondas, nunca óculos);
windup com mudança de silhueta inconfundível (telegraph é gameplay); encarar
a esquerda; tom GORE/TERROR; design autoral (nota de IP do §1).

**Evolui livremente:** rasgo da barra, quantidade de papéis de oração,
respingos, poses extras (exigem mexer no `.tres`) — desde que derive das
assinaturas.
