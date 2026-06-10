# PLANO - Redesign Pop Dark da Caipora

> **SUPERSEDED (2026-06):** este plano foi executado e depois substituído pelo
> conceito "A Guardia da Mata" (96×96, juba-capa, rosto-vazio, chifres, cajado
> de cristal). A lei visual vigente é `docs/CONCEITO-protagonista.md`. Mantido
> como histórico.

> Objetivo: transformar a protagonista em uma figura mais memoravel, pop,
> simpatica e sombria, sem perder o horror folclorico brasileiro nem copiar a
> identidade visual de jogos de referencia.

---

## 1. Validacao da direcao

O pedido esta correto: a Caipora precisa de mais apelo imediato. O sprite atual
tem boas assinaturas de lore (pele escura, juba de fogo, olhos de brasa,
cipos/folhas), mas ainda le pequeno, rigido e pouco desejavel como protagonista.
O problema nao e a premissa; e a falta de uma forma-icone forte.

Referencias como Hollow Knight e Silksong devem ser usadas como analise de
principios, nao como modelo a copiar. O aprendizado util e:

- silhueta reconhecivel em tamanho pequeno;
- rosto simples, quase logotipo;
- contraste alto entre personagem e mundo;
- animacao que comunica personalidade antes de comunicar detalhe;
- protagonista com potencial de avatar, sticker, key art e thumbnail.

O risco principal e transformar a Caipora em "personagem fofo generico". A
solucao e manter a tensao: ela pode ser simpatica de olhar, mas continua sendo
uma entidade perigosa, antiga e vingativa.

---

## 2. Norte criativo revisado

Nome interno do conceito: **Caipora Brasa**.

Frase-guia:

> Uma protetora da mata em forma de boneca sombria de fogo: pequena, expressiva,
> encantadora no primeiro olhar, predadora no segundo.

### Mudanca de leitura

| Antes | Depois |
| --- | --- |
| Predadora mais anatomica | Mascote sombrio premium |
| Corpo longo e rigido | Corpo compacto e expressivo |
| Detalhe folclorico distribuido | Poucas assinaturas muito fortes |
| Juba como chama/cabelo | Juba como icone grafico principal |
| Agressiva antes de simpatica | Simpatica, estranha e ameacadora |

### Travas imutaveis

- Pele escura.
- Fogo como unico acento saturado.
- Olhos de brasa.
- Juba viva de fogo.
- Pes normais para frente; pe invertido e do Curupira.
- Folhas, cipos, jenipapo e urucum como linguagem brasileira.
- Horror real: sangue, floresta hostil, entidade perigosa.

---

## 3. Forma final desejada

### Proporcao

- Cabeca maior: aproximadamente 40% da altura visual.
- Corpo menor e mais simples, com tronco escuro em forma de gota/poncho.
- Pernas curtas, legiveis, com pose de bote.
- Bracos finos e expressivos.
- Chicote/cipo como linha grafica clara.

### Rosto

- Mascara escura de jenipapo como uma grande forma simples.
- Olhos grandes de brasa, levemente assimetricos.
- Boca ausente ou minima; a expressao vem dos olhos e da inclinacao da cabeca.
- A leitura deve funcionar em 32px.

### Juba de fogo

- Deve ser a assinatura de silhueta.
- Forma simples: coroa/flama arredondada + cauda de fogo curta.
- Em idle: chama compacta e viva.
- Em windup: chama arrepia para cima.
- Em strike: chama estica na direcao do golpe.
- Em chama: vira aureola/fagulha, sem poluir o corpo.

### Corpo e roupa

- Folhas como capa/saiote simples, nao como muitos detalhes pequenos.
- Uma assimetria forte: ombreira de folhas ou cipo em um lado.
- Urucum como pequeno risco vermelho, usado com parcimonia.
- Cipo-chicote com ponta em brasa.

---

## 4. Paleta revisada

Manter a logica "corpo escuro + fogo vivo", mas simplificar a leitura:

- Corpo/base: pretos quentes, terra escura, verde quase preto.
- Pele: marrom escuro com highlights quentes minimos.
- Fogo: laranja, amarelo e nucleo claro.
- Olhos: amarelo/branco quente.
- Urucum: vermelho pontual, nunca dominante.

Regra: se uma nova cor compete com o fogo, ela sai.

---

## 5. Pipeline de producao

O pipeline canonico continua sendo `scripts/tools/gen_caipora.py`. Nao editar
PNGs manualmente como fonte de verdade.

### Fase A - Exploracao visual controlada

Entregaveis:

- 3 silhuetas em 64x64:
  - A: cabeca/flama grande, corpo gota;
  - B: poncho de folhas, olhos enormes;
  - C: mais agressiva, juba-cometa curta.
- Uma prancha comparando cada silhueta em:
  - 64x64;
  - 32x32;
  - escala da exploracao;
  - escala da arena.

Criterio de aprovacao:

- A silhueta precisa ser reconhecivel sem cor.
- O rosto precisa ler em miniatura.
- A Caipora precisa parecer jogavel, nao apenas decorativa.

### Fase B - Sprite contract v1

Manter o contrato atual:

- `player_idle.png`
- `player_walk_1.png`
- `player_walk_2.png`
- `player_windup.png`
- `player_strike.png`
- `player_recover.png`
- variantes `*_chama`
- `caipora_sprite_frames.tres`
- `caipora_sprite_frames_chama.tres`

Objetivo:

- substituir o visual sem alterar gameplay, cenas ou testes estruturais.

Criterio de aprovacao:

- exploracao continua legivel com escala `0.8`;
- arena continua expressiva com escala `1.8`;
- `CaiporaSkin` continua sendo o ponto unico de troca;
- `make smoke` passa.

### Fase C - Animacao premium

Depois que a silhueta for aprovada, expandir riqueza visual.

Prioridade:

1. Idle com chama respirando.
2. Windup com compressao forte.
3. Strike com smear de fogo e cipo.
4. Recover com peso.
5. Walk com bounce mais carismatico.

Se necessario, ampliar `SpriteFrames` para mais frames por animacao, mas isso so
deve acontecer depois do redesenho base estar aprovado dentro do jogo.

### Fase D - Integracao de VFX

Adicionar ou ajustar:

- particulas pequenas de brasa no idle/chama;
- trail curto no strike;
- rim light quente em hit/critico;
- sangue/impacto contrastando com o fogo;
- leitura consistente no menu, exploracao e arena.

### Fase E - Key art e marketing

So depois do sprite aprovado:

- portrait da Caipora Brasa;
- icone de app/itch;
- splash/menu;
- thumbnail promocional;
- mini style guide para futuras skins/upgrades.

---

## 6. Ordem de execucao recomendada

1. Criar branch dedicada: `codex/redesign-caipora-pop-dark`.
2. Congelar estado atual dos sprites como referencia em documentacao, sem
   duplicar assets se nao for necessario.
3. Refatorar `gen_caipora.py` para aceitar modos de silhueta/prototipo.
4. Gerar as 3 silhuetas de teste.
5. Montar prancha de comparacao.
6. Escolher uma direcao.
7. Gerar o contrato completo v1.
8. Testar em exploracao, arena e menu.
9. Rodar `make smoke`.
10. Se tocar em timing, input, arena ou camera, rodar tambem as validacoes
    especificas do projeto.
11. Commitar apenas a direcao aprovada.

---

## 7. Criterios de aceite

O redesign so esta pronto quando:

- a Caipora e reconhecivel em silhueta a 32px;
- os olhos e a juba sao identificaveis em gameplay real;
- ela parece mais simpatica/pop sem perder ameaca;
- o fogo continua sendo a assinatura visual dominante;
- a variante `chama` parece uma evolucao da mesma personagem;
- o sprite funciona em fundo escuro, fogo, sangue e UI;
- nao ha copia direta de Hollow Knight, Silksong ou qualquer outra IP;
- `make smoke` passa.

---

## 8. Riscos e mitigacoes

| Risco | Mitigacao |
| --- | --- |
| Ficar fofo demais | Manter olhos de brasa, postura de bote e VFX sangrento |
| Parecer derivado de Hollow Knight | Usar folclore brasileiro, fogo, pele escura, folhas e cipo como nucleos |
| Perder leitura em 64x64 | Priorizar silhueta e rosto antes de textura |
| Poluir com detalhe | Limitar acentos: olhos, juba, ponta do cipo |
| Quebrar cenas | Preservar nomes de arquivos e contrato de `SpriteFrames` no v1 |
| Variante chama virar outro personagem | Mesma silhueta, mais intensidade e particulas |

---

## 9. Definicao de sucesso

A nova Caipora deve passar no teste de desejo:

> Alguem que nunca viu o jogo olha para o sprite parado e entende: "eu quero
> jogar com essa criatura".

E tambem no teste de caipora:

> Ela parece encantadora por um segundo; depois parece que sabe onde voce
> sangra.
