# PRD — Economia & Aprimoramentos v2

> Redefinição da economia (fragmentos) e da escala dos aprimoramentos (ervas do
> cachimbo) para tornar **caipora** um roguelike consistentemente **difícil**.
> Substitui os valores ad-hoc das Fases 3/4/8/9 por um sistema coerente, com
> fonte numérica única e curva de custo deliberada.

---

## 1. Diagnóstico do sistema anterior

Três eixos de poder se acumulavam e empurravam a run para **mais fácil** quanto
mais longe a Caipora ia — o oposto da intenção de horror hostil:

1. **Snowball de HP in-run.** Cada kill comum dava `+1 HP máx.` **e** curava 1.
   ~5 kills/fase = +5 HP/fase: a pressão de morte *caía* ao longo da run.
2. **Teto de dano alto.** A trilha Fúria levava o dano de `1` a `8` (`10` com a
   CHAMA). Contra um inimigo comum de `5 HP`, o TTK colapsava: equipado, matava
   em 1 golpe — o late-game virava trivial.
3. **Cura achatada com custo crescente.** `+2 HP` fixo por erva, custo `6/9/12/15`
   — retorno estritamente decrescente, curva pouco satisfatória.

Incoerências adicionais: fragmentos **fracionários** (`1.5/2.0/2.5`) feios na HUD;
`DAMAGE_CRIT_MULTIPLIER = 1.0` (a promessa de "crítico 2×–3×" nunca acontecia — o
"crítico" é, na prática, o **ataque duplo** da bolha); HP de inimigo fixo que não
acompanhava o dano do jogador; e o label do efeito podia desincronizar da
matemática real (origem do KI-006).

---

## 2. Princípios de design (economia de roguelike, jogo difícil)

1. **Escassez é a alavanca da dificuldade.** Currency apertada força escolhas
   entre as trilhas; não dá para comprar tudo cedo.
2. **Meta-progressão dá *capacidade*, não invencibilidade.** Inspirado em Hades
   (Espelho) e Slay the Spire: você fica capaz, mas o desafio permanece.
3. **Custo marginal crescente, retorno decrescente-mas-relevante.** Cada tier
   custa mais; a última erva é uma meta de longo prazo, não compra-relâmpago.
4. **Banda de TTK estável.** HP de inimigo escala com o dano *esperado* da fase,
   para que todo combate continue levando ~3 trocas (comum) e ~5–7 (boss),
   independentemente do quão equipada a Caipora está.
5. **Números inteiros e legíveis. Fonte numérica única.** Os campos `dmg`/`hp`
   das definições são a verdade; o texto do efeito é **derivado** deles (mata a
   classe de bug do KI-006).

---

## 3. Trilha Fúria (dano) — teto 5 (6 com a CHAMA)

Cada erva soma **+1 de dano** (linear, previsível). Dano base da Caipora = `1`.

| key       | nome           | +dano | total | custo | fase |
|-----------|----------------|:-----:|:-----:|:-----:|:----:|
| `forca`   | Folha-Brasa    |  +1   |   2   |   5   |  1   |
| `forca_2` | Cinza-Viva     |  +1   |   3   |  10   |  2   |
| `forca_3` | Raiz-de-Ira    |  +1   |   4   |  16   |  3   |
| `forca_4` | Breu-Ancestral |  +1   |   5   |  24   |  4   |
| **CHAMA** | (elemento fogo)|  +1   |   6   |  drop |  3+  |

- Total Fúria: **+4** → dano `5`. Com a CHAMA, `6`. Custo da trilha: **55**.
- `forca_3` continua sendo a "espada" que **destrava a CHAMA** (gate inalterado).
- `CHAMA_DAMAGE_BONUS`: `2 → 1` (respeita o teto de 6).

## 4. Trilha Cura (HP) — base 2, teto meta 14

Incrementos **crescentes** (não mais `+2` fixo), custo crescente.

| key       | nome             | +HP | total | custo | fase |
|-----------|------------------|:---:|:-----:|:-----:|:----:|
| `saude`   | Seiva-Mãe        | +2  |   4   |   6   |  1   |
| `saude_2` | Casca-Boa        | +3  |   7   |  12   |  2   |
| `saude_3` | Folha-de-Sangue  | +3  |  10   |  20   |  3   |
| `saude_4` | Coração-de-Cerne | +4  |  14   |  30   |  4   |

- Total Cura: **+12** → HP máx. `14`. Custo da trilha: **68**.

Maximizar as duas trilhas custa **123** fragmentos — meta de longo prazo
deliberada (≈ 2 clears completos), não algo alcançável nas primeiras runs.

## 5. Snowball in-run — meio HP por kill

Decisão de design: manter um crescimento in-run, mas **pela metade**.

- **Kill comum:** `+0,5 HP máx.` e cura `1`. Como os corações são inteiros
  (`HealthIcons` desenha ícones discretos), o meio-HP **acumula em
  `GameState.caipora_max_hp` (float)** e materializa `+1 coração a cada 2 kills`.
- **Kill de boss:** `+1 HP máx.` (marco) e cura `2`.

A componente de combate (`HealthComponent.max_health`, int) é sempre
`floori(GameState.caipora_max_hp)`. O meio-HP acumulado persiste **dentro da run**
(carrega entre fases) e zera no início de cada run (`start_run`).

## 6. Currency (fragmentos) — inteiros, escala por profundidade

| Fonte        | P1 | P2 | P3 | P4 |
|--------------|:--:|:--:|:--:|:--:|
| Kill comum   | 1  | 2  | 3  | 4  |
| **Boss** (novo) | 3  | 5  | 8  | 12 |

- Acaba com os fragmentos fracionários. A função `add_fragments(float)` continua
  aceitando float (compatibilidade/testes), mas as **recompensas** são inteiras.
- O **boss bounty** é novo (antes boss dava 0 fragmentos) e financia as ervas
  caras do late-game, recompensando quem empurra mais fundo.
- A CHAMA continua substituindo o fragmento da morte em que é sorteada.

Renda por clear completo: P1 ≈ 8, P2 ≈ 15, P3 ≈ 23, P4 ≈ 32 → ~**78/run**.

## 7. HP de inimigos — escala para segurar o TTK

Dano *esperado* ao entrar na fase (gates da trilha Fúria): P1 `1–2`, P2 `2–3`,
P3 `3–4`, P4 `4–5` (+CHAMA). Com ataque-duplo (30%) ≈ `×1.3`/turno. HP alvo para
~3 trocas (comum) e ~5–7 (boss):

| Fase | Comum (antes → agora) | Boss (antes → agora) |
|------|:---------------------:|:--------------------:|
| P1   | criatura `5 → 6`      | boss `10 → 12`       |
| P2   | caçador `9 → 10`      | boitatá `15 → 22`    |
| P3   | assombração `12 → 14` | curupira `20 → 30`   |
| P4   | assombração `12 → 14`*| saci `20 → 36`       |

\* P3 e P4 compartilham `assombracao.tscn`; a dificuldade extra da P4 vem do boss
(36), do fogo, da redução de janela de timing (`0.30`) e do `+1` de dano inimigo.

`max_health` das cenas e as constantes de HP (`*_MAX_HEALTH`) andam juntos —
ambos são editados e os testes de padrão afirmam a igualdade.

## 8. Fora de escopo (decisões deliberadas)

- **Crítico multiplicador (2×–3×).** Mantido em `1.0`. O burst por skill já vem do
  **ataque duplo** (bolha); subir o multiplicador estouraria o teto de dano de 6.
  Registrado aqui como escolha consciente, não esquecimento.
- Novos inimigos/scenes por fase para diferenciar comum P3 vs P4.

## 9. Impacto no código

- `scripts/utils/constants.gd`: HP de inimigos; novas constantes de recompensa
  (`COMMON_KILL_HP_GROWTH`, `BOSS_KILL_HP_GROWTH`, heals, fragmentos por fase,
  boss bounty).
- `scripts/core/meta_progression.gd`: `UPGRADE_DEFS` com campos numéricos
  `dmg`/`hp` (fonte única) + custos novos; `get_damage_bonus`/`get_health_bonus`
  data-driven; `effect` derivado; `CHAMA_DAMAGE_BONUS = 1`.
- `scripts/arena/arena_manager.gd`: meio-HP/kill comum + marco de boss;
  recompensas inteiras por fase; boss bounty; sync `max_health` via `floori`.
- `scripts/core/game_state.gd`: nada estrutural (caipora_max_hp já é float).
- `scenes/arena/*.tscn`: `max_health` por inimigo.
- `tests/unit/*`: literais de custo/HP/dano atualizados + novo teste de
  consistência efeito↔matemática.
