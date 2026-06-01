# PRD — Fase 2: Arena & Timing

> **caipora** — Brazilian Folk Horror Roguelike  
> **Fase:** 2 / 5  
> **Status:** 📝 Revisado (pronto para execução)  
> **Document Version:** 1.0  
> **Depende de:** [PRD-fase-1.md](./PRD-fase-1.md) (Grid & Exploration)  

---

## 1. Visão Geral

A Fase 2 introduz o coração do combate de **caipora**: a **Arena de Timing**. Quando a Caipora pisa no tile de arena_trigger, ela é arrastada para uma clareira queimada onde uma Criatura a espera. Aqui, o grid dá lugar à ação em tempo real — e ao ritmo mortal do **Espaço**.

O jogador não ataca automaticamente. Ele deve **sentir** o momento. Pressionar Espaço no frame correto desfere um golpe devastador (crítico). Pressionar Espaço no momento certo durante o ataque da Criatura permite esquivar e contra-atacar. Errar o timing não puni — mas acertar é sangue e glória.

**Tom:** A floresta parou de respirar. Não há mais escuridão para se esconder. É a Caipora contra a Criatura, e o único som é o coração batendo nos ouvidos.

**Filosofia:** *"Timing não é precisão. Timing é instinto. O jogador não deve ler frames — ele deve sentir a janela."*

---

## 2. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Arena Visceral** | Cena de arena carrega com background, Caipora e Criatura posicionados |
| 2 | **Timing Attack** | Pressionar Espaço na janela de ataque da Caipora = dano crítico (2x–3x) |
| 3 | **Timing Dodge** | Pressionar Espaço na janela de defesa = 0 dano + contra-ataque |
| 4 | **Vida e Morte** | HealthComponent aplica dano, detecta morte, emite sinal |
| 5 | **Feedback Brutal** | Screenshake, partículas de impacto e hit-stop tornam cada ação satisfatória |
| 6 | **Transição Funcional** | `SignalBus.arena_entered` carrega a arena e spawna os atores corretamente |

---

## 3. Requisitos Funcionais

### 3.1 RF-201 — Cena Arena

**Descrição:** Criar a cena de combate que será carregada ao pisar no tile de arena_trigger.

**Estrutura da Scene Tree:**
```
Arena (Node2D)
├── Background (ColorRect ou TileMap) — fundo escuro da clareira
├── CaiporaCombat (CharacterBody2D) — instância de scenes/arena/caipora_combat.tscn
├── Criatura (CharacterBody2D) — instância de scenes/arena/criatura.tscn
├── ArenaManager (Node2D) — script que gerencia o combate
├── TimingCueUI (CanvasLayer) — barra/círculo de timing
└── FeedbackSystem (Node) — screenshake + partículas
```

**Artefatos:**
- `scenes/arena/arena.tscn`
- `scripts/arena/arena_manager.gd`

**Detalhes Técnicos:**
- Root é `Node2D` com script `ArenaManager` anexado diretamente ao root
- `ArenaManager` gerencia o estado da arena: spawn de atores, fases de combate, condições de vitória/derrota
- Background: `ColorRect` cobrindo a viewport com `color = Constants.COLOR_ARENA_BG` (`#1a0f0f`, marrom-negro queimado) ou TileMap simples com floor escuro
- Tamanho da arena: 640×480 pixels (mesmo da exploração, para consistência visual)
- Posição inicial da Caipora: `(160, 240)` (esquerda, centro)
- Posição inicial da Criatura: `(480, 240)` (direita, centro)
- Registra `SignalBus.combat_ended` e chama `GameState.change_screen(SignalBus.Screen.HUB)` ou `Screen.GAME_OVER`

**Critério de Aceitação:**
- [ ] Cena abre sem erros no Godot (F5)
- [ ] Hierarquia segue a estrutura acima
- [ ] Caipora e Criatura aparecem nas posições corretas
- [ ] Background preenche toda a viewport

---

### 3.2 RF-202 — Spawn na Arena via ArenaManager

**Descrição:** `ArenaManager` instancia Caipora e Criatura ao entrar na arena, carregando-os nas posições designadas.

**Detalhes Técnicos:**
- `ArenaManager` tem exports:
  ```gdscript
  @export var caipora_combat_scene: PackedScene
  @export var criatura_scene: PackedScene
  ```
- Em `_ready()`:
  ```gdscript
  func _ready() -> void:
      _spawn_caipora()
      _spawn_criatura()
      _start_combat()
  ```
- `_spawn_caipora()` instancia `caipora_combat_scene` em `(160, 240)`, adiciona como child
- `_spawn_criatura()` instancia `criatura_scene` em `(480, 240)`, adiciona como child
- Conecta sinais: `CombatActor.died` de ambos os atores para `_on_actor_died(actor)`
- `ArenaManager` armazena referências: `@onready var _caipora: CombatActor` e `@onready var _criatura: CombatActor`

**Critério de Aceitação:**
- [ ] Caipora spawna na posição (160, 240)
- [ ] Criatura spawna na posição (480, 240)
- [ ] Ambos são instâncias de suas respectivas cenas PackedScene
- [ ] `ArenaManager` pode acessar ambos via referência cacheada

---

### 3.3 RF-203 — Cena Criatura (Inimigo)

**Descrição:** Entidade inimiga com sprite, collision e componentes de combate.

**Estrutura da Scene Tree:**
```
Criatura (CharacterBody2D)
├── AnimatedSprite2D — SpriteFrames com idle
├── CollisionShape2D — RectangleShape2D 32×32
├── CombatActor (script) — vida, dano, timing
└── FeedbackReceiver (script) — reage a hits
```

**Artefatos:**
- `scenes/arena/criatura.tscn`
- `scripts/entities/criatura.gd`

**Detalhes Técnicos:**
- `class_name Criatura extends CharacterBody2D`
- `collision_layer = Constants.LAYER_ENEMY`
- `collision_mask = Constants.LAYER_PLAYER` (para detecção de proximidade futura)
- `AnimatedSprite2D` com `SpriteFrames` resource contendo:
  - `idle`: 1 frame (`enemy_idle.png`), loop
- Sprite scale: `Vector2(2, 2)` para manter consistência visual com a Caipora
- `CombatActor` é um nó filho (Node) ou o próprio script da Criatura — ver decisão arquitetural

**Critério de Aceitação:**
- [ ] Cena instanciável sem erros
- [ ] AnimatedSprite2D visível e pixel-perfect (Nearest filter)
- [ ] CollisionShape2D cobre o sprite escalado (64×64 se scale=2)
- [ ] Layer/mask configurados via `Constants`

---

### 3.4 RF-204 — HealthComponent

**Descrição:** Componente reutilizável de vida, dano e morte. Usado tanto pela Caipora quanto pela Criatura.

**Artefatos:**
- `scripts/shared/health_component.gd`

**Detalhes Técnicos:**
```gdscript
class_name HealthComponent
extends Node

signal health_changed(new_health: int, max_health: int)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health = clampi(current_health - amount, 0, max_health)
    health_changed.emit(current_health, max_health)
    if current_health <= 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = clampi(current_health + amount, 0, max_health)
    health_changed.emit(current_health, max_health)

func is_alive() -> bool:
    return current_health > 0
```
- Anexado como nó filho de qualquer `CombatActor`
- `CombatActor` expõe via `@onready var health: HealthComponent = $HealthComponent`

**Valores Iniciais (MVP):**
- Caipora: `max_health = 100`
- Criatura: `max_health = 80`

**Critério de Aceitação:**
- [ ] `take_damage` reduz vida e emite `health_changed`
- [ ] `take_damage` que leva a 0 emite `died`
- [ ] `heal` aumenta vida até o max
- [ ] `is_alive` retorna false quando vida = 0
- [ ] Componente é reutilizável (funciona em Caipora e Criatura)

---

### 3.5 RF-205 — CombatActor (Base para Caipora e Criatura)

**Descrição:** Classe base que combina movimento (CharacterBody2D), HealthComponent e lógica de timing. Usada tanto pela Caipora quanto pela Criatura na arena.

**Artefatos:**
- `scripts/entities/combat_actor.gd`

**Detalhes Técnicos:**
```gdscript
class_name CombatActor
extends CharacterBody2D

signal attack_ready
signal attack_executed(damage: int, is_critical: bool)
signal dodge_performed

@onready var health: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var base_attack_damage: int = 10
@export var attack_cooldown: float = 2.0
@export var critical_multiplier: float = 2.5

var _attack_timer: Timer
var _can_attack: bool = true

func _ready() -> void:
    _attack_timer = Timer.new()
    _attack_timer.one_shot = true
    _attack_timer.wait_time = attack_cooldown
    _attack_timer.timeout.connect(_on_attack_cooldown_ready)
    add_child(_attack_timer)

func start_attack_window() -> void:
    # Será sobrescrito ou expandido pelo TimingSystem
    pass

func execute_attack(is_critical: bool = false) -> void:
    var damage := base_attack_damage
    if is_critical:
        damage = int(damage * critical_multiplier)
    attack_executed.emit(damage, is_critical)
    _can_attack = false
    _attack_timer.start()

func _on_attack_cooldown_ready() -> void:
    _can_attack = true
    attack_ready.emit()

func take_damage(amount: int) -> void:
    health.take_damage(amount)
```
- `CombatActor` é a classe base. Caipora e Criatura herdam dela.
- `health` é um nó filho `HealthComponent`
- `attack_cooldown` controla o ritmo do combate
- `attack_ready` sinaliza que o ator pode iniciar uma nova janela de timing

**Critério de Aceitação:**
- [ ] `CombatActor` é `class_name` e estende `CharacterBody2D`
- [ ] `health` é acessível e funcional
- [ ] `execute_attack` calcula dano crítico corretamente
- [ ] Cooldown impede ataques em cadeia
- [ ] `attack_ready` emite após cooldown

---

### 3.6 RF-206 — TimingCue UI

**Descrição:** Interface visual que mostra a janela de timing ao jogador — um indicador que aparece quando é hora de pressionar Espaço.

**Artefatos:**
- `scenes/ui/timing_cue.tscn`
- `scripts/ui/timing_cue.gd`

**Estrutura da Scene Tree:**
```
TimingCue (CanvasLayer)
└── CueContainer (CenterContainer)
    └── CueBar (TextureProgressBar ou ColorRect)
```

**Detalhes Técnicos:**
- `CanvasLayer` para renderizar sobre a arena
- `CueContainer` centralizado na tela (ou posicionado próximo ao ator atacante)
- **Abordagem 1 (TextureProgressBar):**
  - Usar `TextureProgressBar` (Godot 4 UI)
  - `fill_mode = FILL_LEFT_TO_RIGHT`
  - `tint_progress = Constants.COLOR_TIMING_HIT` (`#ff6b00`, âmbar)
  - `tint_under = Constants.COLOR_TIMING_BG` (`#3d1f1f`, marrom escuro)
  - Tamanho: 200×20 pixels
- **Abordagem 2 (ColorRect + Tween):**
  - Dois `ColorRect` sobrepostos: fundo escuro + barra de progresso
  - Barra encolhe via tween de 200px → 0px em `timing_window_duration`
- A janela de acerto é uma zona no centro da barra (ex: 30% do comprimento)
- A cue aparece quando o ator está pronto para atacar e desaparece após o input ou timeout

**Valores de Timing (MVP — generosos):**
- `timing_window_duration := 1.5` segundos (tempo total da barra)
- `perfect_window_ratio := 0.3` (30% do centro da barra = acerto perfeito)
- `good_window_ratio := 0.6` (60% do centro = acerto bom, dano normal)
- Fora dessas zonas = miss (ataque normal, sem bônus, sem penalidade)

**Critério de Aceitação:**
- [ ] Cue aparece quando `CombatActor` emite `attack_ready`
- [ ] Barra encolhe ou preenche ao longo do tempo
- [ ] Zona de acerto é visualmente distinta (cor diferente ou marcação)
- [ ] Cue desaparece após input de Espaço ou timeout
- [ ] Cue funciona tanto para ataque da Caipora quanto para defesa contra Criatura

---

### 3.7 RF-207 — Detecção de Timing (Press Espaço)

**Descrição:** Sistema que detecta se o jogador pressionou Espaço dentro da janela de timing e classifica o resultado.

**Artefatos:**
- `scripts/systems/timing_system.gd`

**Detalhes Técnicos:**
```gdscript
class_name TimingSystem
extends Node

enum TimingResult { PERFECT, GOOD, MISS }

signal timing_result(result: TimingResult)

var _is_window_open: bool = false
var _window_progress: float = 0.0  # 0.0 a 1.0
var _window_duration: float = 1.5
var _perfect_start: float = 0.35
var _perfect_end: float = 0.65

func open_window(duration: float = 1.5) -> void:
    _is_window_open = true
    _window_duration = duration
    _window_progress = 0.0

func close_window() -> void:
    _is_window_open = false

func _process(delta: float) -> void:
    if _is_window_open:
        _window_progress += delta / _window_duration
        if _window_progress >= 1.0:
            _is_window_open = false
            timing_result.emit(TimingResult.MISS)

func _input(event: InputEvent) -> void:
    if not _is_window_open:
        return
    if event.is_action_pressed("ui_accept"):  # Espaço
        _evaluate_timing()

func _evaluate_timing() -> void:
    _is_window_open = false
    if _window_progress >= _perfect_start and _window_progress <= _perfect_end:
        timing_result.emit(TimingResult.PERFECT)
    else:
        timing_result.emit(TimingResult.MISS)
```
- `TimingSystem` é um nó autônomo (não autoload, mas instanciado na arena)
- `ArenaManager` conecta `CombatActor.attack_ready` → `TimingSystem.open_window()`
- `TimingSystem.timing_result` → `ArenaManager._on_timing_result(result)`
- Usa `ui_accept` (Espaço por padrão no Godot) — **não criar ação customizada**

**Critério de Aceitação:**
- [ ] Espaço detectado apenas quando `_is_window_open = true`
- [ ] `PERFECT` emitido quando progresso está entre 35% e 65%
- [ ] `MISS` emitido quando progresso está fora da zona ou timeout ocorre
- [ ] Janela fecha imediatamente após o primeiro input válido
- [ ] Não processa múltiplos presses no mesmo frame

---

### 3.8 RF-208 — Ataque Crítico no Timing de Ataque

**Descrição:** Quando é a vez da Caipora atacar, o jogador pressiona Espaço na janela de timing. Acerto perfeito = dano crítico (2.5x). Miss = dano normal.

**Fluxo:**
```
1. CaiporaCombat.attack_ready.emit()
2. ArenaManager abre TimingCue + TimingSystem
3. Jogador pressiona Espaço
4. TimingSystem emite PERFECT ou MISS
5. ArenaManager chama:
   - PERFECT: caipora.execute_attack(true) → dano * 2.5
   - MISS: caipora.execute_attack(false) → dano base
6. Dano aplicado à Criatura via criatura.take_damage(damage)
7. FeedbackSystem dispara screenshake + partículas
```

**Detalhes Técnicos:**
- Dano base da Caipora: `base_attack_damage = 15`
- Multiplicador crítico: `critical_multiplier = 2.5`
- Dano crítico: `15 * 2.5 = 37` (arredondado para int)
- Dano normal: `15`
- Cooldown entre ataques da Caipora: `attack_cooldown = 2.0s`

**Critério de Aceitação:**
- [ ] Timing perfeito aplica dano crítico (37)
- [ ] Timing miss aplica dano normal (15)
- [ ] Criatura perde vida corretamente
- [ ] Criatura emite `died` quando vida chega a 0
- [ ] Cooldown impede spam de ataques

---

### 3.9 RF-209 — Esquiva Perfeita + Contra-Ataque no Timing de Defesa

**Descrição:** Quando a Criatura ataca, o jogador tem uma janela de timing para esquivar. Acerto perfeito = 0 dano + contra-ataque imediato. Miss = dano normal da Criatura.

**Fluxo:**
```
1. Criatura inicia ataque (wind-up visual de 0.5s)
2. Criatura emite attack_ready → ArenaManager abre TimingCue + TimingSystem
3. Jogador pressiona Espaço
4. TimingSystem emite PERFECT ou MISS
5. ArenaManager:
   - PERFECT: caipora.dodge_performed.emit() → 0 dano → caipora.execute_attack(true) contra criatura
   - MISS: caipora.take_damage(criatura.base_attack_damage)
6. FeedbackSystem dispara screenshake + partículas
```

**Detalhes Técnicos:**
- Dano base da Criatura: `base_attack_damage = 12`
- Wind-up da Criatura: `0.5s` de animação antes da janela de timing abrir
- Contra-ataque usa o mesmo dano base da Caipora (15) mas com bônus de `1.5x` (22 de dano)
- A janela de defesa é **mais curta** que a de ataque: `timing_window_duration = 1.0s`
- A zona perfeita é **mais estreita**: `_perfect_start = 0.4`, `_perfect_end = 0.6` (20% da barra)

**Critério de Aceitação:**
- [ ] Esquiva perfeita evita TODO o dano da Criatura
- [ ] Esquiva perfeita dispara contra-ataque automático
- [ ] Miss aplica dano normal da Criatura à Caipora
- [ ] Wind-up visual da Criatura precede a janela de timing
- [ ] Caipora emite `died` quando vida chega a 0

---

### 3.10 RF-210 — Screenshake e Partículas de Impacto

**Descrição:** Feedback visceral para cada ação significativa no combate.

**Artefatos:**
- `scripts/systems/feedback_system.gd`
- `scenes/shared/impact_particles.tscn`

**Estrutura — FeedbackSystem:**
```gdscript
class_name FeedbackSystem
extends Node

@export var shake_intensity: float = 8.0
@export var shake_duration: float = 0.3

func trigger_screenshake(intensity: float = shake_intensity, duration: float = shake_duration) -> void:
    var camera := get_viewport().get_camera_2d()
    if camera == null:
        return
    var tween := create_tween()
    tween.tween_method(_shake_camera.bind(camera), intensity, 0.0, duration)

func _shake_camera(amount: float, camera: Camera2D) -> void:
    camera.offset = Vector2(
        randf_range(-amount, amount),
        randf_range(-amount, amount)
    )
```

**Estrutura — ImpactParticles:**
- `CPUParticles2D` (mais leve que GPUParticles2D para HTML5)
- Configuração:
  - `emitting = false` (ativa via `restart()`)
  - `amount = 12`
  - `lifetime = 0.4`
  - `one_shot = true`
  - `explosiveness = 0.9`
  - `direction = Vector2(0, -1)`
  - `spread = 60.0`
  - `initial_velocity_min = 50.0`
  - `initial_velocity_max = 120.0`
  - `scale_amount_min = 2.0`
  - `scale_amount_max = 4.0`
  - `color = Constants.COLOR_BLOOD` (`#8b0000`)

**Eventos que disparam feedback:**
| Evento | Screenshake | Partículas | Intensidade |
|--------|-------------|------------|-------------|
| Caipora crítico | ✅ | ✅ (na Criatura) | 12.0 / 0.4s |
| Caipora normal | ✅ | ✅ (na Criatura) | 5.0 / 0.2s |
| Criatura hit (Caipora miss defesa) | ✅ | ✅ (na Caipora) | 8.0 / 0.3s |
| Caipora esquiva + contra | ✅ | ✅ (na Criatura) | 10.0 / 0.35s |
| Morte de ator | ✅ | ✅ (explosão) | 20.0 / 0.6s |

**Critério de Aceitação:**
- [ ] Screenshake funciona em todos os eventos listados
- [ ] Partículas de sangue aparecem no alvo do dano
- [ ] Intensidade varia conforme a tabela
- [ ] Partículas usam `CPUParticles2D` (não GPU)
- [ ] Câmera retorna à posição original após o shake

---

## 4. Requisitos Não-Funcionais

| # | Requisito | Especificação |
|---|-----------|---------------|
| RNF-201 | **Performance** | Arena deve manter 60 FPS em HTML5. Nenhum `_process` pesado. TimingSystem usa `_input` + `_process` leve. |
| RNF-202 | **Input** | Usar `ui_accept` (Espaço) para timing. Não criar ação customizada. |
| RNF-203 | **Código** | Todo script com `class_name`, `extends`, static typing. `CombatActor` como classe base reutilizável. |
| RNF-204 | **Testes** | Pelo menos 2 testes GUT: (1) timing perfeito aplica dano crítico, (2) timing miss aplica dano normal. |
| RNF-205 | **Decoupling** | `ArenaManager` não referencia `ExplorationManager`. Comunicação via `SignalBus`. `TimingSystem` não conhece `CombatActor` diretamente — conectado via sinais pelo `ArenaManager`. |
| RNF-206 | **Feedback** | Screenshake e partículas devem ser configuráveis (intensidade/duração via `@export`) para tuning futuro. |

---

## 5. Especificações de Teste

### 5.1 Testes de Fumaça (Smoke Tests)

| # | Teste | Como executar |
|---|-------|---------------|
| ST-201 | Arena carrega ao emitir `SignalBus.arena_entered` | Triggerar sinal manualmente ou via exploration, verificar cena carregada |
| ST-202 | Caipora e Criatura spawnam nas posições corretas | Inspecionar posições após carregar arena |
| ST-203 | Pressionar Espaço na janela de timing registra acerto | Abrir arena, esperar cue, pressionar Espaço no momento certo, verificar dano crítico |
| ST-204 | Pressionar Espaço fora da janela registra miss | Pressionar Espaço muito cedo ou muito tarde, verificar dano normal |
| ST-205 | Screenshake ocorre no hit | Causar dano, verificar offset da câmera |
| ST-206 | Partículas aparecem no alvo | Causar dano, verificar se `CPUParticles2D` emite |
| ST-207 | Morte da Criatura dispara `combat_ended` | Reduzir vida da Criatura a 0, verificar sinal |
| ST-208 | Morte da Caipora dispara `combat_ended` | Reduzir vida da Caipora a 0, verificar sinal |

### 5.2 Testes Unitários (GUT)

```gdscript
# tests/unit/test_timing_system.gd
class_name TestTimingSystem
extends GutTest

var _timing: TimingSystem

func before_each():
    _timing = TimingSystem.new()
    add_child_autofree(_timing)

func test_perfect_timing_within_window():
    var result: TimingSystem.TimingResult = TimingSystem.TimingResult.MISS
    _timing.timing_result.connect(func(r): result = r)
    _timing.open_window(1.0)
    # Simular progresso no centro da janela (50%)
    _timing._window_progress = 0.5
    _timing._evaluate_timing()
    assert_eq(result, TimingSystem.TimingResult.PERFECT)

func test_miss_timing_outside_window():
    var result: TimingSystem.TimingResult = TimingSystem.TimingResult.PERFECT
    _timing.timing_result.connect(func(r): result = r)
    _timing.open_window(1.0)
    # Simular progresso no início (10% — fora da zona perfeita)
    _timing._window_progress = 0.1
    _timing._evaluate_timing()
    assert_eq(result, TimingSystem.TimingResult.MISS)

func test_miss_on_timeout():
    var result: TimingSystem.TimingResult = TimingSystem.TimingResult.PERFECT
    _timing.timing_result.connect(func(r): result = r)
    _timing.open_window(0.1)
    await get_tree().create_timer(0.15).timeout
    assert_eq(result, TimingSystem.TimingResult.MISS)
```

```gdscript
# tests/unit/test_combat_actor.gd
class_name TestCombatActor
extends GutTest

var _actor: CombatActor

func before_each():
    _actor = CombatActor.new()
    var health := HealthComponent.new()
    health.max_health = 100
    _actor.add_child(health)
    add_child_autofree(_actor)

func test_critical_damage_multiplier():
    _actor.base_attack_damage = 10
    _actor.critical_multiplier = 2.5
    var received_damage: int = 0
    _actor.attack_executed.connect(func(d, _is_crit): received_damage = d)
    _actor.execute_attack(true)
    assert_eq(received_damage, 25)

func test_normal_damage_without_critical():
    _actor.base_attack_damage = 10
    var received_damage: int = 0
    _actor.attack_executed.connect(func(d, _is_crit): received_damage = d)
    _actor.execute_attack(false)
    assert_eq(received_damage, 10)

func test_death_signal_emitted():
    var died := false
    _actor.health.died.connect(func(): died = true)
    _actor.take_damage(100)
    assert_true(died)
```

---

## 6. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| `ui_accept` conflita com outros usos de Espaço | Baixa | Médio | Isolar input de timing via `_input` no `TimingSystem` com flag `_is_window_open`. Não processar Espaço fora das janelas. |
| TimingCue não é legível em HTML5 / baixa resolução | Baixa | Médio | Usar cores de alto contraste (âmbar `#ff6b00` sobre marrom `#3d1f1f`). Testar em 1280×720 e 640×480. |
| `CPUParticles2D` performance ruim com muitas emissões simultâneas | Baixa | Médio | Limitar `amount` a 12 por emissão. Usar `one_shot = true`. Não manter partículas ativas entre frames. |
| CombatActor como classe base pode ficar inchada | Média | Médio | Manter `CombatActor` enxuto — apenas vida, dano, cooldown e sinais. Timing e IA ficam em sistemas externos (`TimingSystem`, `AttackPattern` na Fase 3). |
| Tween de screenshake conflita com Camera2D smoothing | Baixa | Baixo | Screenshake modifica `offset`, não `position`. Camera2D smoothing atua em `position`. São propriedades independentes. |

---

## 7. Checklist de Entrega da Fase 2

- [ ] **RF-201:** Cena Arena criada e funcional
- [ ] **RF-202:** ArenaManager spawna Caipora e Criatura corretamente
- [ ] **RF-203:** Cena Criatura com sprite, collision e layer/mask
- [ ] **RF-204:** HealthComponent funcional e reutilizável
- [ ] **RF-205:** CombatActor como classe base para Caipora e Criatura
- [ ] **RF-206:** TimingCue UI aparece, encolhe e desaparece
- [ ] **RF-207:** TimingSystem detecta Espaço e classifica PERFECT/MISS
- [ ] **RF-208:** Ataque crítico aplica 2.5x de dano no timing perfeito
- [ ] **RF-209:** Esquiva perfeita evita dano e dispara contra-ataque
- [ ] **RF-210:** Screenshake e partículas funcionam em todos os eventos de combate
- [ ] **RNF-201:** 60 FPS mantido em HTML5
- [ ] **RNF-203:** Static typing em todos os scripts
- [ ] **RNF-204:** Pelo menos 2 testes GUT para timing + 2 para combat actor
- [ ] **ST-201 a ST-208:** Smoke tests passam
- [ ] **Commit:** `git commit -m "fase-2: arena & timing — combat, cues, screenshake"`
- [ ] **ROADMAP:** Marcar tasks da Fase 2 como ✅ Done

---

## 8. Notas para o Agente

### Ordem de Implementação Recomendada

1. **RF-204 (HealthComponent)** — base para todos os atores de combate
2. **RF-205 (CombatActor)** — classe base que usa HealthComponent
3. **RF-203 (Criatura cena)** — primeiro ator concreto
4. **RF-201 + RF-202 (Arena + ArenaManager)** — cena que junta tudo
5. **RF-206 (TimingCue UI)** — visual do timing
6. **RF-207 (TimingSystem)** — lógica de detecção
7. **RF-208 + RF-209 (Ataque crítico + Esquiva)** — conecta timing ao dano
8. **RF-210 (Feedback)** — screenshake e partículas

### Anti-Padrões a Evitar

- ❌ Não criar ação de input customizada para Espaço — usar `ui_accept`
- ❌ Não hardcodear dano, multiplicador ou cooldown — usar `@export` e `Constants`
- ❌ Não fazer `ArenaManager` depender de `ExplorationManager` — comunicação só via `SignalBus`
- ❌ Não usar `GPUParticles2D` — usar `CPUParticles2D` para compatibilidade HTML5
- ❌ Não acoplar `TimingSystem` diretamente a `CombatActor` — `ArenaManager` faz o wiring
- ❌ Não esquecer de resetar `Camera2D.offset` após screenshake

### Padrões a Seguir

- ✅ `class_name` em `HealthComponent`, `CombatActor`, `TimingSystem`, `FeedbackSystem`
- ✅ Composição: `HealthComponent` como nó filho, não herança
- ✅ Signals para comunicação: `health_changed`, `died`, `attack_executed`, `timing_result`
- ✅ `@export` para tuning: dano, cooldown, intensidade de shake, duração de janela
- ✅ `await get_tree().create_timer(x).timeout` em testes GUT quando houver timers/tweens

---

## 9. Decisões Arquiteturais Específicas

### 9.1 CombatActor: Herança vs. Composição

**Decisão:** `CombatActor` é uma classe base (`extends CharacterBody2D`) que contém `HealthComponent` como nó filho (composição).

**Por quê:**
- `CharacterBody2D` é necessário para posicionamento 2D, animação e potencial movimento futuro
- `HealthComponent` como nó filho permite reutilização e testabilidade isolada
- Não queremos herança profunda — `Caipora` e `Criatura` herdam de `CombatActor`, e pronto
- Timing e padrões de ataque ficam fora de `CombatActor` (em `TimingSystem` e futuro `AttackPattern`), evitando god class

### 9.2 TimingSystem: Nó Instanciado vs. Autoload

**Decisão:** `TimingSystem` é instanciado como nó filho de `ArenaManager`, não autoload.

**Por quê:**
- Timing é específico da arena de combate. Não existe fora dela.
- Autoload seria overkill e poluiria o escopo global.
- Instância por arena permite múltiplas arenas simultâneas no futuro (modo desafio, etc).

### 9.3 FeedbackSystem: Métodos Estáticos vs. Instância

**Decisão:** `FeedbackSystem` é um nó comum (não autoload nesta fase) — `ArenaManager` o instancia.

**Por quê:**
- Na Fase 3, `FeedbackSystem` pode virar autoload para reagir a eventos globais (meta-progressão, menus, etc).
- Nesta fase, feedback é local à arena. Manter local reduz acoplamento.
- Se necessário na Fase 3, a migração para autoload é trivial.

### 9.4 Timing Cue: TextureProgressBar vs. Tween Manual

**Decisão:** Usar `TextureProgressBar` como base, com tween no `value`.

**Por quê:**
- `TextureProgressBar` já tem fill modes, tints e anchoring nativos do Godot UI
- Tween em `value` de 100 → 0 é uma linha de código
- Mais acessível para ajustes visuais futuros (mudar textura, cor, tamanho)
- Fallback para `ColorRect + Tween` é simples se `TextureProgressBar` não renderizar bem em HTML5

---

## 10. Referências Cruzadas

| Documento | Seções Relevantes |
|-----------|-------------------|
| `PLAN.md` | 4.1 (Loop de Gameplay), 4.2 (Sistemas Core), 4.3 (Estrutura de Entidades), 7.2 (Padrões de Scene Tree) |
| `AGENTS.md` | Scene Architecture, Code Standards, Session Protocol |
| `PRD-fase-1.md` | RF-103 (Arena trigger), RF-104 (Caipora cena), decisões de TileMap e sinais |
| `ROADMAP.md` | Fase 2: Arena & Timing |
| `REPORT-fase-1.md` | Estado de saída da Fase 1, estrutura de diretórios, decisões arquiteturais aplicadas |
