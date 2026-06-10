# Plano de Execucao - Audio v3.1

> Execucao elegante da PRD `docs/PRD-audio-v3-1-ocarina.md`.
> Norte: Ocarina of Time como inteligencia sonora; caipora como maracatu folk-horror
> tatil, hostil e autoral.

---

## 1. Objetivo

Transformar o audio atual de caipora de uma base tecnica boa para uma experiencia viva:

- musica que reage ao estado do combate;
- HP critico sentido no corpo antes de ser lido na UI;
- SFX tateis para movimento, dano, UI, hub e bolsa;
- bosses com assinatura sonora propria;
- mata que respira, cala e volta;
- budget conhecido para HTML5.

Este plano organiza a execucao em sessoes pequenas, testaveis e commitaveis.

---

## 2. Principios De Execucao

1. **Uma sessao, uma entrega.** Nao misturar runtime, geracao de assets e tuning grande
   sem necessidade.
2. **Runtime antes de catalogo novo.** Primeiro ligar os stems que ja existem; depois
   adicionar sons.
3. **Fallback sempre.** Asset ausente nunca quebra o jogo.
4. **Sinais antes de referencias diretas.** Audio reage via `SignalBus` ou API do dono
   local da cena.
5. **Audio-check sempre que asset muda.** `make audio-check` e obrigatorio em qualquer
   mudanca de `assets/audio` ou `gen_sfx.py`.
6. **Gate antes de commit de runtime.** `make gate` para codigo; docs podem usar smoke +
   audio-check.
7. **Beat-sync por ultimo.** Qualquer mudanca em timing fica isolada, atras de flag e
   exige validacoes de controle/plataforma.

---

## 3. Ordem Recomendada

### S0 - Baseline de audio

Tipo: verificacao.

Objetivo: garantir que a base esta estavel antes de mexer.

Comandos:

- `make smoke`
- `make audio-check`
- medir peso real de `assets/audio`

Aceite:

- smoke verde;
- audio-check verde;
- peso registrado no report da sessao.

Observacao: baseline atual conhecido: 74 assets verdes; `assets/audio` perto de 9.67 MB.

---

### S1 - Stems adaptativos no AudioDirector

Tipo: runtime.

Objetivo: fazer o jogo tocar `base`, `mid` e `top` de arenas/bosses em sincronia.

Status: implementado. `AudioDirector` usa stems sincronizados em arenas/bosses,
arena comum entra em intensidade 1, boss entra em intensidade 2, e o fallback para
`_base` permanece quando um conjunto completo de stems nao existe.

Arquivos provaveis:

- `scripts/core/audio_director.gd`
- `tests/unit/test_audio_director.gd`

Implementacao:

- adicionar tres players persistentes para stems;
- manter os dois players atuais de crossfade para faixas single-loop, ou encapsular sem
  quebrar menu/hub/exploracao;
- resolver stems por nome:
  - `mus_arena_pN_base.wav`
  - `mus_arena_pN_mid.wav`
  - `mus_arena_pN_top.wav`
  - `mus_boss_X_base.wav`
  - `mus_boss_X_mid.wav`
  - `mus_boss_X_top.wav`
- iniciar stems no mesmo frame;
- tweenar volumes por intensidade;
- fallback para `_base` ou faixa unica quando stems faltarem.

API sugerida:

- `set_music_intensity(level: int) -> void`
- `_play_music_context(path: String) -> void`
- `_has_stems(path: String) -> bool`
- `_play_stems(path: String) -> void`
- `_stop_stems(fade: float) -> void`

Estados iniciais:

- arena comum: intensidade 1 (`base + mid`);
- boss: intensidade 2 (`base + mid + top`);
- menu/hub/exploracao/ending: single-loop como hoje.

Testes:

- arena comum escolhe stems e intensidade 1;
- boss escolhe stems e intensidade 2;
- transicao boss-intro -> arena nao reinicia se contexto e o mesmo;
- fallback toca `_base` se stems completos nao existirem;
- single-loop de menu/hub segue funcionando.

Validacao:

- `make gate`
- `make audio-check`

Risco:

- dessincronia de stems no browser. Mitigacao: iniciar no mesmo frame e manter streams
  com mesma duracao; validar no export depois.

---

### S2 - Modo coracao

Tipo: runtime.

Objetivo: comunicar HP critico como estado fisico, inspirado na clareza de Zelda, mas
com alfaia/heartbeat de caipora.

Arquivos provaveis:

- `scripts/core/audio_director.gd`
- `tests/unit/test_audio_director.gd`

Implementacao:

- conectar `SignalBus.caipora_health_changed`;
- definir limiar `CRITICAL_HP_RATIO := 0.30`;
- ao entrar em critico:
  - reduzir mid/top;
  - manter base baixa;
  - tocar `assets/audio/ambience/heartbeat.wav` em player dedicado ou camada Ambience;
  - expor SFX com menos competicao;
- ao sair do critico:
  - restaurar intensidade anterior;
  - fade out do heartbeat.

API sugerida:

- `_on_caipora_health_changed(new_health: float, max_health: float) -> void`
- `_set_heart_mode(enabled: bool) -> void`

Testes:

- HP acima de 30% nao ativa heartbeat;
- HP abaixo de 30% ativa heart mode;
- cura acima do limiar restaura intensidade anterior;
- heart mode nao toca se audio ainda nao foi desbloqueado no HTML5.

Validacao:

- `make gate`
- playtest curto em arena.

Risco:

- cansaco auditivo. Mitigacao: heartbeat grave, curto, sem pico agudo; volume abaixo do
  timing alert/perfect.

---

### S3 - SFX tateis P0

Tipo: assets + runtime.

Objetivo: preencher eventos basicos que hoje reduzem a qualidade percebida.

Sons P0:

- `step_grass`
- `step_stone`
- `hurt_caipora`

Arquivos provaveis:

- `scripts/tools/gen_sfx.py`
- `assets/audio/sfx/*.wav`
- `scripts/systems/sfx_system.gd`
- `scripts/exploration/exploration_manager.gd`
- `scripts/arena/arena_manager.gd`
- `tests/unit/test_sfx_variants.gd`

Implementacao:

- gerar 3 variantes para `step_grass` e `step_stone`;
- gerar 3 variantes para `hurt_caipora`;
- registrar novos exports no `SfxSystem` ou criar API por nome com carregamento graceful;
- tocar passo apenas quando movimento de tile for confirmado;
- usar `step_stone` na Fase 5/igreja;
- tocar `hurt_caipora` quando a Caipora perde HP, distinto de `hit`.

Testes:

- variantes descobertas por convencao;
- passo nao toca em movimento bloqueado;
- Fase 5 usa pedra;
- dano recebido usa som proprio.

Validacao:

- `make audio`
- `make audio-check`
- `make gate`
- `/validate-controls` se tocar logica de movimento/input.

Risco:

- passos repetitivos. Mitigacao: round-robin, jitter, volume baixo, nao tocar em excesso.

---

### S4 - SFX tateis P1

Tipo: assets + runtime.

Objetivo: elevar hub, UI e corpse run para padrao premium.

Sons P1:

- `ui_hover`
- `herb_pickup`
- `pipe_smoke`
- `fragment_bag_drop`
- `fragment_bag_recover`

Arquivos provaveis:

- `scripts/tools/gen_sfx.py`
- `scripts/core/audio_director.gd`
- `scripts/hub/hub_manager.gd`
- `scripts/exploration/exploration_manager.gd`
- `scripts/ui/options_panel.gd`
- `scripts/ui/main_menu.gd`
- testes de hub/exploracao/UI relevantes.

Implementacao:

- `ui_hover`: baixo volume, agogo/tick seco, usado em foco/hover sem spam;
- `herb_pickup`: chocalho/erva amassada;
- `pipe_smoke`: sopro grave + brasa;
- `fragment_bag_drop`: queda grave + estilhaços ambar;
- `fragment_bag_recover`: alivio contido + assovio de retorno.

Testes:

- compra bem-sucedida toca som de sucesso;
- compra negada preserva feedback seco;
- recuperar bolsa dispara som proprio;
- hover nao cria player se audio bloqueado ou se foco nao mudou.

Validacao:

- `make audio`
- `make audio-check`
- `make gate`
- `/validate-platforms` se mexer em UI touch/hover de forma sensivel.

---

### S5 - Assovio da Caipora como assinatura

Tipo: assets + runtime/tuning.

Objetivo: estabelecer o equivalente diegetico da ocarina sem copiar Zelda.

Sons/casos:

- assovio curto para timing perfect;
- assovio aspirado para dodge perfect;
- assovio de caca no boss intro;
- assovio quente na Chama;
- assovio distante no ending.

Arquivos provaveis:

- `scripts/tools/gen_sfx.py`
- `scripts/core/audio_director.gd`
- `scripts/arena/arena_manager.gd`
- `scripts/ui/ending_screen.gd` se necessario.

Implementacao:

- evitar tocar assovio em todo evento pequeno;
- preservar o `timing_perfect` atual como base, mas enriquecer com camada de assovio;
- manter variações reconheciveis pelo contorno, nao pelo volume.

Aceite auditivo:

- jogador reconhece "isso e a Caipora";
- nao soa heroico/flauta bonita;
- nao compete com timing alert.

Validacao:

- `make audio`
- `make audio-check`
- `make gate`
- escuta manual de boss intro e timing.

---

### S6 - Boss signatures

Tipo: assets + runtime.

Objetivo: cada boss ter memoria sonora propria.

Sons:

- `boss_death_mula`
- `boss_death_boitata`
- `boss_death_curupira`
- `boss_death_saci`
- `boss_death_jesuita`

Arquivos provaveis:

- `scripts/tools/gen_sfx.py`
- `scripts/core/audio_director.gd`
- `scripts/arena/arena_manager.gd`
- `tests/unit/test_audio_director.gd`
- testes de boss se houver caminho especifico.

Implementacao:

- mapear boss_type/fase para stinger de morte;
- morte comum segue som seco separado;
- boss death toca acima da musica e pode duckar o mix;
- Jesuita preserva igreja/sino/orgao/agua benta.

Testes:

- cada fase/boss resolve stinger proprio;
- comum nao toca boss death;
- fallback para `death_sound` se asset ausente.

Validacao:

- `make audio`
- `make audio-check`
- `make gate`

---

### S7 - A mata respira

Tipo: runtime + assets opcionais.

Objetivo: ambiencia reativa, eventos raros e silencio dramatico.

Arquivos provaveis:

- `scripts/core/audio_director.gd`
- `scripts/tools/gen_sfx.py`
- `tests/unit/test_audio_director.gd`

Implementacao:

- criar scheduler com intervalo 8-20s em exploracao;
- tocar `mata_event_*` em volume baixo;
- pausar scheduler fora da exploracao;
- ao `boss_intro_started`:
  - fade rapido da ambiencia;
  - pequena pausa;
  - stinger nasce do vazio;
- no game over:
  - esvaziar music/ambience;
  - stinger depois de pausa curta;
- retorno pos-combate em 1.2-2.0s.

Testes:

- scheduler so roda em exploracao;
- boss intro reduz ambiencia antes do stinger;
- game over chama esvaziamento;
- nenhum timer fica vivo apos troca de tela.

Validacao:

- `make audio`
- `make audio-check`
- `make gate`
- playtest manual.

---

### S8 - Budget de audio

Tipo: tools/build.

Objetivo: controlar peso antes de continuar adicionando assets.

Arquivos provaveis:

- `scripts/tools/check_audio.py`
- `Makefile`
- `docs/PRD-audio-v3.md` se o teto mudar.

Implementacao:

- adicionar medicao de bytes totais de `assets/audio`;
- imprimir total por categoria;
- definir limite inicial:
  - warning acima de 9 MB;
  - fail acima de 10 MB, ou outro teto decidido;
- manter `make audio-check` rapido;
- se necessario, criar `make audio-budget`.

Decisao posterior:

- reduzir WAVs longos;
- aceitar teto de 10 MB;
- converter apenas musica para OGG.

Validacao:

- `make audio-check`
- `make gate`

---

### S9 - Beat-sync experimental

Tipo: timing/input, alto risco.

Objetivo: experimentar telegraphs de inimigos comuns alinhados ao pulso musical.

Arquivos provaveis:

- `scripts/core/audio_director.gd`
- `scripts/arena/arena_manager.gd`
- `scripts/systems/timing_system.gd`
- talvez novo `scripts/core/audio_beat_map.gd`
- testes de timing/arena.

Implementacao:

- constante `BEAT_SYNC_ENABLED := false`;
- mapa BPM por faixa;
- `time_to_next_beat() -> float`;
- inicio de wind-up de inimigo comum pode aguardar o proximo beat;
- espera maxima de 1 beat;
- janela de timing nao muda;
- bosses fora da v1.

Validacao obrigatoria:

- `make gate`
- `/validate-controls`
- `/validate-platforms`
- playtest manual em browser.

Kill switch:

- se o feel piorar, manter desligado e fechar como experimento documentado.

---

## 4. Dependencias Entre Sessoes

```text
S0 baseline
  -> S1 stems
      -> S2 heart mode
  -> S3 P0 tactile SFX
      -> S4 P1 tactile SFX
          -> S5 assovio signature
              -> S6 boss signatures
S1/S2/S3/S4/S5/S6
  -> S7 mata respira
S3/S4/S5/S6/S7
  -> S8 budget
S1/S2/S8
  -> S9 beat-sync experimental
```

S1 e S2 devem vir antes dos sons mais cosmeticos porque mudam a experiencia estrutural.
S9 fica por ultimo porque toca timing.

---

## 5. Estrategia De Testes

### Docs only

- `make smoke`
- `make audio-check`

### Runtime sem assets novos

- `make gate`
- `make audio-check`

### Assets novos

- `make audio`
- `make audio-check`
- `make gate`

### Movimento/input/timing/UI sensivel

- `make gate`
- `/validate-controls`
- `/validate-platforms`

### Export/browser

Obrigatorio depois de S1, S2 e S9:

- `make export`
- teste em browser;
- verificar drift de stems e autoplay unlock.

---

## 6. Criterios De Pronto Por Sessao

Uma sessao so esta pronta quando:

- a entrega e pequena e nomeavel em uma frase;
- testes relevantes passaram;
- audio-check passou se asset mudou;
- nenhum asset novo ficou sem geracao procedural;
- fallback para asset ausente existe;
- `PLAN.md` ou report foi atualizado se a decisao mudou;
- commit foi criado.

---

## 7. Primeiras Tres Sessoes Recomendadas

1. **S1 - Stems adaptativos.** Maior ganho com assets ja existentes.
2. **S2 - Modo coracao.** Faz o jogo comunicar risco pelo corpo.
3. **S3 - SFX tateis P0.** Passos e dano recebido mudam a qualidade percebida do minuto
   a minuto.

Depois disso, seguir para hub/bolsa/UI e so entao boss signatures.

---

## 8. Riscos E Guardrails

| Risco | Guardrail |
|---|---|
| Stems dessincronizam no HTML5 | iniciar no mesmo frame, medir no export, fallback para base |
| Heartbeat fica irritante | volume baixo, sem agudo, fade curto, playtest de 30 min |
| Passos viram spam | tocar so em tile confirmado, 3 variantes, volume baixo |
| UI hover fica cansativo | cooldown/foco mudou, volume muito baixo |
| Catalogo passa do budget | S8 antes de aumentar demais, medir por categoria |
| Beat-sync estraga game feel | flag desligada, uma sessao isolada, validacoes obrigatorias |
| Audio novo quebra cenas headless | ResourceLoader.exists e fallback sempre |

---

## 9. Definicao De Elegancia

Esta execucao sera elegante se o jogador nao perceber o sistema. Ele so deve sentir que:

- a mata ouviu seus passos;
- a Caipora tem uma voz propria;
- o combate pulsa com a mao;
- a morte esvazia o mundo;
- cada boss deixa uma cicatriz sonora;
- tudo carrega rapido no browser.

Quando houver duvida entre mais conteudo e mais resposta, escolher mais resposta.
