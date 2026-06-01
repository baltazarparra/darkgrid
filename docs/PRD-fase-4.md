# PRD — Fase 4: Meta-Progression & UI

> **caipora** — Brazilian Folk Horror Roguelike
> **Fase:** 4 / 5
> **Status:** 📝 Revisado (pronto para execução)
> **Document Version:** 1.0
> **Depende de:** [PRD-fase-3.md](./PRD-fase-3.md) (Enemy AI & Visceral Feedback)

---

## 1. Visão Geral

A Fase 4 fecha o **loop do jogo**. Até agora a Caipora caça e morre, mas a morte não tem peso
e a vitória não constrói nada. Não há porta de entrada (menu), não há rosto para a dor (HUD de
vida), não há santuário entre as caçadas (Hub), e nada do que se conquista persiste.

Esta fase costura tudo num ciclo de roguelike:

```
MainMenu → Hub → Exploração → Arena → Win/GameOver → Hub → (próxima run)
```

A vida da Caipora **persiste dentro de uma run** — cada golpe recebido é uma dívida que se
carrega até o Hub, onde a floresta finalmente solta o fôlego e ela se cura. Entre as runs, o
jogador gasta o que aprendeu numa árvore simples de upgrades permanentes, salvos em disco. Ao
fim da Fase 4, **é possível jogar uma run completa, perder, voltar mais forte e tentar de novo.**

**Tom:** O Hub é o único lugar onde a floresta não alcança. Uma fogueira baixa, o silêncio
depois do sangue. Aqui a Caipora respira — e decide o que vai ser da próxima vez que entrar.

**Filosofia:** *"Progressão não é número maior. É a coragem de entrar de novo sabendo o que há lá dentro."*

---

## 2. Objetivos

| # | Objetivo | Sucesso |
|---|----------|---------|
| 1 | **Porta de Entrada** | MainMenu carrega no boot; Iniciar leva ao Hub |
| 2 | **Rosto da Dor** | HUD mostra a vida da Caipora atualizando em tempo real no combate |
| 3 | **Vida que Pesa** | HP persiste entre encontros de uma run; recupera só no Hub |
| 4 | **Santuário** | Hub permite comprar upgrades permanentes e iniciar a próxima run |
| 5 | **Memória** | Upgrades e estatísticas persistem em `user://savegame.json` entre sessões |
| 6 | **Loop Fechado** | Player joga run completa: menu → hub → exploração → arena → fim → hub |

---

## 3. Requisitos Funcionais

### 3.1 RF-401 — MainMenu

**Descrição:** Tela de entrada do jogo, carregada no boot.

**Artefatos:**
- `scenes/ui/main_menu.tscn`
- `scripts/ui/main_menu.gd` (`class_name MainMenu`)

**Estrutura da Scene Tree:**
```
MainMenu (CanvasLayer)
├── Background (ColorRect) — COLOR_NIGHT (#0d1117)
└── Center (CenterContainer, anchors full)
    └── VBox (VBoxContainer)
        ├── Title (Label) — "CAIPORA", font grande, COLOR_BLOOD
        ├── Subtitle (Label) — "a floresta tem fome", COLOR_TEXT
        ├── StartButton (Button) — "Iniciar"
        └── QuitButton (Button) — "Sair"
```

**Detalhes Técnicos:**
- `CanvasLayer` raiz com script `MainMenu`.
- No `_ready()`: `MetaProgression.load_progress()` (carrega o save uma vez no boot).
- `StartButton.pressed` → `GameState.change_screen(SignalBus.Screen.HUB)`.
- `QuitButton.pressed` → `get_tree().quit()`.
- `project.godot:run/main_scene` passa a apontar para `main_menu.tscn` (ver RF-408).
- Botões navegáveis por teclado (foco inicial no StartButton) — coerente com input `ui_accept`.

**Critério de Aceitação:**
- [ ] Jogo boota no MainMenu (não mais na exploração)
- [ ] "Iniciar" transiciona para o Hub
- [ ] "Sair" encerra o jogo
- [ ] Save é carregado no boot

---

### 3.2 RF-402 — Hub (Santuário entre Runs)

**Descrição:** Cena de descanso entre runs. Exibe progresso, recupera a vida da Caipora,
permite comprar upgrades permanentes e iniciar a próxima run.

**Artefatos:**
- `scenes/ui/hub.tscn`
- `scripts/ui/hub.gd` (`class_name Hub`)

**Estrutura da Scene Tree:**
```
Hub (CanvasLayer)
├── Background (ColorRect) — COLOR_EARTH (#3d1f1f)
└── Center (CenterContainer, anchors full)
    └── VBox (VBoxContainer)
        ├── Title (Label) — "ACAMPAMENTO"
        ├── Stats (Label) — "Caçadas: {total_runs}   Vitórias: {total_wins}"
        ├── UpgradeList (VBoxContainer) — uma linha por upgrade (RF-403)
        │   └── [UpgradeRow] (HBoxContainer): Label(nome/nível) + Button("Aprimorar")
        └── EnterButton (Button) — "Entrar na Floresta"
```

**Detalhes Técnicos:**
- No `_ready()`:
  - `GameState.heal_to_full()` — a Caipora recupera HP cheio ao chegar ao Hub (RF-404).
  - Popula `Stats` com `MetaProgression.total_runs` / `total_wins`.
  - Gera dinamicamente uma `UpgradeRow` por chave em `MetaProgression.UPGRADE_DEFS` (RF-403),
    mostrando `nível atual / máximo` e desabilitando o botão se já no cap.
- Botão "Aprimorar" de uma linha → `MetaProgression.purchase_upgrade(key)` → `save_progress()`
  → atualiza o texto da linha (compra livre permanente; sem custo).
- `EnterButton.pressed` → `GameState.start_run()` (RF-404) → `change_screen(EXPLORATION)`.

**Critério de Aceitação:**
- [ ] Hub exibe total de caçadas e vitórias corretos
- [ ] Cada upgrade aparece com nível atual e botão de aprimorar
- [ ] Aprimorar incrementa o nível, salva e atualiza a UI imediatamente
- [ ] Botão desabilita ao atingir o nível máximo do upgrade
- [ ] "Entrar na Floresta" inicia a run e carrega a exploração
- [ ] Chegar ao Hub recupera a vida da Caipora

---

### 3.3 RF-403 — Upgrades Permanentes em MetaProgression

**Descrição:** Sistema de upgrades permanentes, de compra livre (sem moeda), persistido no save.

**Artefatos:**
- Modificações em `scripts/core/meta_progression.gd`

**Detalhes Técnicos:**
```gdscript
# Definição declarativa dos upgrades (chave → cap de níveis).
const UPGRADE_DEFS := {
    "max_hp": { "name": "Vigor", "max_level": 3 },      # +10 HP por nível
    "cooldown": { "name": "Reflexos", "max_level": 2 }, # -0.1s cooldown por nível
}

var upgrades: Dictionary = {}  # { "max_hp": int, "cooldown": int } — default 0

func get_upgrade_level(key: String) -> int:
    return int(upgrades.get(key, 0))

func purchase_upgrade(key: String) -> bool:
    if not UPGRADE_DEFS.has(key):
        return false
    var level := get_upgrade_level(key)
    if level >= int(UPGRADE_DEFS[key]["max_level"]):
        return false  # já no cap
    upgrades[key] = level + 1
    return true

func get_bonus_max_hp() -> int:
    return get_upgrade_level("max_hp") * 10

func get_cooldown_reduction() -> float:
    return get_upgrade_level("cooldown") * 0.1
```

**Persistência (save/load):**
- `save_progress()` inclui `"upgrades": upgrades` no dicionário serializado.
- `load_progress()` lê `data.get("upgrades", {})` — **retrocompatível**: saves antigos sem o
  campo carregam com `upgrades` vazio (todos nível 0). Sanitizar para `int` por chave.
- Manter `unlocked_characters/modifiers`, `total_runs/total_wins` intactos (testes da Fase 0
  continuam válidos).

**Critério de Aceitação:**
- [ ] `purchase_upgrade` incrementa o nível e respeita o cap (retorna `false` no cap)
- [ ] `get_bonus_max_hp` = nível de `max_hp` × 10
- [ ] `get_cooldown_reduction` = nível de `cooldown` × 0.1
- [ ] `save_progress`/`load_progress` preservam `upgrades`
- [ ] Save antigo sem `upgrades` carrega sem erro (default vazio)

---

### 3.4 RF-404 — Estado de Run no GameState (HP Persistente)

**Descrição:** A vida da Caipora persiste ao longo de uma run (entre encontros) e só recupera
no Hub. O `GameState` passa a guardar o estado da run corrente.

**Artefatos:**
- Modificações em `scripts/core/game_state.gd`

**Detalhes Técnicos:**
```gdscript
var run_active: bool = false
var caipora_max_hp: int = Constants.CAIPORA_MAX_HEALTH
var caipora_current_hp: int = Constants.CAIPORA_MAX_HEALTH

func start_run() -> void:
    run_active = true
    caipora_max_hp = Constants.CAIPORA_MAX_HEALTH + MetaProgression.get_bonus_max_hp()
    caipora_current_hp = caipora_max_hp

func heal_to_full() -> void:
    caipora_max_hp = Constants.CAIPORA_MAX_HEALTH + MetaProgression.get_bonus_max_hp()
    caipora_current_hp = caipora_max_hp

func end_run(won: bool) -> void:
    run_active = false
    MetaProgression.total_runs += 1
    if won:
        MetaProgression.total_wins += 1
    MetaProgression.save_progress()
```

- O **HP de run vive no GameState, não no save** — o save guarda apenas meta permanente
  (upgrades + estatísticas). HP é estado volátil da sessão de jogo.
- `start_run()` é chamado pelo Hub ao "Entrar na Floresta".
- `end_run(won)` é chamado nas telas de fim (RF-407).
- `heal_to_full()` é chamado ao entrar no Hub (RF-402); recalcula o max com o bônus atual de meta
  (caso o jogador tenha comprado +HP).

**Critério de Aceitação:**
- [ ] `start_run` define `caipora_max_hp` com o bônus de meta e enche o HP
- [ ] HP danificado numa arena permanece reduzido no próximo encontro da mesma run
- [ ] `heal_to_full` (Hub) restaura HP cheio
- [ ] `end_run(true)` incrementa `total_runs` e `total_wins` e salva
- [ ] `end_run(false)` incrementa só `total_runs` e salva

---

### 3.5 RF-405 — Aplicar Run/Meta à Caipora da Arena

**Descrição:** Ao spawnar a Caipora na arena, aplicar o HP de run, o bônus de vida e a redução
de cooldown vindos da meta-progressão; ao fim do combate, gravar o HP sobrevivente de volta.

**Artefatos:**
- Modificações em `scripts/arena/arena_manager.gd`

**Detalhes Técnicos:**
- Em `_spawn_caipora()`, **após** `add_child(_caipora)` (o `HealthComponent._ready` já igualou
  `current_health = max_health`), sobrescrever a partir do GameState:
  ```gdscript
  _caipora.health.max_health = GameState.caipora_max_hp
  _caipora.health.current_health = GameState.caipora_current_hp
  _caipora.attack_cooldown = maxf(0.3, Constants.ATTACK_COOLDOWN_SECONDS - MetaProgression.get_cooldown_reduction())
  ```
- Conectar `_caipora.health.health_changed` → reemitir `SignalBus.caipora_health_changed(new, max)`
  (RF-406). Emitir uma vez no spawn para o HUD inicializar.
- Conectar `_caipora.health.died` → `SignalBus.caipora_died` (ativa o sinal reservado).
- Ao encerrar o combate (em `_on_actor_died`, antes de trocar de tela), gravar o HP atual de
  volta: `GameState.caipora_current_hp = _caipora.health.current_health` (0 em caso de derrota).

**Critério de Aceitação:**
- [ ] Caipora na arena nasce com o HP atual da run (não sempre cheio)
- [ ] Bônus de `max_hp` da meta aumenta o HP máximo efetivo
- [ ] Redução de cooldown da meta diminui `attack_cooldown` (com piso de 0.3s)
- [ ] `SignalBus.caipora_health_changed` emite a cada dano/cura
- [ ] HP sobrevivente é gravado no GameState ao fim do combate

---

### 3.6 RF-406 — HUD de Vida

**Descrição:** Interface de combate que mostra a vida da Caipora em tempo real.

**Artefatos:**
- `scenes/ui/hud.tscn`
- `scripts/ui/hud.gd` (`class_name Hud`)

**Estrutura da Scene Tree:**
```
Hud (CanvasLayer)
└── Margin (MarginContainer, ancorado no topo)
    └── HBox (HBoxContainer)
        ├── HealthLabel (Label) — "CAIPORA"
        └── HealthBar (ProgressBar) — min 0, max = max_hp
```

**Detalhes Técnicos:**
- Instanciado como nó da `arena.tscn` (CanvasLayer sobre o combate).
- No `_ready()`: `SignalBus.caipora_health_changed.connect(_on_health_changed)`.
- `_on_health_changed(new_health, max_health)` atualiza `HealthBar.max_value`/`value` e,
  opcionalmente, o texto numérico.
- Cor da barra via `theme_override_styles`/`tint_progress` na paleta (`COLOR_BLOOD` no fill,
  `COLOR_EARTH` no fundo). Sem dependência de texturas externas (coerente com a decisão da Fase 2).
- **Desacoplado:** o HUD nunca referencia a Caipora diretamente — só escuta o `SignalBus`.

**Critério de Aceitação:**
- [ ] HUD aparece na arena sobre o combate
- [ ] Barra inicia no HP atual da run e no max correto
- [ ] Barra diminui ao receber dano e sobe ao curar/contra-atacar (se houver cura)
- [ ] HUD não tem referência direta à Caipora (apenas `SignalBus`)

---

### 3.7 RF-407 — Win/GameOver Integrados ao Loop

**Descrição:** As telas de fim de combate (placeholders da Fase 3) passam a registrar o
resultado da run e a voltar para o **Hub**, não para a exploração.

**Artefatos:**
- Modificações em `scripts/ui/end_screen.gd`
- `scenes/ui/win.tscn` e `scenes/ui/game_over.tscn` (ajuste de texto/ação)

**Detalhes Técnicos:**
- `EndScreen` ganha um `@export var won: bool` (true em `win.tscn`, false em `game_over.tscn`).
- No `_ready()`: `GameState.end_run(won)` (incrementa stats + salva — RF-404). Idempotência:
  garantir que `end_run` rode uma única vez por entrada na tela.
- Input `ui_accept` → `GameState.change_screen(SignalBus.Screen.HUB)` (em vez de EXPLORATION).
- Textos mantêm o tom: WIN "A CRIATURA TOMBOU" / hint "Espaço para voltar ao acampamento";
  GAME_OVER "A FLORESTA TE DEVOROU" / hint "Espaço para voltar ao acampamento".

**Critério de Aceitação:**
- [ ] Vitória chama `end_run(true)` (total_runs++ e total_wins++) e salva
- [ ] Derrota chama `end_run(false)` (apenas total_runs++) e salva
- [ ] `end_run` é disparado exatamente uma vez por tela
- [ ] Ambas as telas retornam ao Hub via `ui_accept`

---

### 3.8 RF-408 — Transições Completas de Tela

**Descrição:** Fechar o roteamento de telas no `GameState` e mudar a cena inicial do projeto.

**Artefatos:**
- Modificações em `scripts/core/game_state.gd`
- Modificações em `project.godot`

**Detalhes Técnicos:**
- Estender `_on_screen_changed` com os casos faltantes:
  ```gdscript
  SignalBus.Screen.MAIN_MENU:
      get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
  SignalBus.Screen.HUB:
      get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")
  ```
  (ARENA/EXPLORATION/WIN/GAME_OVER permanecem como na Fase 3.)
- `project.godot`: `run/main_scene = "res://scenes/ui/main_menu.tscn"`.
- Loop completo resultante:
  ```
  MainMenu --Iniciar--> Hub --Entrar--> Exploração --trigger--> Arena
     ^                    ^                                        |
     |                    |                              vitória / derrota
     |                    +---------------- Win/GameOver <---------+
  (Sair encerra)            (volta ao Hub, run registrada)
  ```

**Critério de Aceitação:**
- [ ] `change_screen(MAIN_MENU)` carrega o MainMenu
- [ ] `change_screen(HUB)` carrega o Hub
- [ ] `main_scene` do projeto é o MainMenu
- [ ] O loop completo é percorrível sem becos sem saída

---

## 4. Requisitos Não-Funcionais

| # | Requisito | Especificação |
|---|-----------|---------------|
| RNF-401 | **Performance** | Telas de UI são leves (Controls + ColorRect). HUD atualiza só em `caipora_health_changed`, não em `_process`. 60 FPS mantido (validação HTML5 na Fase 5). |
| RNF-402 | **Código** | `class_name` + static typing em `MainMenu`, `Hub`, `Hud`. Sem hardcode de valores que pertencem a `Constants`/`MetaProgression`. |
| RNF-403 | **Decoupling** | HUD escuta apenas `SignalBus.caipora_health_changed`. Telas não referenciam managers de outras cenas; navegação só por `GameState.change_screen`. |
| RNF-404 | **Persistência** | Save em `user://savegame.json` retrocompatível (campos novos com default). Nunca crashar com save ausente/corrompido. |
| RNF-405 | **Testes** | ≥2 testes GUT novos (upgrades + estado de run). Os 23 testes atuais continuam passando. |
| RNF-406 | **UI sem assets externos** | Telas usam ColorRect/Label/Button + paleta de `Constants` (sem dependência de texturas), coerente com as Fases 2–3. |

---

## 5. Especificações de Teste

### 5.1 Testes de Fumaça (Smoke Tests)

| # | Teste | Como executar |
|---|-------|---------------|
| ST-401 | Boot abre o MainMenu | Rodar o projeto; verificar cena inicial |
| ST-402 | Iniciar → Hub; Entrar → Exploração | Clicar nos botões e observar transições |
| ST-403 | Comprar upgrade no Hub atualiza UI e salva | Aprimorar "Vigor"; verificar nível e `savegame.json` |
| ST-404 | HUD reflete dano em tempo real | Entrar na arena, levar dano, observar a barra |
| ST-405 | HP persiste entre encontros da run | Sair de uma arena com dano e checar HP no próximo encontro |
| ST-406 | Hub recupera HP | Voltar ao Hub e confirmar HP cheio na run seguinte |
| ST-407 | Vitória/derrota registram stats e voltam ao Hub | Vencer/perder; conferir `total_runs/total_wins` |
| ST-408 | Bônus de meta afeta a Caipora | Comprar +HP / -cooldown e confirmar efeito na arena |

### 5.2 Testes Unitários (GUT)

```gdscript
# tests/unit/test_upgrades.gd
extends GutTest

func before_each():
    MetaProgression.upgrades = {}

func test_purchase_increments_and_caps():
    assert_true(MetaProgression.purchase_upgrade("max_hp"))
    assert_eq(MetaProgression.get_upgrade_level("max_hp"), 1)
    assert_eq(MetaProgression.get_bonus_max_hp(), 10)
    # vai até o cap (3) e então recusa
    MetaProgression.purchase_upgrade("max_hp")
    MetaProgression.purchase_upgrade("max_hp")
    assert_false(MetaProgression.purchase_upgrade("max_hp"))
    assert_eq(MetaProgression.get_upgrade_level("max_hp"), 3)

func test_upgrades_persist_through_save_load():
    MetaProgression.purchase_upgrade("cooldown")
    MetaProgression.save_progress()
    MetaProgression.upgrades = {}
    MetaProgression.load_progress()
    assert_eq(MetaProgression.get_upgrade_level("cooldown"), 1)
    assert_almost_eq(MetaProgression.get_cooldown_reduction(), 0.1, 0.001)
```

```gdscript
# tests/unit/test_run_state.gd
extends GutTest

func before_each():
    MetaProgression.upgrades = {}
    MetaProgression.total_runs = 0
    MetaProgression.total_wins = 0

func test_start_run_fills_hp_with_bonus():
    MetaProgression.purchase_upgrade("max_hp")  # +10
    GameState.start_run()
    assert_eq(GameState.caipora_max_hp, Constants.CAIPORA_MAX_HEALTH + 10)
    assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)

func test_damage_persists_until_heal():
    GameState.start_run()
    GameState.caipora_current_hp -= 30
    assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp - 30)
    GameState.heal_to_full()
    assert_eq(GameState.caipora_current_hp, GameState.caipora_max_hp)

func test_end_run_updates_stats():
    GameState.end_run(true)
    assert_eq(MetaProgression.total_runs, 1)
    assert_eq(MetaProgression.total_wins, 1)
    GameState.end_run(false)
    assert_eq(MetaProgression.total_runs, 2)
    assert_eq(MetaProgression.total_wins, 1)
```

> Nota: testes que tocam autoloads (`MetaProgression`, `GameState`) devem resetar o estado em
> `before_each` para não vazar entre casos. Considerar restaurar o `savegame.json` ao final
> (ou usar um caminho de teste) para não poluir o save real.

---

## 6. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Save antigo sem `upgrades` quebra o load | Média | Médio | `data.get("upgrades", {})` + sanitização por chave; nunca assumir presença. |
| HP de run dessincronizado entre GameState e a arena | Média | Alto | Fonte única: GameState. ArenaManager lê no spawn e grava no fim; HUD só escuta sinal. |
| `end_run` disparado duas vezes (re-entrada na tela) | Baixa | Médio | Guard de idempotência por entrada na `EndScreen` (flag local). |
| Botões de UI não navegáveis por teclado no HTML5 | Baixa | Baixo | Definir foco inicial; ações via `ui_accept`. Testar na Fase 5. |
| Testes de autoload poluindo `savegame.json` real | Média | Baixo | Resetar estado em `before_each`; documentar; idealmente caminho de save de teste. |
| Order-of-init: setar HP antes do `_ready` do HealthComponent | Baixa | Médio | Setar `max_health`/`current_health` **após** `add_child` (pós-`_ready`). |

---

## 7. Checklist de Entrega da Fase 4

- [ ] **RF-401:** MainMenu no boot, Iniciar→Hub, Sair encerra
- [ ] **RF-402:** Hub com stats, upgrades compráveis e "Entrar na Floresta"
- [ ] **RF-403:** Upgrades permanentes em MetaProgression + persistência retrocompatível
- [ ] **RF-404:** Estado de run no GameState (start/heal/end, HP persistente)
- [ ] **RF-405:** Caipora da arena usa HP de run + bônus + cooldown; grava HP de volta
- [ ] **RF-406:** HUD de vida via `SignalBus.caipora_health_changed`
- [ ] **RF-407:** Win/GameOver registram run e voltam ao Hub
- [ ] **RF-408:** Transições MAIN_MENU/HUB + `main_scene` = MainMenu
- [ ] **RNF-402/403:** Static typing + decoupling via SignalBus
- [ ] **RNF-405:** ≥2 testes GUT novos; 23 testes atuais ainda passando
- [ ] **ST-401 a ST-408:** Smoke tests passam
- [ ] **Commit:** `git commit -m "fase-4: meta-progression & UI — loop completo"`
- [ ] **ROADMAP:** Marcar tasks da Fase 4 como ✅ Done

---

## 8. Notas para o Agente

### Ordem de Implementação Recomendada
1. **RF-403 (Upgrades em MetaProgression)** — base de dados da progressão
2. **RF-404 (Estado de run no GameState)** — fonte única do HP de run
3. **RF-408 (Transições + main_scene)** — roteamento para as novas telas
4. **RF-401 (MainMenu)** — porta de entrada
5. **RF-402 (Hub)** — usa RF-403 + RF-404
6. **RF-405 (Aplicar à Caipora) + RF-406 (HUD)** — combate ciente da progressão
7. **RF-407 (Win/GameOver integrados)** — fecha o loop
8. **Testes GUT + smoke da run completa**

### Anti-Padrões a Evitar
- ❌ Guardar HP de run no save (HP é volátil; save é só meta permanente)
- ❌ HUD referenciando a Caipora diretamente — usar `SignalBus.caipora_health_changed`
- ❌ Hardcodear bônus/cooldown — derivar de `MetaProgression` e `Constants`
- ❌ Assumir que o save tem todos os campos — sempre `get(..., default)`
- ❌ Espalhar `change_scene_to_file` pelas cenas — navegação só via `GameState.change_screen`
- ❌ Introduzir moeda/custo (fora de escopo: compra livre nesta fase)

### Padrões a Seguir
- ✅ `class_name` em `MainMenu`, `Hub`, `Hud`; `UPGRADE_DEFS` declarativo em MetaProgression
- ✅ Navegação centralizada em `GameState.change_screen` (já existente)
- ✅ UI procedural (ColorRect/Label/Button + paleta `Constants`), sem texturas externas
- ✅ Sinais reservados da Fase 0 finalmente ativados (`caipora_health_changed`, `caipora_died`)
- ✅ Reuso de `EndScreen`, `HealthComponent.heal()`, `MetaProgression.save/load_progress`

---

## 9. Decisões Arquiteturais Específicas

### 9.1 HP de Run no GameState (não no Save)
**Decisão:** A vida corrente da run vive em `GameState` (`caipora_current_hp`/`caipora_max_hp`);
o save (`MetaProgression`) guarda apenas meta permanente (upgrades + estatísticas).
**Por quê:** HP é estado efêmero de uma run; persistir em disco confundiria meta-progressão com
estado de sessão e complicaria saves. Recuperação no Hub torna o HP uma pressão tática da run.

### 9.2 Upgrades de Compra Livre (sem Moeda)
**Decisão:** Upgrades disponíveis desde o início, comprados livremente (níveis com cap), sem custo.
**Por quê:** Mínimo viável para fechar o loop e demonstrar progressão persistente. Uma economia
(essência por vitória) é evolução natural pós-MVP, sem reescrever a base (`UPGRADE_DEFS` + níveis).

### 9.3 HUD Desacoplado por SignalBus
**Decisão:** HUD escuta `SignalBus.caipora_health_changed`; o ArenaManager reemite o sinal a
partir do `HealthComponent` da Caipora.
**Por quê:** Ativa o sinal reservado da Fase 0, mantém o HUD ignorante sobre onde a Caipora vive
e prepara terreno para HUD persistente (exploração) sem acoplamento.

### 9.4 Fluxo MainMenu → Hub → Run → Hub
**Decisão:** Boot no MainMenu; Iniciar leva ao Hub; o Hub é o ponto de partida e retorno de cada
run. Win/GameOver voltam ao Hub.
**Por quê:** O Hub vira o centro de gravidade do meta-loop — único lugar de cura e progressão —,
dando ritmo de roguelike (descansar, decidir, mergulhar de novo).

---

## 10. Referências Cruzadas

| Documento | Seções Relevantes |
|-----------|-------------------|
| `ROADMAP.md` | Fase 4: Meta-Progression & UI |
| `PRD-fase-3.md` | RF-306 (death anim/transição), telas placeholder, `GameState.next_enemy_scene` |
| `REPORT-fase-3.md` | Estado de saída, KI-004 resolvida (placeholders WIN/GAME_OVER), decisões |
| `PRD-fase-2.md` | RF-204/205 (HealthComponent/CombatActor), UI procedural sem texturas |
| `scripts/core/*` | `game_state.gd`, `meta_progression.gd`, `signal_bus.gd` (sinais reservados) |
