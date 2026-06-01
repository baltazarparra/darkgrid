# darkgrid — Combat-Focused Roguelike

> Browser-first roguelike built with Godot 4.6 + GDScript.  
> Published on itch.io as an HTML5 build.

---

## 1. Product Vision

**darkgrid** is a 2D pixel-art roguelike where the combat feels *satisfying*.

The core innovation is a **timing-based combat system** inspired by *Legend of Dragoon* and *Clair Obscur*:

- **Spacebar to attack:** Press at the right frame to land a **critical hit** (2x–3x damage).
- **Spacebar to defend:** Press at the right frame to **perfect dodge** (zero damage) and **counter-attack**.

Every action has juicy feedback: screen shake, particle bursts, hit-stop frames, and crisp sound effects.

**MVP Scope:**
- 1 playable character
- 1 enemy type
- 1 arena/stage + boss
- Timing system fully implemented and satisfying

**Out of scope for MVP:**
- Steam / desktop builds
- Mobile builds
- Gamepad support
- Multiplayer
- Cloud saves
- Leaderboards
- Achievements

---

## 2. Target Platform

- **Primary:** Web / HTML5 (itch.io)
- **Renderer:** Godot 2D (Compatibility mode for WebGL stability)
- **Resolution:** 1280×720 (scalable)

---

## 3. Tech Stack

| Layer | Choice |
|-------|--------|
| Engine | Godot 4.6.3 |
| Language | GDScript |
| Rendering | 2D, OpenGL Compatibility |
| Distribution | itch.io HTML5 export |
| Version Control | Git |
| Agent Tools | `@coding-solo/godot-mcp` (MCP server) |

---

## 4. Game Architecture

### 4.1 Gameplay Loop

```
[Main Menu]
    ↓
[Exploration]  ← grid-based, turn-based
    ↓  (step onto arena tile)
[Arena Combat] ← action / timing-based
    ↓  (win / die)
[Rewards / Death]
    ↓
[Hub / Meta-progression]
    ↓
[Exploration]  ← next arena
```

**Exploration:**
- Grid-based movement (4 directions)
- Turn-based: player moves one tile → enemies move
- Fog of war or limited visibility
- Stepping onto an arena tile triggers combat

**Arena Combat:**
- Real-time action (not turn-based)
- Player and enemy have attack cooldowns
- Enemy telegraphs attacks with a visual cue + wind-up window
- Player presses **Space** during the cue window to dodge + counter
- Player presses **Space** during their own attack window to crit
- Missing the timing = normal outcome (no penalty, no bonus)

### 4.2 Core Systems

| System | Responsibility |
|--------|----------------|
| `TurnManager` | Handles exploration turn order |
| `ArenaManager` | Spawns enemies, manages arena state, win/lose conditions |
| `TimingSystem` | Detects spacebar presses within cue windows, emits hit/miss events |
| `CombatSystem` | Applies damage, handles death, triggers feedback |
| `FeedbackSystem` | Screenshake, particles, hit-stop, sound cues |
| `MetaProgression` | Unlocks between runs (persisted in `user://`) |

### 4.3 Entity Structure

```
Player
├── MovementController (exploration)
├── CombatActor (arena)
│   ├── Health
│   ├── AttackCooldown
│   └── TimingWindow
└── FeedbackReceiver

Enemy
├── CombatActor
│   ├── Health
│   ├── AttackPattern (telegraph → wind-up → strike)
│   └── TimingWindow (for player dodge)
└── FeedbackReceiver
```

---

## 5. Directory Structure

```
darkgrid/
├── assets/
│   ├── sprites/          # all sprites: chars, enemies, tiles, items (.png)
│   ├── audio/
│   │   └── sfx/          # sound effects (.wav, jsfxr/sfxr)
│   ├── fonts/            # pixel font (.ttf / .otf)
│   └── licenses/         # CC0 licenses and attribution
├── scenes/
│   ├── ui/               # menus, HUD, screens
│   ├── exploration/      # grid map, fog, tiles
│   ├── arena/            # combat arena backgrounds
│   └── shared/           # reusable components (health bar, etc)
├── scripts/
│   ├── core/             # autoloads: GameState, SignalBus, MetaProgression
│   ├── systems/          # TimingSystem, CombatSystem, FeedbackSystem
│   ├── entities/         # Player, Enemy base classes
│   ├── exploration/      # grid logic, TurnManager
│   ├── arena/            # ArenaManager, attack patterns
│   └── utils/            # helpers, constants
├── tests/
│   └── unit/             # GUT unit tests
├── docs/                 # design docs, references
└── export/               # HTML5 build output (gitignored)
```

---

## 6. Code Standards

### 6.1 Naming

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `CombatActor`, `TimingSystem` |
| Variables / Functions | snake_case | `attack_damage`, `start_timing_window()` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH`, `TIMING_WINDOW_FRAMES` |
| Signals | past-tense snake_case | `health_changed`, `timing_hit` |
| Files | snake_case | `combat_actor.gd`, `arena_manager.gd` |

### 6.2 Script Layout

```gdscript
class_name CombatActor
extends CharacterBody2D

# ─── Exports ───────────────────────────────────────
@export var max_health: int = 100
@export var attack_damage: int = 10

# ─── Signals ───────────────────────────────────────
signal health_changed(new_health: int)
signal died

# ─── Constants ─────────────────────────────────────
const TIMING_WINDOW_FRAMES := 6

# ─── State ─────────────────────────────────────────
var current_health: int
var is_timing_window_open: bool = false

# ─── Lifecycle ─────────────────────────────────────
func _ready() -> void:
    current_health = max_health

# ─── Public API ────────────────────────────────────
func take_damage(amount: int) -> void:
    current_health = clampi(current_health - amount, 0, max_health)
    health_changed.emit(current_health)
    if current_health <= 0:
        died.emit()

# ─── Private ───────────────────────────────────────
func _open_timing_window() -> void:
    is_timing_window_open = true
```

### 6.3 Principles

- **Composition over inheritance:** Use `@export` nodes and components, avoid deep inheritance trees.
- **Signals for decoupling:** Systems communicate via `SignalBus` autoload or direct signals, not direct references.
- **State machines:** Use `StateMachine` pattern for Player and Enemy behaviors (explore → combat → dead).
- **No magic numbers:** Define constants at the top of the script or in a `constants.gd` autoload.
- **Typed everything:** Use static typing (`-> void`, `-> int`, `: int`) everywhere.

---

## 7. Scene Architecture

### 7.1 Autoloads (`Project > Project Settings > Autoloads`)

| Name | Script | Purpose |
|------|--------|---------|
| `GameState` | `scripts/core/game_state.gd` | Current screen, run state, pause |
| `SignalBus` | `scripts/core/signal_bus.gd` | Global signals (decoupled communication) |
| `MetaProgression` | `scripts/core/meta_progression.gd` | Unlocks, currency, stats between runs |
| `FeedbackSystem` | `scripts/systems/feedback_system.gd` | Global screenshake, particles, sound |

### 7.2 Scene Tree Patterns

- **Arena scene:** `ArenaManager` (Node2D) owns the background, spawns `Player` and `Enemy` instances.
- **UI scenes:** CanvasLayer-based, anchored to viewport, use `Control` nodes for layout.
- **Reusable components:** HealthBar, DamageNumber, TimingCue are instanced scenes (`PackedScene`) exported as `@export var`.

---

## 8. MCP & Agent Harness

The project has `@coding-solo/godot-mcp` installed and configured.

### 8.1 Available MCP Tools

| Tool | Use Case |
|------|----------|
| `create_scene` | Create new `.tscn` files |
| `add_node` | Add nodes to existing scenes |
| `save_scene` | Save scene changes |
| `run_project` | Run the game and capture output |
| `get_debug_output` | Read stdout/stderr from running game |
| `stop_project` | Kill the running game process |
| `launch_editor` | Open Godot editor for the project |
| `get_godot_version` | Verify installed Godot version |

### 8.2 Agent Workflow

1. **Orient:** Read `PLAN.md`, check git status, read `AGENTS.md`.
2. **Verify:** Run smoke test (`run_project`) before making changes.
3. **Implement:** One task per session. Use MCP tools for scene creation.
4. **Test:** Run GUT unit tests + smoke test + screenshot validation.
5. **Update:** Commit with descriptive message. Update `PLAN.md` if scope changes.

---

## 9. Build & Export Pipeline

### 9.1 Local Development

```bash
# Run the game (requires display :0, WSLg works)
~/.local/bin/godot --path /home/baltz/darkgrid

# Run headless (for scene operations via MCP)
~/.local/bin/godot --headless --path /home/baltz/darkgrid --script <script>

# Run GUT tests
~/.local/bin/godot --headless --path /home/baltz/darkgrid -s res://addons/gut/gut_cmdln.gd
```

### 9.2 Export to HTML5

```bash
# Export preset must be configured in Godot first
~/.local/bin/godot --headless --path /home/baltz/darkgrid --export-release "Web" export/index.html
```

### 9.3 Deploy to itch.io

1. Zip `export/` contents.
2. Upload to itch.io project page.
3. Set "This file will be played in the browser" for `index.html`.

---

## 10. Testing & Validation

### 10.1 Layers

| Layer | Tool | Trigger |
|-------|------|---------|
| Smoke test | `run_project` | After every change |
| Unit tests | GUT (Godot Unit Test) | Before commit |
| Visual validation | Screenshot | Before commit |
| Playtest | Manual | At milestone boundaries |

### 10.2 Acceptance Criteria per Milestone

- **Fase 1:** Player moves on grid. Camera follows. No crashes.
- **Fase 2:** Arena loads. Timing cue appears. Spacebar registers hit/miss. Damage applies.
- **Fase 3:** Enemy attacks with telegraph. Boss has unique pattern. Win/lose conditions work.
- **Fase 4:** Meta-progression unlocks persist. Polish particles, sounds, screenshake.
- **Fase 5:** HTML5 export runs in browser. itch.io page loads and plays.

---

## 11. Milestones

### Phase 1: Grid + Player Movement
- [ ] Grid-based exploration scene
- [ ] Player character with 4-direction movement
- [ ] Camera follow
- [ ] Arena tile triggers combat

### Phase 2: Arena + Timing System
- [ ] Arena scene with background
- [ ] Player combat actor (health, damage)
- [ ] Timing cue UI (visual bar + window)
- [ ] Spacebar detection within window
- [ ] Critical hit on perfect timing
- [ ] Feedback: screenshake + particles + sound

### Phase 3: Enemy AI + Boss
- [ ] Enemy combat actor
- [ ] Attack telegraph (wind-up animation + cue)
- [ ] Perfect dodge + counter-attack on timing
- [ ] Boss with unique attack pattern
- [ ] Win condition (enemy death) / Lose condition (player death)

### Phase 4: Meta-Progression + Polish
- [ ] Hub scene between runs
- [ ] Unlock system (characters, modifiers)
- [ ] Persistent save (`user://`)
- [ ] Particle polish
- [ ] Sound design (sfx for every action)
- [ ] Screenshake tuning
- [ ] Hit-stop frames

### Phase 5: Export + Publish
- [ ] HTML5 export preset configured
- [ ] Export test in browser
- [ ] itch.io page created
- [ ] Upload and verify

---

## 12. Asset Guidelines

- **Sprites:** CC0 from Kenney.nl. Pick **one pack** for visual consistency. 16×16 or 32×32, .png, transparent background. No AI-generated sprites for core game.
- **Audio:** Generate with jsfxr/sfxr. Export as .wav. Short, punchy, under 100KB each. No music in MVP.
- **UI:** Godot native UI nodes (`Button`, `Panel`, `Label`, `ProgressBar`). No custom UI sprite sheets.
- **Fonts:** One pixel font with permissive license (e.g., Kenney Fonts or "Press Start 2P").
- **Licenses:** Copy every asset pack's license into `assets/licenses/`.

---

## 13. Notes

- **Browser-first:** Avoid heavy shaders, large textures, and complex physics. Test load time frequently.
- **Timing windows:** Start generous (12 frames), tune down based on playtest feel.
- **Feedback is king:** Every action must feel good. Prioritize juice over content.
- **Save often:** Use git commits as checkpoints. The agent should commit after every successful task.
