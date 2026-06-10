# PRD Audio v3 - O Batuque da Mata

> caipora - direcao sonora premium para um roguelike brasileiro de horror folclorico.
> Status: fonte canonica para a proxima rodada de audio.
> Base tecnica: `AudioDirector`, `SfxSystem`, `gen_sfx.py`, `check_audio.py`,
> `default_bus_layout.tres`.

---

## 1. Intencao

O audio de caipora deve ser agradavel de ouvir, fisico de tocar e hostil de sentir.
Nao e uma camada decorativa. Num jogo em que o jogador vence pelo timing, o som e parte
do controle.

A experiencia alvo e:

**maracatu folk-horror tatil, com a mata respirando junto do input.**

O jogo deve soar autoral, organico e premium sem depender de samples externos. Couro de
tambor, madeira, metal seco, assovio, fogo, agua, pedra e grao digital formam a paleta.
O horror vem do espaco, do silencio e do impacto, nao de ruido constante.

---

## 2. Estado Atual Verificado

A base existente ja e madura:

- `default_bus_layout.tres`: `Master`, `Reverb`, `SFX`, `Music`, `Ambience`; limiter no
  Master; EQ no bus Music; SFX e Ambience enviados ao Reverb.
- `AudioDirector`: autoload persistente com volumes por bus, crossfade, ambiencia por tela,
  stingers, ducking, perfis de reverb e unlock de autoplay HTML5.
- `SfxSystem`: SFX de combate com variantes por round-robin, pitch/volume jitter e players
  descartaveis.
- `gen_sfx.py`: catalogo procedural, deterministico, sem samples externos.
- `check_audio.py`: fiscal de loudness/pico/RMS.
- `make audio-check`: 74 assets atuais passam no padrao.

O principal achado: os stems `base/mid/top` de arenas e bosses ja existem nos assets, mas
o runtime ainda toca apenas o `_base` como fallback. A musica adaptativa esta pronta no
catalogo, mas ainda nao esta viva no jogo.

Risco atual: `assets/audio` pesa cerca de 9.67 MB em bytes reais. O teto de 9 MB precisa
virar criterio automatizado ou ser revisado com uma decisao consciente de formato.

---

## 3. Pilares

### Pilar 1 - A mata respira

A ambiencia deve parecer um organismo atento. Ela reage ao jogador, cala antes do perigo e
volta aos poucos depois do choque. Eventos raros importam mais que preenchimento constante:
galho quebrando, bicho que cala, assovio distante, fogo baixo, pedra fria da igreja.

Regra: quando tudo toca o tempo todo, nada assusta. O silencio e ferramenta de direcao.

### Pilar 2 - O batuque e o controle

O maracatu e a espinha ritmica. Alfaia, caixa, ganza, gongue e agogo devem conversar com
ataque, esquiva, hit-stop e janela de timing. O jogador que escuta deve sentir quando
pressionar.

Regra: SFX de timing sempre vencem o mix. A musica cede espaco na banda de presenca.

### Pilar 3 - O grao e assinatura

O lo-fi e estetica, nao limitacao. 11/22 kHz, mono, bitcrush e caudas impressas devem soar
como fita velha achada na beira do rio: suja, quente, estranha e propria.

Regra: nenhum sample externo entra no catalogo principal. Tudo nasce de geracao procedural
ou de uma decisao documentada de excecao.

### Pilar 4 - Premium e menos cansativo

AAA aqui nao significa volume, excesso de camadas ou graves gigantes. Significa intencao:
hierarquia clara, resposta imediata, variacao anti-repeticao, headroom, loops sem costura,
transicoes suaves e eventos memoraveis.

Regra: o som precisa continuar agradavel apos 30 minutos de run.

---

## 4. Paleta Timbrica

| Familia | Uso | Timbre |
|---|---|---|
| Couro | impacto, coracao, boss, morte | alfaia surda, tambor abafado, pancada com ar |
| Madeira | passos, UI seca, mapa | estalo curto, borda de tarol, galho quebrando |
| Metal | timing, boss reveal, igreja | agogo, gongue, sino, metal frio |
| Ar | esquiva, assovio, mata viva | sopro curto, eco escuro, delay leve |
| Fogo | Chama, hit critico, hub | crepitacao, transiente quente, brasas |
| Agua/pedra | Fase 5, agua benta, igreja | cauda longa, ping frio, reverb grande |
| Grao digital | cola estetica | bitcrush, duty pulse, ruido NES filtrado |

Cada novo som deve declarar sua familia primaria. Se nao couber em nenhuma, provavelmente
nao pertence ao jogo.

---

## 5. Padrao Tecnico

| Item | Padrao |
|---|---|
| Musica e ambiencia | -16 LUFS +/- 1 |
| Stingers | -14 LUFS aprox.; devem furar o mix |
| SFX curtos | pico -3 dBFS; RMS entre -12 e -9 dBFS |
| Pico por asset | <= -1.2 dBFS |
| Sample rate | musica 11025 Hz; SFX/ambiencia/stingers 22050 Hz |
| Canais | mono por padrao |
| Variantes | 3 variantes para SFX repetitivos |
| Orçamento | alvo: <= 9 MB em `assets/audio`; se passar, abrir decisao OGG/reducao |
| Runtime | graceful degradation: asset ausente nunca quebra o jogo |
| Acoplamento | gameplay fala com audio por `SignalBus` ou API local do dono da cena |

---

## 6. Matriz de Experiencia

### Menu

Sensacao: convite ritual, bonito mas incomodo.

Audio: loop curto, assovio distante, grave contido, UI com ticks macios. Nada agressivo
antes do jogador iniciar.

### Hub / Acampamento

Sensacao: unico lugar minimamente respiravel, mas nunca seguro.

Audio: fogo baixo, cachimbo, folhas, tambor distante quase imperceptivel. Compras devem
soar satisfatorias e tacteis, como erva amassada, brasa e sopro.

### Exploracao

Sensacao: a mata observa.

Audio: ambiencia por fase, passos por superficie, eventos raros e silencios. O mapa deve
ficar mais ameaçador perto de boss/bolsa/perigo, sem precisar de UI extra.

### Arena

Sensacao: o corpo do jogador entra no ritmo.

Audio: stems adaptativos. Ataque, alerta de timing, critico e esquiva perfeita devem ser
os sons mais legiveis do jogo. Hit-stop deve calar o mundo por uma fracao.

### Boss

Sensacao: ritual de confronto.

Audio: silencio pre-intro, stinger unico, tema em stems ja no nivel alto. Cada boss deve
ter assinatura: Mula galopa, Boitata serpenteia, Curupira assovia/rastreia, Saci roda,
Jesuita ecoa pedra/sino/agua benta.

### Morte

Sensacao: perda fisica.

Audio: o mix esvazia antes do game over. A bolsa de fragmentos precisa soar como uma queda
grave e injusta, nao como feedback neutro.

---

## 7. Eventos Obrigatorios

Eventos que nao devem ficar mudos:

- passo em mata;
- passo em igreja/pedra;
- ataque da Caipora;
- dano causado;
- dano recebido;
- timing alert;
- timing perfect;
- esquiva perfeita;
- morte de criatura comum;
- morte unica de cada boss;
- abertura de arena;
- boss intro;
- vitoria;
- game over;
- ganhar Chama;
- comprar erva/fumar cachimbo;
- compra negada;
- recuperar bolsa de fragmentos;
- derrubar bolsa na morte;
- hover/foco de UI;
- clique/tap de UI;
- evento raro da mata.

---

## 8. Roadmap Executavel

Uma etapa por sessao, cada uma commitavel.

### E1 - Biblia sonora e budget

Entrega: esta PRD v3 ligada ao `PLAN.md`; `make audio-check` documentado como gate de
qualidade; decisao explicita sobre teto de peso.

Aceite:

- PRD v3 existe e e referenciada.
- Baseline registrado: smoke verde, audio-check verde, peso atual conhecido.

### E2 - Stems adaptativos no runtime

Entrega: `AudioDirector` toca `base/mid/top` sincronizados para arenas e bosses.

Comportamento:

- arena comum entra em intensidade 1;
- boss entra em intensidade 2;
- HP da Caipora < 30% ativa modo coracao: mid/top descem, `heartbeat` entra;
- HP recuperado acima de 30% restaura intensidade anterior;
- se stems faltarem, fallback atual para faixa unica permanece.

Testes:

- `test_audio_director.gd` cobre intensidade, fallback e modo coracao.

### E3 - Eventos tateis de gameplay

Entrega: novos SFX em `gen_sfx.py` e wiring.

Sons prioritarios:

- `step_grass`;
- `step_stone`;
- `hurt_caipora`;
- `herb_pickup`;
- `pipe_smoke`;
- `fragment_bag_drop`;
- `fragment_bag_recover`;
- `ui_hover`.

Testes:

- `test_sfx_variants.gd` cobre variantes novas quando aplicavel.
- Testes de hub/exploracao nao quebram sem assets.

### E4 - Bosses com assinatura sonora

Entrega: mortes/stingers especificos por boss e pequenos gestos de telegraph.

Sons:

- `boss_death_mula`;
- `boss_death_boitata`;
- `boss_death_curupira`;
- `boss_death_saci`;
- `boss_death_jesuita`.

Aceite:

- cada boss tem uma queda sonora propria;
- morte comum nao usa o mesmo som de boss;
- Jesuíta preserva identidade de igreja, sino e agua benta.

### E5 - A mata respira

Entrega: scheduler de eventos raros no `AudioDirector`.

Comportamento:

- em exploracao, evento raro a cada 8-20s;
- corta eventos em arena/menu;
- `boss_intro_started` faz fade rapido da ambiencia antes do stinger;
- game over esvazia o mix antes do stinger.

### E6 - Budget e formato

Entrega: fiscal de peso em `check_audio.py` ou script auxiliar.

Decisao:

- se `assets/audio` seguir acima de 9 MB, escolher uma:
  - reduzir duracao/taxa/camadas;
  - aceitar novo teto documentado;
  - converter apenas musica para OGG, mantendo SFX em WAV.

### E7 - Beat-sync atras de flag

Entrega: `BEAT_SYNC_ENABLED := false` e API de tempo ate o proximo beat.

Escopo:

- apenas inimigos comuns;
- espera maxima de 1 beat;
- nunca altera duracao da janela de timing;
- bosses ficam fora da v1.

Validacao obrigatoria:

- `/validate-controls`;
- `/validate-platforms`;
- playtest manual em browser.

---

## 9. Criterios de Escuta

Antes de marcar uma etapa de audio como pronta, ouvir pelo menos:

- fone comum;
- speaker de notebook;
- volume baixo;
- uma run curta com HP normal;
- uma run curta com HP critico;
- uma boss fight;
- Fase 5 na igreja.

Perguntas de aceite:

- O timing ficou mais facil de sentir sem virar metronomo obvio?
- O critico da vontade de apertar de novo?
- A esquiva perfeita soa leve, rapida e precisa?
- A morte pesa sem ficar desagradavel demais?
- A musica pode tocar por 30 minutos sem fadiga?
- A igreja soa maior que a mata?
- O jogador consegue entender SFX de timing mesmo com musica cheia?

---

## 10. Fora de Escopo

- Voz gravada.
- Samples externos.
- Audio posicional 2D em toda cena.
- Beat-sync ligado por padrao antes de playtest.
- Refazer toda a trilha do zero.
- Acessibilidade auditiva completa; merece PRD propria. Os cues visuais atuais continuam
  obrigatorios.

---

## 11. Decisao de Produto

O caminho premium nao e aumentar o catalogo indiscriminadamente. E fazer o jogo responder.

Prioridade real:

1. stems adaptativos;
2. eventos tateis faltantes;
3. silencio dramatico;
4. boss signatures;
5. budget/formato;
6. beat-sync experimental.

Quando houver duvida, escolher o som que melhora a mao do jogador.
