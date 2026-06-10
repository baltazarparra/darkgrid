# PRD Audio v3.1 - Ocarina of Time como Norte

> caipora - extensao da biblia sonora v3.
> Referencia maior: The Legend of Zelda: Ocarina of Time como filosofia de design
> sonoro, nao como copia de timbre, melodia ou identidade.
> Documento base: `docs/PRD-audio-v3.md`.

---

## 1. Intencao

Ocarina of Time e a referencia principal para caipora porque trata audio como linguagem
do mundo. Musica, SFX, silencio e motivos curtos nao ficam separados: tudo participa da
memoria do jogador.

caipora deve aprender essa licao, mas falar com outra boca:

- Zelda usa ocarina, fada, templo, campo aberto e aventura heroica.
- caipora usa assovio, couro de tambor, mata fechada, sangue, fogo e ritual.

O objetivo nao e soar como Zelda. O objetivo e ter a mesma clareza emocional:

**cada lugar tem memoria, cada personagem tem um gesto musical, cada acao importante
tem uma resposta tatil e reconhecivel.**

---

## 2. O Que Importa Em Ocarina

Referencia de design:

1. **Motivos curtos e memoraveis.** Poucas notas bastam quando a identidade e forte.
2. **Musica como geografia.** O jogador reconhece lugar pelo som antes de racionalizar.
3. **SFX limpos e iconicos.** Cada interacao importante tem ataque claro e resposta curta.
4. **Instrumento diegetico.** A ocarina nao e so trilha; e linguagem dentro do mundo.
5. **Silencio como enquadramento.** Quando a musica some, o espaco fica narrativo.
6. **Transicoes suaves.** Mudancas de estado parecem naturais, nao interruptores.
7. **Leitmotifs reaproveitados.** Um motivo volta em outras formas: menor, invertido,
   mais lento, mais escuro, mais seco.

Traducao para caipora:

1. Motivos de 2 a 5 gestos sonoros.
2. Cada fase/boss reconhecivel por textura e motivo.
3. SFX com corpo organico, transiente legivel e pouca fadiga.
4. O assovio da Caipora e o instrumento-identidade.
5. A mata cala antes de revelar perigo.
6. Stems, ducking e ambiencias mudam sem cortes duros.
7. O motivo da Caipora contamina Chama, morte, boss intro e final.

---

## 3. Instrumento Diegetico: O Assovio da Caipora

O equivalente da ocarina em caipora nao deve ser uma flauta bonita. Deve ser o
**assovio da Caipora**: antigo, seco, proximo demais do ouvido, com eco de mata.

Ele vira assinatura do jogo.

Uso prioritario:

- timing perfect: micro-assovio curto, quase uma lamina de ar;
- dodge perfect: assovio aspirado, rapido, com cauda curta;
- boss intro: versao mais longa, chamada de caca;
- Chama: assovio aquecido por brasa;
- fragment bag recover: assovio de retorno, menos hostil;
- ending: assovio distante, ambivalente, a mata ainda viva.

Regras:

- nunca usar o assovio como preenchimento constante;
- reservar para eventos com significado;
- manter variacoes pequenas para o jogador reconhecer a familia;
- evitar soar heroico demais: o assovio e predatorio, nao triunfal.

---

## 4. Leitmotifs Canonicos

Cada motivo deve ser pequeno o bastante para caber em stinger, SFX ou camada top.
O gerador procedural pode expressar os motivos por notas, ritmo, contorno, timbre ou
familia instrumental.

| Motivo | Identidade | Contorno | Timbre |
|---|---|---|---|
| Caipora | predadora da mata | queda curta + resposta grave | assovio + alfaia seca |
| Mata | organismo hostil | pedal grave + evento raro | ambiencia, madeira, inseto que cala |
| Chama | poder que morde | subida curta | brasa, agogo quente, bitcrush luminoso |
| Bolsa | perda/retorno | queda grave, estilhaço, pausa | couro surdo + fragmentos ambar |
| Mula | corrida e incendio | padrao galopado | alfaia rapida + fogo |
| Boitata | serpente de luz | linha sinuosa aguda | pulse lead + chiado |
| Curupira | rastro enganoso | intervalo torto, chamado-resposta | assovio ecoado + madeira |
| Saci | redemoinho | sincopa curta, interrupcao | caixa, ruido filtrado, ar |
| Jesuita | pedra, sino, profanacao | nota grave + sino frio | orgao, gongue, agua benta |
| Morte | mundo esvaziando | queda + zumbido fino | sub grave, ar estreito, silencio |

Regra de ouro: se um boss aparece, seu motivo deve aparecer antes da luta acabar.
Pode estar no stinger, no tema, no telegraph ou na morte.

---

## 5. Musica Adaptativa A La Zelda, Mas Caipora

Ocarina of Time muda a sensacao de lugar e perigo sem sempre chamar atencao para o
sistema. caipora deve fazer isso com stems verticais.

### Camadas

- `base`: pulso, corpo, territorio. Sempre toca em arena/boss.
- `mid`: conflito, movimento, pressao. Entra em combate ativo.
- `top`: identidade, perigo, motivo. Entra em boss ou intensidade alta.

### Estados

| Estado | Musica |
|---|---|
| Exploracao | loop unico atmosferico, motivo de fase diluido |
| Arena comum | stems nivel 1: base + mid |
| Boss | stems nivel 2: base + mid + top |
| HP critico | mid/top descem; heartbeat entra; SFX ficam mais expostos |
| Vitoria | stinger interrompe tensao e resolve o motivo |
| Morte | mix esvazia antes do stinger de game over |

### Regras

- Transicao de intensidade deve durar 0.4s a 1.2s.
- Nao reiniciar faixa se o tema ja esta tocando no boss intro.
- Se stems faltarem, tocar `_base` como fallback.
- O top layer deve ser reconhecivel, mas nao competir com timing alert/perfect.

---

## 6. SFX Tatil: A Licao De Clareza

O SFX de Zelda e forte porque o jogador entende a resposta imediatamente. caipora precisa
da mesma clareza, com materia organica.

### Anatomia de um SFX premium

1. Ataque: informa o evento em menos de 50 ms.
2. Corpo: da peso fisico, sem embolar.
3. Cauda: diz o espaco, curta na mata, longa na igreja.
4. Variacao: 3 variantes para sons repetitivos.
5. Mix: SFX de timing sempre acima da musica.

### Prioridades de implementacao

| Som | Prioridade | Observacao |
|---|---:|---|
| `step_grass` | P0 | tatilidade de exploracao |
| `step_stone` | P0 | igreja precisa soar diferente da mata |
| `hurt_caipora` | P0 | dano recebido nao pode ser igual a dano causado |
| `ui_hover` | P1 | melhora qualidade percebida sem grande risco |
| `herb_pickup` | P1 | compra/erva precisa ser gostosa |
| `pipe_smoke` | P1 | identidade do hub |
| `fragment_bag_drop` | P1 | perda souls-like precisa doer |
| `fragment_bag_recover` | P1 | retorno deve aliviar, sem virar fanfarra |
| `boss_death_*` | P2 | assinatura por chefe |
| `mata_event_*` | P2 | vida ambiente rara |

---

## 7. Silencio Dramatico

O silencio em caipora deve ser deliberado.

Momentos obrigatorios:

- antes de boss intro: ambiencia desce rapido, stinger nasce do vazio;
- HP critico: remover excesso musical para destacar heartbeat e input;
- game over: queda do mundo antes da tela final;
- bolsa recuperada: micro-pausa depois do som, para deixar o alivio entrar.

Numeros iniciais:

- fade pre-boss: 0.3s;
- silencio antes do stinger de boss: 0.5s a 1.2s;
- game over: 0.7s de esvaziamento antes do stinger;
- retorno de ambiencia pos-combate: 1.2s a 2.0s.

---

## 8. Plano De Execucao

Uma etapa por sessao, cada uma pequena o bastante para validar e commitar.

### E1 - Registrar norte Ocarina

Entrega:

- esta PRD v3.1;
- link no `PLAN.md`;
- nenhuma mudanca de runtime.

Aceite:

- smoke verde;
- worktree limpo apos commit.

### E2 - Stems adaptativos

Entrega:

- `AudioDirector` com players sincronizados para `base/mid/top`;
- `set_music_intensity(level: int)`;
- fallback para faixa unica/base;
- testes cobrindo arena comum, boss e fallback.

Arquivos provaveis:

- `scripts/core/audio_director.gd`;
- `tests/unit/test_audio_director.gd`.

### E3 - Modo coracao

Entrega:

- `AudioDirector` reage a `SignalBus.caipora_health_changed`;
- HP < 30% ativa heartbeat e reduz mid/top;
- HP recuperado restaura intensidade anterior.

Arquivos provaveis:

- `scripts/core/audio_director.gd`;
- `tests/unit/test_audio_director.gd`.

### E4 - SFX tateis P0/P1

Entrega:

- novos geradores em `gen_sfx.py`;
- assets regenerados;
- wiring para passos, dano recebido, hover, erva/cachimbo e bolsa.

Arquivos provaveis:

- `scripts/tools/gen_sfx.py`;
- `scripts/systems/sfx_system.gd`;
- `scripts/exploration/exploration_manager.gd`;
- `scripts/hub/hub_manager.gd`;
- `scripts/ui/options_panel.gd` ou componentes de UI;
- testes unitarios relevantes.

### E5 - Leitmotifs por boss e morte unica

Entrega:

- `boss_death_mula`;
- `boss_death_boitata`;
- `boss_death_curupira`;
- `boss_death_saci`;
- `boss_death_jesuita`;
- stingers/gestos de boss reaproveitam motivos canonicos.

Arquivos provaveis:

- `scripts/tools/gen_sfx.py`;
- `scripts/core/audio_director.gd`;
- `scripts/arena/arena_manager.gd`.

### E6 - A mata respira

Entrega:

- scheduler de eventos raros;
- fade/silencio pre-boss;
- esvaziamento de game over;
- retorno suave da ambiencia.

Arquivos provaveis:

- `scripts/core/audio_director.gd`;
- `scripts/core/signal_bus.gd` se precisar de novo sinal.

### E7 - Budget e formato

Entrega:

- fiscal de peso total em `check_audio.py` ou target dedicado;
- decisao documentada: teto novo, reducao de WAV, ou OGG apenas para musica.

Regra:

- SFX seguem WAV.
- OGG, se entrar, entra so para musica longa.

### E8 - Beat-sync experimental

Entrega:

- `BEAT_SYNC_ENABLED := false`;
- API de tempo ate proximo beat;
- apenas inimigos comuns;
- espera maxima de 1 beat;
- janela de timing intacta.

Validacao:

- `/validate-controls`;
- `/validate-platforms`;
- playtest manual no browser.

---

## 9. Criterios De Aceite De Qualidade

Para cada etapa audivel:

- o som melhora a mao do jogador;
- timing alert/perfect continuam legiveis com musica cheia;
- a musica nao cansa em 30 minutos;
- a igreja soa maior que a mata;
- cada boss tem uma assinatura reconhecivel;
- o assovio da Caipora aparece pouco, mas marca memoria;
- `make audio-check` passa;
- peso total e conhecido;
- `make gate` passa antes de commit de runtime;
- se tocar input/timing/camera/UI sensivel, rodar validacoes especificas do projeto.

---

## 10. Fora De Escopo

- Copiar melodias, progressions reconheciveis ou timbres proprietarios de Zelda.
- Voz gravada.
- Samples externos.
- Orquestracao realista.
- Sistema musical horizontal complexo antes dos stems verticais.
- Beat-sync ligado sem playtest.

---

## 11. Decisao Final

caipora deve herdar de Ocarina of Time a inteligencia sonora, nao a superficie.

O equivalente da ocarina e o assovio da Caipora. O equivalente dos templos e a mata
corrompida. O equivalente do heroismo e a vinganca ritual.

Se um som novo nao ajuda o jogador a lembrar, sentir ou agir, ele nao entra.
