# CONCEITO — Mapas e Tiles Organicos

> Este documento deriva da protagonista aprovada. A Caipora e a marca visual do
> jogo; os mapas precisam parecer uma extensao fisica dela: silhuetas duras,
> massa preta, bordas serrilhadas, laranja controlado, sangue real e floresta
> hostil.

Fonte canonica dos PNGs:
- `scripts/tools/gen_tiles.py`
- `assets/sprites/tile_identity_contact_sheet.png`
- `assets/sprites/tile_identity_value_sheet.png`
- `assets/sprites/tile_floor.png`
- `assets/sprites/tile_wall.png`
- `assets/sprites/tile_floor_church.png`
- `assets/sprites/tile_wall_church.png`

## 1. Lei visual

Os mapas nao sao fundo neutro. A mata e um corpo antigo. O chao tem lama,
raiz, sangue seco, osso, poça preta e folhas como dentes. A parede e uma massa
densa de tronco, folha, cipó e breu. A igreja final nao e uma igreja limpa:
ela esta invadida pela mata, rachada, sangrada e apodrecida.

O jogador precisa sentir que a Caipora pertence ao mundo porque ela e feita da
mesma linguagem: laranja serrilhado, vazio preto, olhos/luzes pontuais e forma
chapada.

## 2. Hierarquia de leitura

A identidade nao pode esmagar a jogabilidade. Em gameplay, o mapa precisa ter
uma escada clara de valor:

1. **Chao caminhavel** — medio-escuro, texturizado, mas sem grandes massas de
   preto puro. Deve ser o plano onde a Caipora pisa.
2. **Parede/bloqueio** — muito escuro, vertical, denso e continuo. Deve ler
   como limite antes de qualquer detalhe.
3. **Hazards** — alto contraste imediato: fogo quente ou osso claro sobre base
   escura.
4. **Props/interativos** — silhueta simples + contorno escuro + acento legivel.
5. **Atmosfera** — fog/vinheta/luz da cena podem escurecer, mas os tiles base
   ja precisam nascer separados em valor.

Regra pratica: o piso de floresta deve ficar visivelmente mais claro que a
parede de floresta; o piso de igreja deve ficar muito mais claro que a parede
de igreja. Se tudo vira a mesma mancha escura, o estilo falhou.

## 3. Contrato tecnico

O `ExplorationManager` consome quatro atlas:

| Arquivo | Tamanho | Variantes | Uso |
|---------|---------|-----------|-----|
| `tile_floor.png` | 128x32 | 4 | chao de floresta |
| `tile_wall.png` | 64x32 | 2 | parede/mata densa |
| `tile_floor_church.png` | 128x32 | 4 | chao da igreja |
| `tile_wall_church.png` | 64x32 | 2 | parede da igreja |

Nao mudar nomes, dimensoes, quantidade de variantes ou tamanho de tile sem
ajustar `scripts/exploration/exploration_manager.gd` e testes.

## 4. Paleta

Use paleta fechada, com no maximo poucos tons por material:

| Papel | Cores principais |
|-------|------------------|
| Breu/silhueta | `#000000`, `#0d1117` |
| Terra viva | `#361d18`, `#58342d`, `#462723` |
| Casca/raiz | `#22140a`, `#462a14` |
| Mata escura | `#152d12`, `#26441c` |
| Laranja Caipora | `#8b2a00`, `#ff4500` |
| Fogo/CHAMA | `#ff6808`, `#ffb032` |
| Sangue | `#420000`, `#8b0000` |
| Osso | `#423a2f`, `#afa486` |
| Igreja | `#2e2e38`, `#626068`, `#8e8876` |

Verde vivo pertence ao cristal/Furia da Caipora. Nos mapas, verde deve ser
escuro, doente e organico.

## 5. Variantes

### Floresta

- `floor v0`: terra molhada atravessada por raizes.
- `floor v1`: serrapilheira denteada, folhas como pequenas facas.
- `floor v2`: sangue seco e raizes pretas.
- `floor v3`: poça preta, osso e podridao laranja.
- `wall v0/v1`: mata densa como parede de silhueta; troncos, folhas-dente,
  feridas laranja e bloqueio visual claro.

### Igreja

- `floor v0`: laje rachada.
- `floor v1`: pedra invadida por raizes.
- `floor v2`: sangue seco no piso.
- `floor v3`: cera, cinza e piso quebrado.
- `wall v0`: cruz torta, sombra preta e sangue escorrido.
- `wall v1`: arco/altar quebrado invadido por raizes e folhas.

## 6. Hazards e props

`scripts/exploration/map_object.gd` completa os tiles:

- `FIRE`: CHAMA triangular, preta na base, quente no centro.
- `SPIKE`: dente de raiz/osso, nao cone limpo.
- `ROOTS`: silhueta preta mordendo o chao.
- `DEAD_TREE`: tronco-garra, lascas de laranja, galhos retorcidos.
- `CROSS/CANDLE/PEW/FONT`: igreja corrompida, liturgia suja, nunca decoracao
  limpa ou generica.

## 7. Checklist

- O mapa parece extensao da Caipora?
- Chao, parede, hazard e prop leem em quatro camadas diferentes?
- A parede le como bloqueio escuro antes de detalhe?
- O chao e organicamente hostil sem esconder entidades nem parecer parede?
- O laranja aparece como assinatura/acento, nao como tapete inteiro?
- A igreja parece contaminada pela mata e pelo sangue?
- O acabamento segue pixel art chapada, sem gradiente suave ou brilho plastico?
- `make gate` passa e previews reais de fases 1/3/5 continuam legiveis?
