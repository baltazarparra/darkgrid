# PRD — Fase 3: Enemy AI & Visceral Feedback

> **caipora** — Brazilian Folk Horror Roguelike  
> **Fase:** 3 / 5  
> **Status:** 📝 Revisado (pronto para execução)  
> **Document Version:** 1.0  
> **Depende de:** [PRD-fase-2.md](./PRD-fase-2.md) (Arena & Timing)  

---

## 1. Visão Geral

A Fase 3 transforma a **Criatura** de um boneco de treino em um predador. Até agora, o combate funciona — mas a Criatura não respira. Ela não pensa. Não há tensão no momento antes do golpe. O jogador precisa **sentir** que a Criatura está viva, que ela o observa, que o ataque vem de um lugar de fome e ódio.

Esta fase introduz:
- **StateMachine** na Criatura: ela não ataca por turnos impostos pelo ArenaManager — ela decide.
- **AttackPattern** configurável: wind-up visual → telegraph → strike, com parâmetros ajustáveis.
- **Boss**: uma segunda Criatura mais rápida e letal, com pattern de múltiplos golpes.
- **Visceral Feedback**: hit-stop frames que congelam o mundo no impacto, death animation que faz a morte do ator ser um evento, e SFX que dão peso a cada ação.

**Tom:** O combate não é mais um minigame de timing. É um duelo. Cada golpe é uma sentença. Cada esquiva é uma respiração roubada.

**Filosofia:** *"O inimigo não é um obstáculo. O inimigo é uma promessa de dor. Se ele não ameaçar, o jogador não sente vitória."*

---

## 2. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Criatura Autônoma** | StateMachine controla o ciclo de ataque da Criatura; ArenaManager delega turnos via sinais |
| 2 | **Telegraph Visível** | Wind-up da Criatura tem feedback visual (tween de escala/cor) antes da janela de defesa abrir |
| 3 | **Boss Ameaçador** | Segunda entidade com pattern de ataque diferente (mais rápido ou múltiplos golpes) |
| 4 | **Hit-Stop Visceral** | Jogo congela por 2-3 frames no impacto de crítico ou morte |
| 5 | **Morte É Evento** | Death animation com flash branco, fade out e explosão de partículas |
| 6 | **Som É Sangue** | Cada ação tem SFX distinto: ataque, hit, esquiva, timing perfeito, morte |

---

## 3. Requisitos Funcionais

### 3.1 RF-301 — StateMachine na Criatura

**Descrição:** A Criatura deve ter um StateMachine que gerencia seus estados de combate autonomamente, em vez de ser controlada por timers no ArenaManager.

**Artefatos:**
- `scripts/entities/enemy_state_machine.gd` (class_name EnemyStateMachine)
- `scripts/entities/attack_pattern.gd` (class_name AttackPattern)
- Modificações em `scripts/entities/criatura.gd`
- Modificações em `scripts/arena/arena_manager.gd`

**Estados:**
```
IDLE → WIND_UP → ATTACK → COOLDOWN → IDLE
```

**Detalhes Técnicos:**
```gdscript
class_name EnemyStateMachine
extends Node

enum State { IDLE, WIND_UP, ATTACK, COOLDOWN }

signal state_changed(new_state: State)
signal attack_started
signal attack_finished

var _current_state: State = State.IDLE
var _attack_pattern: AttackPattern
var _state_timer: Timer

func _ready() -> void:
    _state_timer = Timer.new()
    _state_timer.one_shot = true
    _state_timer.timeout.connect(_on_state_timer_timeout)
    add_child(_state_timer)

func start_pattern(pattern: AttackPattern) -> void:
    _attack_pattern = pattern
    _transition_to(State.IDLE)

func _transition_to(new_state: State) -> void:
    _current_state = new_state
    state_changed.emit(new_state)
    match new_state:
        State.IDLE:
            _state_timer.wait_time = _attack_pattern.idle_duration
            _state_timer.start()
        State.WIND_UP:
            _state_timer.wait_time = _attack_pattern.wind_up_duration
            _state_timer.start()
        State.ATTACK:
            attack_started.emit()
            _state_timer.wait_time = _attack_pattern.attack_duration
            _state_timer.start()
        State.COOLDOWN:
            _state_timer.wait_time = _attack_pattern.cooldown_duration
            _state_timer.start()

func _on_state_timer_timeout() -> void:
    match _current_state:
        State.IDLE:
            _transition_to(State.WIND_UP)
        State.WIND_UP:
            _transition_to(State.ATTACK)
        State.ATTACK:
            attack_finished.emit()
            _transition_to(State.COOLDOWN)
        State.COOLDOWN:
            _transition_to(State.IDLE)
```

- `AttackPattern` é um `Resource` (class_name AttackPattern extends Resource) com exports:
  - `wind_up_duration: float = 0.5`
  - `attack_duration: float = 1.0` (duração da janela de timing de defesa)
  - `cooldown_duration: float = 2.0`
  - `idle_duration: float = 0.3`
  - `damage_multiplier: float = 1.0`

- `Criatura` ganha um nó filho `EnemyStateMachine` (script `enemy_state_machine.gd`)
- `Criatura` ganha um nó filho `AttackPattern` (instância de resource com valores padrão)

**Refatoração do ArenaManager:**
- Remover `_windup_timer` do ArenaManager (migrado para EnemyStateMachine)
- ArenaManager conecta `criatura.state_machine.attack_started` para abrir a janela de defesa
- ArenaManager conecta `criatura.state_machine.attack_finished` para fechar a janela de defesa (se ainda aberta)
- Ciclo de turnos: Caipora ataca → espera cooldown → Criatura inicia pattern → loop

**Critério de Aceitação:**
- [ ] Criatura transiciona autonomamente entre IDLE → WIND_UP → ATTACK → COOLDOWN
- [ ] Wind-up dura exatamente `attack_pattern.wind_up_duration` segundos
- [ ] Ataque inicia exatamente após wind-up terminar
- [ ] Cooldown impede novo ataque até terminar
- [ ] ArenaManager não contém mais timers de wind-up da Criatura

---

### 3.2 RF-302 — Telegraph Visual no Wind-Up

**Descrição:** Durante o estado WIND_UP da Criatura, feedback visual deve deixar claro para o jogador que um ataque está sendo preparado.

**Detalhes Técnicos:**
- Durante `State.WIND_UP`, `Criatura` executa um tween visual:
  ```gdscript
  var tween := create_tween()
  tween.tween_property(animated_sprite, "modulate", Color(1.2, 0.5, 0.5), 0.25)
  tween.tween_property(animated_sprite, "scale", Vector2(2.3, 2.3), 0.25)
  tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.25)
  tween.tween_property(animated_sprite, "scale", Vector2(2.0, 2.0), 0.25)
  ```
- O tween pulsa (flash vermelho + leve aumento de escala) enquanto o wind-up dura
- Ao final do wind-up, a Criatura "salta" em direção à Caipora (tween de `position.x` de 480 → 400 por 0.1s) e depois volta (400 → 480 por 0.1s) — simula o lunge do ataque
- O pulso de wind-up é interrompido se o estado muda antes do tempo (ex: Criatura morre)

**Critério de Aceitação:**
- [ ] Criatura pulsa em vermelho durante wind-up
- [ ] Criatura dá um lunge para a esquerda no início do ataque
- [ ] Efeito visual é claramente perceptível em 1280×720
- [ ] Efeito para imediatamente se Criatura morre durante wind-up

---

### 3.3 RF-303 — Boss com Pattern Diferente

**Descrição:** Criar uma segunda entidade de combate — um Boss — com um padrão de ataque mais desafiador.

**Artefatos:**
- `scripts/entities/boss.gd` (class_name Boss extends Criatura)
- `scenes/arena/boss.tscn`
- `resources/attack_patterns/boss_pattern.tres`

**Detalhes Técnicos:**
- `Boss extends Criatura` — herda StateMachine, CombatActor, etc.
- Sprite: reusar `enemy_idle.png` com `modulate` diferente (ex: `Color(0.8, 0.2, 0.2)` para um tom mais escuro/ameaçador) ou criar um novo SpriteFrames se houver outro sprite disponível
- Scale: `Vector2(3, 3)` em vez de `Vector2(2, 2)` — Boss é maior
- CollisionShape2D: 96×96
- `max_health = Constants.BOSS_MAX_HEALTH` (200)
- `base_attack_damage = 18`

**AttackPattern do Boss (Multi-Strike):**
```gdscript
# resources/attack_patterns/boss_pattern.tres
wind_up_duration = 0.3   # mais rápido
attack_duration = 0.8    # janela de defesa mais curta
cooldown_duration = 1.5
idle_duration = 0.2
damage_multiplier = 1.0
strike_count = 3         # NOVO: número de golpes consecutivos
strike_delay = 0.4       # NOVO: delay entre golpes
```

- O Boss executa **3 golpes consecutivos** com delay de 0.4s entre cada um
- Cada golpe abre uma janela de defesa separada (duration 0.8s)
- O jogador precisa esquivar **todos os 3** para contra-atacar (timing perfeito em qualquer um dos 3 = esquiva completa + contra-ataque após o último)
- Se errar qualquer um dos 3, recebe dano do golpe correspondente

**Modificação no EnemyStateMachine:**
- Suportar `strike_count > 1` — após `State.ATTACK`, se ainda houver strikes restantes, volta para `State.WIND_UP` em vez de `State.COOLDOWN`
- Contador `_strikes_remaining` decrementa a cada ATTACK completo

**Critério de Aceitação:**
- [ ] Boss spawna corretamente com sprite maior e mais escuro
- [ ] Boss executa 3 golpes consecutivos com wind-up entre cada um
- [ ] Cada golpe tem sua própria janela de defesa
- [ ] Esquivar todos os 3 dispara contra-ataque único após o último
- [ ] Errar qualquer golpe aplica dano normal e interrompe a sequência
- [ ] Boss morre quando vida chega a 0

---

### 3.4 RF-304 — Blood Particles Aprimoradas

**Descrição:** As partículas de impacto existentes são funcionais mas genéricas. Esta fase as torna viscerais e específicas para cada tipo de hit.

**Artefatos:**
- `scenes/shared/blood_particles.tscn` (substitui/estende impact_particles.tscn)
- `scenes/shared/critical_particles.tscn`
- Modificações em `scripts/systems/feedback_system.gd`

**Detalhes Técnicos:**
- **BloodParticles** (hit normal):
  - `amount = 20` (aumentado de 12)
  - `lifetime = 0.6`
  - `color = Constants.COLOR_BLOOD` (`#8b0000`)
  - `initial_velocity_min = 80.0`, `max = 180.0`
  - `scale_amount_min = 3.0`, `max = 6.0`
  - `direction = Vector2(0, 1)` (sangue cai para baixo, não sobe)
  - `gravity = Vector2(0, 300)` (sangue cai como gotas)

- **CriticalParticles** (hit crítico):
  - `amount = 35`
  - `lifetime = 0.8`
  - Cores variadas: vermelho escuro (`#8b0000`) + vermelho vivo (`#ff0000`) alternados via `color_ramp` (Gradient)
  - `initial_velocity_min = 120.0`, `max = 250.0`
  - `scale_amount_min = 4.0`, `max = 8.0`
  - `direction = Vector2(0, -1)` (explosão para cima)
  - `spread = 90.0`

- **DeathParticles**:
  - `amount = 60`
  - `lifetime = 1.2`
  - Cores: vermelho + âmbar + preto (Gradient de 3 cores)
  - `initial_velocity_min = 150.0`, `max = 400.0`
  - `scale_amount_min = 5.0`, `max = 12.0`
  - `explosiveness = 1.0`

- `FeedbackSystem` ganha métodos novos:
  ```gdscript
  func spawn_blood_particles(position: Vector2) -> void
  func spawn_critical_particles(position: Vector2) -> void
  func spawn_death_particles(position: Vector2) -> void
  ```

**Critério de Aceitação:**
- [ ] Hit normal spawna blood particles (20 gotas caindo)
- [ ] Crítico spawna critical particles (35 explosão para cima, cores variadas)
- [ ] Morte spawna death particles (60 explosão massiva)
- [ ] Partículas antigas (`impact_particles.tscn`) são substituídas ou descontinuadas
- [ ] Todas as partículas usam `CPUParticles2D`

---

### 3.5 RF-305 — Hit-Stop Frames

**Descrição:** Congelar o jogo brevemente no impacto de golpes significativos, criando um efeito de "peso" no combate.

**Artefatos:**
- Modificações em `scripts/systems/feedback_system.gd`

**Detalhes Técnicos:**
```gdscript
func trigger_hit_stop(frames: int = 3) -> void:
    Engine.time_scale = 0.0
    await get_tree().create_timer(frames / 60.0).timeout
    Engine.time_scale = 1.0
```

- Hit-stop é aplicado nos seguintes eventos:
  - Caipora crítico: 3 frames
  - Caipora contra-ataque: 4 frames
  - Criatura/Boss hit na Caipora: 2 frames
  - Morte de qualquer ator: 5 frames

- O `Engine.time_scale = 0.0` pausa TODO o jogo, incluindo tweens e timers. Por isso, o hit-stop deve ser aplicado ANTES do screenshake e partículas (que usam tweens).
- Alternativa: usar `get_tree().paused = true` com um Timer, mas isso requer `process_mode = PROCESS_ALWAYS` nos nós que devem continuar funcionando.
- **Decisão:** Usar `Engine.time_scale` pois é mais simples e não requer ajustar `process_mode` de múltiplos nós.

**Critério de Aceitação:**
- [ ] Hit-stop de 3 frames no crítico da Caipora
- [ ] Hit-stop de 4 frames no contra-ataque
- [ ] Hit-stop de 2 frames no hit da Criatura
- [ ] Hit-stop de 5 frames na morte
- [ ] Jogo retoma velocidade normal imediatamente após hit-stop
- [ ] Não há acumulação de hit-stops (se dois acontecerem em sequência, o segundo ignora o primeiro)

---

### 3.6 RF-306 — Death Animation

**Descrição:** Quando um ator morre, não deve simplesmente desaparecer. A morte deve ser um evento visual marcante.

**Artefatos:**
- Modificações em `scripts/entities/combat_actor.gd`
- Modificações em `scripts/arena/arena_manager.gd`

**Detalhes Técnicos:**
- Quando `HealthComponent.died` é emitido, o `CombatActor` inicia a death animation em vez de ser removido imediatamente:
  ```gdscript
  func _on_health_died() -> void:
      _is_dying = true
      var tween := create_tween()
      tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.05)  # flash branco
      tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 0), 0.5)  # fade out
      tween.tween_callback(queue_free)
  ```
- Durante a death animation, o ator não pode receber dano adicional nem atacar
- O ArenaManager detecta a morte via `health.died` (como já faz), mas agora aguarda a death animation terminar antes de trocar de tela:
  ```gdscript
  func _on_actor_died(actor: CombatActor) -> void:
      # Aguarda a death animation (0.55s = flash + fade)
      await get_tree().create_timer(0.6).timeout
      # ... resto da lógica de vitória/derrota
  ```
- Death particles são spawnadas no início da animação (no momento do flash branco)

**Critério de Aceitação:**
- [ ] Flash branco (1 frame) ao morrer
- [ ] Fade out em 0.5s após flash
- [ ] Partículas de morte spawnadas no início da animação
- [ ] Ator não recebe dano nem ataca durante death animation
- [ ] Tela de vitória/derrota só aparece após a animação completar
- [ ] `queue_free()` é chamado ao final do fade

---

### 3.7 RF-307 — SFX com jsfxr

**Descrição:** Gerar efeitos sonoros para cada ação significativa do combate.

**Artefatos:**
- `assets/audio/sfx/attack.wav`
- `assets/audio/sfx/hit.wav`
- `assets/audio/sfx/dodge.wav`
- `assets/audio/sfx/timing_perfect.wav`
- `assets/audio/sfx/death.wav`
- `assets/audio/sfx/ui_click.wav`
- `scripts/systems/sfx_system.gd` (class_name SfxSystem)

**Detalhes Técnicos:**
- **Geração de SFX:**
  - Ferramenta principal: **jsfxr** (https://sfxr.me/ ou equivalente CLI)
  - Fallback: script Python usando `wave` + `math` para gerar ondas básicas
  - Cada SFX deve ter < 100KB e < 0.5s de duração
  - Formato: `.wav` (mono, 22050Hz, 16-bit — compatível com Godot HTML5)

- **Especificações por SFX:**
  | SFX | Tipo de Som | Duração | Uso |
  |-----|-------------|---------|-----|
  | `attack.wav` | Whoosh / swipe curto | ~0.2s | Caipora inicia ataque (timing cue abre) |
  | `hit.wav` | Impacto seco / punch | ~0.15s | Dano aplicado (qualquer hit) |
  | `dodge.wav` | Whoosh rápido + silence | ~0.2s | Esquiva perfeita |
  | `timing_perfect.wav` | Ding / chime curto | ~0.15s | Timing perfeito (ataque ou defesa) |
  | `death.wav` | Rumble / growl descendente | ~0.4s | Morte de ator |
  | `ui_click.wav` | Click seco | ~0.05s | Interações de UI (reserva para Fase 4) |

- **SfxSystem:**
  ```gdscript
  class_name SfxSystem
  extends Node

  @export var attack_sound: AudioStream
  @export var hit_sound: AudioStream
  @export var dodge_sound: AudioStream
  @export var timing_perfect_sound: AudioStream
  @export var death_sound: AudioStream
  @export var ui_click_sound: AudioStream

  func play(sound: AudioStream) -> void:
      if sound == null:
          return
      var player := AudioStreamPlayer.new()
      player.stream = sound
      player.finished.connect(player.queue_free)
      add_child(player)
      player.play()
  ```
  - Usar `AudioStreamPlayer` (2D) em vez de `AudioStreamPlayer2D` — SFX de combate não precisam de spatialização
  - Cada som é reproduzido em um player descartável (`queue_free` após `finished`)

**Critério de Aceitação:**
- [ ] 6 arquivos `.wav` gerados e presentes em `assets/audio/sfx/`
- [ ] Cada arquivo < 100KB
- [ ] `SfxSystem` consegue reproduzir qualquer som sem erros
- [ ] Múltiplos sons podem tocar simultaneamente (ex: hit + timing_perfect)

---

### 3.8 RF-308 — Conectar SFX aos Eventos de Combate

**Descrição:** Integrar SfxSystem ao loop de combate para que cada ação tenha som correspondente.

**Artefatos:**
- `scenes/arena/arena.tscn` (adicionar SfxSystem como filho)
- Modificações em `scripts/arena/arena_manager.gd`
- Modificações em `scripts/systems/sfx_system.gd` (se necessário)

**Detalhes Técnicos:**
- Adicionar `SfxSystem` como nó filho da arena (ao lado de `FeedbackSystem` e `TimingSystem`)
- Conectar eventos de combate aos sons no `ArenaManager`:

| Evento | Som | Intensidade |
|--------|-----|-------------|
| Caipora `attack_ready` (timing cue abre) | `attack.wav` | volume padrão |
| Caipora crítico | `hit.wav` + `timing_perfect.wav` | hit em 1.0x, perfect em 0.8x |
| Caipora normal | `hit.wav` | volume padrão |
| Esquiva perfeita | `dodge.wav` + `timing_perfect.wav` | dodge em 1.0x, perfect em 0.8x |
| Criatura hit | `hit.wav` | volume padrão |
| Morte de ator | `death.wav` | volume padrão |

- Volume pode ser ajustado via `player.volume_db` (ex: -10dB para sons secundários)
- O `timing_perfect.wav` toca no momento exato do input de Espaço (PERFECT), não no impacto

**Critério de Aceitação:**
- [ ] Cada ação de combate emite o som correto
- [ ] Som de timing perfeito toca no frame do input, não no impacto
- [ ] Múltiplos sons podem sobrepor (ex: crítico = hit + perfect simultâneos)
- [ ] Nenhum som é emitido quando timing é miss (exceto hit.wav no impacto)
- [ ] Som de morte toca no início da death animation

---

## 4. Requisitos Não-Funcionais

| # | Requisito | Especificação |
|---|-----------|---------------|
| RNF-301 | **Performance** | Hit-stop com `Engine.time_scale` não deve causar stuttering. Partículas aumentadas (35-60) devem manter 60 FPS em HTML5. |
| RNF-302 | **SFX** | Todos os SFX em `.wav` mono, 22050Hz, < 100KB. Nenhum som > 0.5s. |
| RNF-303 | **Código** | StateMachine usa enum e match/case. Nenhum `if` encadeado para estados. `class_name` em todos os scripts novos. |
| RNF-304 | **Testes** | Pelo menos 1 teste GUT para StateMachine (transição idle → wind-up → attack). Pelo menos 1 teste para Boss (strike_count > 1). |
| RNF-305 | **Decoupling** | `ArenaManager` não conhece a lógica interna do StateMachine — apenas escuta sinais `attack_started` e `attack_finished`. |
| RNF-306 | **Extensibilidade** | `AttackPattern` como `Resource` permite criar novos patterns sem modificar código (apenas criar novos `.tres`). |

---

## 5. Especificações de Teste

### 5.1 Testes de Fumaça (Smoke Tests)

| # | Teste | Como executar |
|---|-------|---------------|
| ST-301 | Criatura transiciona autonomamente pelos 4 estados | Carregar arena, observar ciclo de estados via print ou debug |
| ST-302 | Telegraph visual (pulso vermelho) aparece no wind-up | Observar Criatura durante wind-up |
| ST-303 | Boss executa 3 golpes consecutivos | Spawnar Boss, esperar pattern completo |
| ST-304 | Hit-stop congela o jogo | Causar crítico, verificar se animações param brevemente |
| ST-305 | Death animation tem flash + fade | Matar Criatura, observar sequência visual |
| ST-306 | SFX tocam em eventos de combate | Realizar ações e verificar output de áudio |
| ST-307 | Critical particles têm mais partículas que blood normal | Comparar visualmente hits críticos e normais |

### 5.2 Testes Unitários (GUT)

```gdscript
# tests/unit/test_enemy_state_machine.gd
class_name TestEnemyStateMachine
extends GutTest

var _sm: EnemyStateMachine
var _pattern: AttackPattern

func before_each():
    _sm = EnemyStateMachine.new()
    _pattern = AttackPattern.new()
    _pattern.wind_up_duration = 0.1
    _pattern.attack_duration = 0.1
    _pattern.cooldown_duration = 0.1
    _pattern.idle_duration = 0.1
    add_child_autofree(_sm)
    _sm.start_pattern(_pattern)

func test_idle_to_windup_transition():
    var state: Array = [EnemyStateMachine.State.IDLE]
    _sm.state_changed.connect(func(s): state[0] = s)
    await get_tree().create_timer(0.15).timeout
    assert_eq(state[0], EnemyStateMachine.State.WIND_UP)

func test_full_cycle_idle_windup_attack_cooldown():
    var states: Array = []
    _sm.state_changed.connect(func(s): states.append(s))
    await get_tree().create_timer(0.45).timeout
    assert_eq(states.size(), 3)
    assert_eq(states[0], EnemyStateMachine.State.WIND_UP)
    assert_eq(states[1], EnemyStateMachine.State.ATTACK)
    assert_eq(states[2], EnemyStateMachine.State.COOLDOWN)
```

```gdscript
# tests/unit/test_boss_pattern.gd
class_name TestBossPattern
extends GutTest

func test_boss_has_strike_count():
    var pattern := AttackPattern.new()
    pattern.strike_count = 3
    pattern.strike_delay = 0.1
    assert_eq(pattern.strike_count, 3)
    assert_eq(pattern.strike_delay, 0.1)
```

---

## 6. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| `Engine.time_scale = 0` pausa tweens de partículas/screenshake | Média | Médio | Aplicar hit-stop ANTES de iniciar tweens de partículas/screenshake. Ou usar `get_tree().create_timer()` com `process_always = true`. |
| jsfxr não disponível via CLI para gerar SFX | Média | Médio | Fallback: script Python com `wave` + `math` para gerar ondas básicas (senoide, ruído, sawtooth). |
| `AudioStreamPlayer` em Godot 4 HTML5 pode ter latência | Baixa | Médio | Usar `AudioStreamPlayer` (não 2D). Pré-carregar streams via `preload()`. Testar no browser na Fase 5. |
| Boss com 3 golpes pode tornar o combate impossível | Baixa | Alto | Valores generosos: wind-up 0.3s, defesa 0.8s. Ajustar após playtest. |
| Death animation com `await` pode conflitar com troca de cena | Baixa | Médio | ArenaManager aguarda timer fixo (0.6s) antes de trocar tela. Timer é independente do tween do ator. |
| StateMachine pode entrar em loop infinito se states não forem tratados | Baixa | Alto | Usar match/case exhaustivo. Adicionar `assert` em estados desconhecidos. Testar todas as transições. |

---

## 7. Checklist de Entrega da Fase 3

- [ ] **RF-301:** StateMachine na Criatura com 4 estados (idle → wind-up → attack → cooldown)
- [ ] **RF-302:** Telegraph visual com pulso vermelho e lunge durante wind-up
- [ ] **RF-303:** Boss com pattern de 3 golpes consecutivos
- [ ] **RF-304:** Blood particles (20), critical particles (35), death particles (60)
- [ ] **RF-305:** Hit-stop frames (2-5 frames conforme evento)
- [ ] **RF-306:** Death animation com flash branco + fade out + particles
- [ ] **RF-307:** 6 arquivos SFX `.wav` gerados em `assets/audio/sfx/`
- [ ] **RF-308:** SfxSystem conectado a todos os eventos de combate
- [ ] **RNF-301:** 60 FPS mantido com novas partículas
- [ ] **RNF-303:** Static typing em todos os scripts novos
- [ ] **RNF-304:** Pelo menos 2 testes GUT novos (StateMachine + Boss)
- [ ] **ST-301 a ST-307:** Smoke tests passam
- [ ] **Commit:** `git commit -m "fase-3: enemy AI, state machine, boss, hit-stop, SFX"`
- [ ] **ROADMAP:** Marcar tasks da Fase 3 como ✅ Done

---

## 8. Notas para o Agente

### Ordem de Implementação Recomendada

1. **RF-301 (StateMachine + AttackPattern)** — base para todo o resto
2. **RF-302 (Telegraph visual)** — dá vida à Criatura
3. **RF-304 (Particles aprimoradas)** — substitui partículas antigas
4. **RF-305 (Hit-stop)** — feedback visceral
5. **RF-306 (Death animation)** — evento de morte
6. **RF-307 (SFX)** — geração de arquivos de áudio
7. **RF-308 (Conectar SFX)** — integração no combate
8. **RF-303 (Boss)** — último, pois depende de StateMachine e AttackPattern

### Anti-Padrões a Evitar

- ❌ Não fazer ArenaManager controlar estados da Criatura diretamente — use sinais
- ❌ Não usar `get_tree().paused` para hit-stop — use `Engine.time_scale`
- ❌ Não gerar SFX em formatos pesados (OGG, MP3) — use WAV mono 22050Hz
- ❌ Não esquecer de liberar `AudioStreamPlayer` após tocar — conectar `finished` → `queue_free`
- ❌ Não hardcodear parâmetros de Boss — usar `@export` e `AttackPattern` resource
- ❌ Não remover ator imediatamente na morte — aguardar death animation

### Padrões a Seguir

- ✅ `AttackPattern` como `Resource` (não Node) — pode ser salvo como `.tres` e reusado
- ✅ StateMachine com `enum State` e `match/case` — legível e robusto
- ✅ `class_name` em `EnemyStateMachine`, `AttackPattern`, `Boss`, `SfxSystem`
- ✅ Sinais para comunicação entre StateMachine e ArenaManager (`attack_started`, `attack_finished`)
- ✅ `@export` em todos os parâmetros de tuning (durações, volumes, intensidades)

---

## 9. Decisões Arquiteturais Específicas

### 9.1 AttackPattern como Resource

**Decisão:** `AttackPattern` é um `Resource` (`extends Resource`), não um `Node`.

**Por quê:**
- Resources podem ser salvos como arquivos `.tres` e editados no inspector do Godot
- Permite criar múltiplos patterns (Criatura padrão, Boss, futuros inimigos) sem código
- Pode ser passado como parâmetro para `StateMachine.start_pattern(pattern)`
- Não precisa estar na árvore de cena — é um dado puro

### 9.2 StateMachine na Criatura vs. no ArenaManager

**Decisão:** StateMachine é um nó filho de `Criatura`, não do `ArenaManager`.

**Por quê:**
- A Criatura é a entidade que decide quando atacar. O ArenaManager apenas reage.
- Desacopla a lógica de IA do gerenciamento de arena
- Permite que diferentes inimigos (Criatura, Boss) tenham StateMachines independentes
- O ArenaManager escuta sinais (`attack_started`, `attack_finished`) em vez de controlar timers

### 9.3 Hit-Stop via Engine.time_scale

**Decisão:** Usar `Engine.time_scale = 0.0` por N/60 segundos.

**Por quê:**
- É o método mais simples e confiável para congelar TODO o jogo por frames exatos
- `get_tree().paused = true` requer configurar `process_mode = PROCESS_ALWAYS` em nós que devem continuar (timers, tweens de UI)
- `Engine.time_scale` afeta tudo uniformemente sem exceções
- O efeito é imediatamente perceptível e satisfatório

### 9.4 SFX via AudioStreamPlayer Descartável

**Decisão:** Criar `AudioStreamPlayer` temporário para cada som, liberando após `finished`.

**Por quê:**
- Permite múltiplos sons simultâneos sem precisar de pool de players
- Cada som é independente — não há risco de um som interromper outro
- Em Godot 4, `AudioStreamPlayer` com `stream = preload(...)` tem overhead mínimo
- Para HTML5, manter o número de players simultâneos baixo (< 8) é seguro

---

## 10. Referências Cruzadas

| Documento | Seções Relevantes |
|-----------|-------------------|
| `PLAN.md` | 4.2 (Sistemas Core), 4.3 (Estrutura de Entidades com AttackPattern), 7.2 (Padrões de Scene Tree) |
| `AGENTS.md` | Scene Architecture, Code Standards, Session Protocol |
| `PRD-fase-2.md` | RF-205 (CombatActor), RF-208/209 (dano e esquiva), RF-210 (FeedbackSystem) |
| `REPORT-fase-2.md` | Estado de saída da Fase 2, decisões arquiteturais aplicadas |
| `ROADMAP.md` | Fase 3: Enemy AI & Visceral Feedback |
