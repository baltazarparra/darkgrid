# CONCEITO — A Mula sem Cabeça (Boss da Fase 1)

> **Este documento é lei visual** para o primeiro chefe do jogo. Deriva da
> protagonista (`docs/CONCEITO-protagonista.md`) e da skill de identidade visual
> (`.agents/skills/visual-identity/SKILL.md`).
>
> Gerador canônico: `scripts/tools/gen_mula.py`.  
> Prancha: `assets/sprites/mula_contact_sheet.png`.  
> Contrato validado por `tests/unit/test_mula_sprite_assets.gd` e
> `tests/unit/test_boss_scale_proportions.gd`.

---

## 1. O conceito

A Mula sem Cabeça é a **primeira impressão** do jogador sobre os chefes de
*caipora*. Ela é o pesadelo da estrada de terra: uma égua negra amaldiçoada,
sem cabeça, cujo pescoço termina num **toco cru de onde jorra uma coluna de
fogo** que serve como "cabeça". As ferraduras de ferro reluzem a cada
passada, e o arreio vermelho-sangue ainda pinga da última cavalgada.

- **Horror físico:** carne viva no toco, sangue seco no arreio, pelo empapado
  de fuligem e sangue.
- **Folclore brasileiro:** a Mula do folclore é castigo e fogo — nunca uma
  fera genérica de fantasia ocidental.
- **Hostilidade:** encara a Caipora (lado esquerdo, como todos os inimigos) e
  a silhueta deve ler ameaça antes de qualquer detalhe.

## 2. Lei de escala — a montaria sobre todos

A Caipora é uma criança da mata. A Mula é uma **montaria amaldiçoada** e deve
agigantar-se sobre todos os outros atores:

```
Saci (menino de uma perna) < Caipora ≈ Curupira (criança da mata)
< humanos adultos (Jesuíta, caçador-de-machados ≈ caçador/bruxo comuns)
< Boitatá (serpente gigante — massa horizontal enrolada)
< Mula sem Cabeça (montaria + coluna de fogo, agiganta sobre todos)
```

- Canvas: **192×192** (4× a área do sprite legado).
- Escala de cena: aproximadamente **0.9** para manter altura visual ~168 px,
  preservando a hierarquia sem esticar pixels.
- Os pés assentam na mesma linha de chão da Caipora (`offset.y ≈ -77`).

## 3. Assinaturas visuais (leitura a 32 px)

1. **Toco decepado + coluna de fogo** — sem cabeça. O fogo é a "cabeça";
   leitura imediata de silhueta. A coluna é viva, composta de múltiplas línguas
   entrelaçadas com bordas irregulares, brasas orbitando e brasa caindo do toco.
2. **Ferraduras de ferro reluzentes** — flash prateado nos cascos, visível
   mesmo em escala reduzida.
3. **Arreio amaldiçoado** — sela escura com debrum vermelho-sangue; traça o
   flanco e desce como barrigueira.
4. **Pelo negro-terra com bordas serrilhadas** — massa escura, quase uma sombra
   com músculo; o contorno é agressivamente irregular, inspirado na juba
   serrilhada da Caipora. Crina, cauda e bordas do corpo terminam em "dentes"
   de pelo negro.
5. **Rim light de fogo** — luz laranja do toco lambendo o pescoço, ombros e
   flanco, conectando visualmente a coluna de fogo ao corpo escuro.
6. **Pose de montaria prestes a galopar** — não estática; peso recolhido,
   peito aberto, patas firmes.

## 4. Paleta-guia (fechada, máx. 2 tons por material)

| Material | Ramp |
|----------|------|
| Pelo/corpo | `#341e1a → #54342c` (negro-terra, não preto puro) |
| Casco | `#100a09` |
| Ferradura de ferro | `#7a7c8a → #bcc0ce` (flash prateado) |
| Carne do toco | `#4a0808` |
| Fogo (base → núcleo) | `#bc2a00 → #ff6b08 → #ffa838 → #fff0c8` |
| Arreio/sela | `#28160e → #961810` (couro escuro + debrum sangue) |
| Contorno | `#1a120a` (1 px, mesmo do mundo) |

**Travas de marca (nunca quebrar):**
- Nenhum olho branco redondo (`#ffffff`) — assinatura exclusiva da Caipora.
- Nenhum laranja da juba (`#ff4500` / `#8b2a00`) no corpo da Mula. O fogo pode
  tocar `#ff6b08`, mas nunca a massa laranja-marca da protagonista.
- Nenhum verde `#00fa9a` — exclusivo do cristal/Fúria.

## 5. Poses e animações

| Animação | Descrição | Uso |
|----------|-----------|-----|
| `idle` | Mula firme, fogo pulsando, ferraduras no chão, crina e cauda com brasas. | Loop da arena/exploração. |
| `windup` | Corpo recolhe, patas afundam, coluna de fogo **incha drasticamente** com mais línguas, brasas e overbright. | Telegraph visual do ataque especial. |

## 6. Pipeline técnico (premium reprodutível)

`scripts/tools/gen_mula.py`, determinístico, stdlib + Pillow:

1. **Desenho vetorial supersampled 8×** (1536×1536): formas orgânicas de
   silhueta, pelo com bordas serrilhadas (perturbação senoidal nos vértices,
   inspirada na juba da Caipora), arreio, ferraduras, toco e fogo.
2. **Downsample por área → 192×192** + threshold de alpha (sem halos).
3. **Snap de paleta**: cada pixel cai na cor mais próxima da paleta fechada da
   Mula.
4. **Rim light de fogo**: polígonos e elipses de `FIRE_MID`/`FIRE_DEEP` ao
   longo das bordas do pescoço, ombros e flanco, simulando a luz da coluna
   incandescente sobre o pelo negro.
5. **Outline 1 px `#1a120a`**: todo pixel opaco que toca transparência vira
   contorno escuro contínuo.

Regras de manutenção:
- **Nunca editar `mula_idle.png` / `mula_windup.png` à mão** — toda mudança
  visual passa por `gen_mula.py` e por este documento.
- Contrato de saída: 2 poses (`idle`, `windup`) em 192×192, validado pelos
  testes de assets e de escala.

## 7. O que NUNCA muda / o que pode evoluir

**Imutável:** as travas de marca (§4); toco decepado + coluna de fogo como
assinatura; escala de montaria maior que todos os outros atores; ferraduras de
ferro reluzentes; arreio vermelho-sangue; pelo negro-terra; acabamento flat +
outline 1 px; tom GORE/TERROR.

**Evolui livremente:** forma específica das chamas, quantidade de sangue no
arreio, agressividade da crina em brasa, poses extras (`hurt`, `attack`,
`death`) — desde que derivem das 5 assinaturas de silhueta.
