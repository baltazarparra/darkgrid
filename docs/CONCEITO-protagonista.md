# CONCEITO — A Caipora, Protagonista

> **Este documento é lei visual.** Todo asset, animação, partícula, key art,
> ícone ou material promocional que envolva a protagonista deriva daqui.
> Gerador canônico: `scripts/tools/gen_caipora.py`.

---

## 1. Diagnóstico — por que redesenhar

A Caipora da Fase 7 cumpria o checklist de assinaturas (cabelo de fogo, olhos
brilhando, folhas, cipó) mas falhava no teste que importa: **ninguém olha pra
ela e quer jogar**. Causas:

| Problema | Efeito |
|----------|--------|
| Construção por retângulos simétricos | Lê como "boneco", não como criatura |
| Sem anatomia (sem cintura, ombro, joelho) | Sem peso, sem gênero, sem espécie |
| Cabelo = listras verticais | Lê como "vassoura/coroa", não como fogo |
| Pose frontal estática | Zero atitude; protagonista parece NPC |
| Sem luz | O fogo na cabeça não ilumina nada — vira chapéu |

## 2. Análise — o que faz uma protagonista 2D ser *hype*

Princípios extraídos dos personagens que carregam jogos da indústria popular
(Zagreus/*Hades*, o Prisioneiro/*Dead Cells*, o Cavaleiro/*Hollow Knight*,
o Penitente/*Blasphemous*):

1. **Silhueta primeiro.** O personagem precisa ser identificável em preto
   sólido a 32px. Formas: uma massa grande característica (a juba), um corpo
   médio tenso (o tronco felino), detalhes pequenos (chicote, saiote).
2. **Um único acento de cor saturada sobre corpo escuro.** *Dead Cells* é
   laranja-sobre-teal; *Hades* é vermelho-sobre-bronze. A Caipora é
   **fogo-sobre-terra**: todo o resto da paleta é dessaturado para o fogo
   estourar.
3. **Luz própria.** Personagens "premium" carregam a própria iluminação (a
   chama do Prisioneiro, o lampião de *Childe of Light*). O fogo da juba gera
   **rim light térmico** nas bordas do corpo — é isso que separa "sprite com
   cabelo laranja" de "criatura iluminada por fogo".
4. **Assimetria.** Ombreira só de um lado, juba varrida para trás, arma numa
   mão só. Simetria = estática; assimetria = movimento congelado.
5. **Atitude na pose neutra.** O idle já conta a história: tronco inclinado,
   olhar por baixo da testa, mão na arma. Predadora, nunca turista.
6. **Anticipação e smear legíveis.** O windup comprime (mola), o strike vira
   mancha de luz (smear de 3 tons), o recover assenta. A linguagem do corpo
   ecoa a mecânica central (timing).

## 3. Autenticidade — o folclore como fonte, não fantasia genérica

Travas de lore (inegociáveis, já estabelecidas no projeto):

- **Caboclinha da mata**: pele escura. Não suavizar.
- **Cabelo de fogo**: a juba é chama viva, não cabelo ruivo.
- **PÉS NORMAIS PRA FRENTE** — o pé-pra-trás é do Curupira (parente), não dela.
- **Senhora dos rastros e da vingança**: ela pune caçadores; é ameaça, não mascote.
- **Cachimbo** existe no universo (hub); não entra no sprite de combate.

Elementos folclóricos incorporados ao redesign:

- **Urucum**: risco de garra vermelho na bochecha (pintura de guerra).
- **Jenipapo**: faixa preto-azulada atravessando os olhos (máscara de caça)
  e faixa diagonal no peito — faz a brasa dos olhos estourar no escuro.
- **Folhas e cipós como vestes vivas**: peitoral, saiote, ombreira (um lado
  só), braceletes de cipó no antebraço e na canela.

## 4. O conceito: **A Predadora-Rainha da Mata**

Uma entidade antiga com corpo de caçadora: silhueta felina, tronco inclinado
pra frente, ombros largos, cintura estreita — sempre a meio passo do bote.
A juba de fogo flui pra trás em **arco de cometa ascendente**: mesmo parada,
ela parece estar avançando. O fogo é dela; a mata escura existe ao redor do
brilho que ela carrega.

### Assinaturas visuais (as 5 travas do design)

1. **Juba-cometa de fogo** — nasce do couro cabeludo, sobe em línguas curtas
   na coroa e flui pra trás afinando até brasas soltas. No strike, estica
   horizontal (velocidade); no windup, eriça (ameaça).
2. **Rim light térmico** — toda borda superior do corpo voltada ao fogo recebe
   um pixel de realce quente (`SK_HL`). A fonte de luz é ELA.
3. **Olhos de brasa na máscara de jenipapo** — faixa escura na linha dos
   olhos; dentro, âmbar com núcleo branco-quente. O olho da frente é maior
   (encara a presa).
4. **Cipó-chicote vivo** — madeira escura, folhas brotando, **ponta em brasa**
   (o estalo crítico nasce ali). No strike vira smear de 3 tons de fogo.
5. **Vestes vivas assimétricas** — ombreira de folhas só no ombro do chicote;
   peitoral e saiote de folhas com pontas irregulares; urucum na bochecha.

### Paleta (ramps fechados — fonte: `gen_caipora.py`)

| Material | Ramp |
|----------|------|
| Fogo | `#941c08 → #d03604 → #ff6b00 → #ffac30 → #ffecb4` |
| Pele | `#341c16 → #54301e → #7c4c2c → #b2743e` (rim) |
| Folha/cipó | `#102012 → #223a1e → #546e30` (realce) |
| Terra/madeira | `#221210 → #3d1f1f` |
| Urucum / Jenipapo | `#c42c14` / `#181014` |
| Olhos | `#ffd654` + núcleo `#ffffdc` |

O fogo é o ÚNICO material de alta saturação. Se um novo asset da Caipora
precisa de destaque, a resposta é sempre fogo — nunca uma cor nova.

### Linguagem corporal por frame

| Frame | Corpo | Juba | Chicote |
|-------|-------|------|---------|
| `idle` | Tronco inclinado, mão na arma | Arco de cometa | Pende vivo, ondulando |
| `walk_1/2` | Passada em tesoura + contrabalanço dos braços | Balança com a fase | Pende |
| `windup` | Agachada, mola comprimida | Eriçada pra cima | Arco tensionado atrás do ombro |
| `strike` | Afundo, queixo avançado | Esticada horizontal | **Smear de 3 tons + estalo branco** |
| `recover` | Assentando o peso | Assentando | Caindo à frente, ainda balançando |

## 5. Pipeline técnico (o "premium" reprodutível)

`gen_caipora.py`, determinístico, stdlib + Pillow:

1. **Desenho vetorial supersampled 8×** (512×512): membros capsulares com
   afunilamento, polígonos orgânicos, juba por discos ao longo de spline.
2. **Downsample por área → 64×64** + threshold de alpha (sem halos).
3. **Snap de paleta**: cada pixel cai no ramp mais próximo (paleta fechada).
4. **Selout**: borda externa escurecida (1px) — coesão contra qualquer fundo.
   Fogo e olhos ficam de fora (material emissivo não tem contorno).
5. **Rim light procedural**: bordas superiores (e dorsais, em dither) de
   pele/folha/terra dentro do alcance do fogo sobem um degrau no ramp.
6. **Dither de bandas no fogo**: xadrez na fronteira entre tons — chama
   orgânica, não listras.

Regra de manutenção: **nunca editar os PNGs `player_*` à mão** — toda mudança
visual da protagonista passa por `gen_caipora.py` e por este documento.

## 6. O que NUNCA muda / o que pode evoluir

**Imutável:** pele escura; juba de fogo fluindo PRA TRÁS; pés normais pra
frente; fogo como único acento saturado; olhos de brasa; chicote com ponta em
brasa; postura de predadora.

**Evolui livremente:** densidade de folhas (upgrades podem vesti-la mais),
intensidade da juba (fúria/CHAMA podem incendiá-la), partículas, key art em
resolução maior — desde que derive das 5 assinaturas.

**Já realizado:** a CHAMA incendeia a própria Caipora — variante
`player_*_chama.png` (`caipora(..., chama=True)`): juba +longa/+quente, brasas
orbitando, estalo do chicote maior. Selecionada em runtime por
`MetaProgression.caipora_frames_path()` (exploração, arena e TitleWalker).
