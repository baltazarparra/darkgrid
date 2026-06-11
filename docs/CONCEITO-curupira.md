# CONCEITO — Curupira, Boss da Fase 3 ("O Parente Mais Antigo")

> **Este documento é lei visual** para o Curupira. Deriva da lei da
> protagonista (`docs/CONCEITO-protagonista.md`) e do plano aprovado
> (`docs/PLANO-redesign-curupira.md`, histórico). Gerador canônico:
> `scripts/tools/gen_bosses.py`. Prancha: `assets/sprites/curupira_contact_sheet.png`.
> Contrato validado por `tests/unit/test_curupira_sprite_assets.gd`.

---

## 1. O conceito

O Curupira é **parente da Caipora** — o protetor mais antigo da mata, e o
pé-pra-trás é dele (lei do projeto: nunca dela). Mesma espécie de entidade,
mas mais velho, **indiferente e letal**. Ele lê como **eco** dela, nunca cópia:

- A Caipora é **laranja vibrante + vazio preto + olhos brancos redondos** —
  predadora pronta, eriçada.
- O Curupira é **verde profundo + vazio de breu + fendas verde-folha** — o
  protetor antigo que nem se dá ao trabalho de se eriçar. A crista
  vermelho-sangue é fogo que já queimou e apagou (**"sem fogo"** é lei dele;
  chama viva pertence a Saci/Mula).

O parentesco está na **linguagem** (massa serrilhada envolvendo a cabeça,
rosto vazio sem expressão humana, proporção de criança da mata); a diferença
está na paleta, na postura e nos PÉS.

Leitura a 32px: **os pés ao contrário + a crista serrilhada vermelho-sangue**.

### Lei de escala — criança ao lado de criança

A Caipora é PEQUENA (96px, corpo ~79px) e o Curupira é do MESMO porte:
**128×128** na arena com corpo ~82px (0.9–1.1× ela, guardado por
`test_curupira_sprite_assets.gd` e `test_boss_scale_proportions.gd`), escala
de nó **1.2** (texels uniformes com o mundo — KI-012) e pés na linha de chão
dela. **Variante de mapa 48×48** re-renderizada dos mesmos vetores
(`curupira_map.png`, figura ~45px ≈ a Caipora a ~42px no mapa). O horror é
esse: duas crianças se encarando, e uma delas é mais antiga que o medo.

## 2. Travas de marca (NUNCA quebrar — viram assert no GUT)

1. **Zero olhos brancos redondos** (`#ffffff` é assinatura exclusiva da
   Caipora). Os olhos do Curupira são **fendas** verde-folha, semicerradas.
2. **Zero laranja da juba** (`#ff4500` / `#8b2a00`). A crista é
   vermelho-sangue ESCURO (`#a8281e`), nunca laranja vivo.
3. **Zero verde `#00fa9a`** (exclusivo do cristal/Fúria). O verde dele é
   verde-FOLHA (`#2fa838`, matiz amarelado), casando com
   `COLOR_TELEGRAPH_CURUPIRA`/`COLOR_AURA_CURUPIRA`/`COLOR_DIALOGUE_CURUPIRA`.
4. **Acabamento chapado:** máx. 2 tons por material, outline 1px `#1a120a`,
   sem gradiente, sem dither, sem brilho glossy.
5. **Horror físico:** sangue seco, cicatriz de machado, garra, pegada
   invertida. Nunca sorriso, nunca dentes, nunca mascote.
6. **Silhueta primeiro:** a 32px ele é mancha verde + crista + pés invertidos.

## 3. As 5 assinaturas

1. **PÉS AO CONTRÁRIO** — a assinatura folclórica. Dedos com garras de osso
   apontando para TRÁS (direita — ele encara a esquerda), calcanhares para a
   frente, duas lâminas horizontais que rompem a silhueta. Sob os pés,
   **pegadas invertidas de sangue** no chão "errado" — eco do padrão RASTRO
   (←→←→) que confunde a leitura do jogador.
2. **Crista serrilhada vermelho-sangue** (`#5a100a → #a8281e`) — picos
   varridos para trás, fogo morto. Eco da juba dela na LINGUAGEM, não na cor.
3. **Vazio de breu com fendas verde-folha** (`#2fa838` + ponto `#66d44e`) —
   sem boca, sem expressão; o ponto vivo pende pra esquerda: o olhar já está
   na Caipora. No windup as fendas ESCANCARAM (mas seguem fendas).
4. **Corpo de mata** (`#14381c → #2a6b34`) — tronco curto, braços longos
   caídos com garras penduradas, **talhos de machado cicatrizados** no peito
   (os invasores tentaram — e estão mortos).
5. **Postura indiferente** — ereto, peso assentado, cabeça levemente baixa.
   Ele NÃO se agacha em bote como ela… até o windup.

## 4. Poses (contrato atual, 2 frames)

- `idle` (loop) — a indiferença: ereto, fendas semicerradas, pés invertidos
  plantados, pegadas de sangue na direção errada.
- `windup` (one-shot) — **a indiferença QUEBRA, e isso é gameplay** (telegraph
  do combate de timing): agachamento de mola com joelhos dobrados, crista
  eriçada em picos esticados e abertos (+40–50%), fendas escancaradas, garras
  em leque, cabeça baixa avançando. Pés cravados na MESMA linha de chão do
  idle (sem pop de pose). Os telegraphs por tween (`curupira.gd`: pulso verde
  do RASTRO, double-jump do ASSOBIO) somam por cima do frame; o `ActorAnimator`
  toca a anim sozinho (`arena_manager.gd` chama `play_pose(&"windup")`).

## 5. Paleta (fechada — fonte: `gen_bosses.py`, 2 tons por material)

| Material | Ramp |
|----------|------|
| Pele/corpo | `#14381c → #2a6b34` (verde profundo, família da aura) |
| Crista | `#5a100a → #a8281e` (vermelho-sangue, fogo morto) |
| Vazio do rosto | `#0a0d08` |
| Olhos (fendas) | `#2fa838` + ponto vivo `#66d44e` (verde-FOLHA) |
| Garras (pés/mãos) | osso sujo `#9c8c70` |
| Sangue (pegadas/talhos) | `#8b0000` |
| Contorno | `#1a120a` (1px, toda a silhueta) |

## 6. Pipeline técnico (premium orgânico reprodutível)

`gen_bosses.py` — reusa o `Painter` de `gen_inimigos.py` (formas orgânicas
supersampled 8× → downsample por área → snap de paleta fechada → outline 1px),
com `grid`/`shift` para re-renderizar os MESMOS vetores na moldura do mapa.

Regras de manutenção:

- **Nunca editar `curupira_*.png` à mão** — toda mudança passa por
  `gen_bosses.py` e por este documento. `gen_chars.py` apenas delega.
- Contrato de saída: `curupira_idle/windup.png` 128×128 + `curupira_map.png`
  48×48, nomes estáveis — `curupira_sprite_frames.tres` (idle loop + windup
  one-shot) e os consumidores não mudam.
- Cuidado com o snap: osso encostado na pele verde pode cair no verde-folha
  dos olhos (assinatura). Garras usam osso ESCURO (`#9c8c70`) por isso;
  `strays` de verde-folha fora dos olhos = bug.
- Rodar `make gate` antes de commit; contrato e travas cobrados por
  `test_curupira_sprite_assets.gd` + `test_boss_scale_proportions.gd`.

## 7. O que NUNCA muda / o que pode evoluir

**Imutável:** as travas de marca (§2); pés ao contrário + crista como
assinatura de silhueta; rosto-vazio SEM expressão (o sorriso do legado morreu
com ele); windup com mudança de silhueta inconfundível (telegraph é gameplay
no combate de timing); porte de criança da mata (≈ Caipora); "sem fogo" —
o vermelho dele nunca vira chama; encarar a esquerda; tom GORE/TERROR.

**Evolui livremente:** agressividade da serrilha, quantidade de talhos e
pegadas, poses extras (walk/strike/death — exigem mexer no `.tres`), VFX da
aura — desde que derive das 5 assinaturas.

**Fora deste documento:** os demais chefes (Mula, Boitatá, Saci, Jesuíta,
Caçador-de-Machados) seguem com a arte legada de `gen_chars.py` até suas
próprias sessões de redesign em `gen_bosses.py`, uma por sessão (KI-012).
