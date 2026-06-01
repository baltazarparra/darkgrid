# AGENTS.md — darkgrid

This file guides the Kimi Code CLI agent when working on the **darkgrid** project.

## Project Overview

**darkgrid** is a browser-first 2D pixel-art roguelike built with Godot 4.6.3 + GDScript.

The core mechanic is **timing-based combat**:
- Press **Space** at the right frame to land a **critical hit** (2x–3x damage).
- Press **Space** at the right frame to **perfect dodge** an enemy attack and **counter-attack**.

Gameplay loop: grid-based exploration (turn-based) → step onto arena tile → real-time arena combat with timing.

The full product spec is in `PLAN.md`. Read it before every session.

---

## Harness Layer — Agent Interaction Model

This project uses the **Godot MCP Server** (`@coding-solo/godot-mcp`) to let the agent create scenes, add nodes, and control the Godot editor programmatically.

### MCP Tools Available

| Tool | When to use |
|------|-------------|
| `create_scene` | Create a new `.tscn` file |
| `add_node` | Add a node to an existing scene |
| `save_scene` | Save changes to a scene |
| `run_project` | Run the game and capture output |
| `get_debug_output` | Read stdout/stderr from the running game |
| `stop_project` | Stop the running game process |
| `launch_editor` | Open the Godot editor |
| `get_godot_version` | Verify Godot installation |

### Godot Path

- Executable: `/home/baltz/.local/bin/godot` (v4.6.3-stable)
- Project: `/home/baltz/darkgrid`
- Display: `:0` (WSLg — works for `run_project` and `launch_editor`)
- Headless mode is used automatically by MCP for scene operations.

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Engine | Godot 4.6.3 |
| Language | GDScript (static typing required) |
| Rendering | 2D, OpenGL Compatibility |
| Art | Pixel art (16×16 or 32×32 sprites) |
| Audio | `.ogg` music, `.wav` SFX |
| Distribution | itch.io HTML5 export |
| Tests | GUT (Godot Unit Test) |
| Agent Tools | `@coding-solo/godot-mcp` |

---

## Directory Structure

Place files in the correct directory. Do not create new top-level folders without approval.

```
assets/
  sprites/     — Character and object sprites (.png)
  tilesets/    — Tileset images + .tres resources
  particles/   — Particle textures
  audio/sfx/   — Short sound effects
  audio/music/ — Background music
  fonts/       — Pixel fonts

scenes/
  ui/          — Menus, HUD, screens
  exploration/ — Grid map, fog, tile layers
  arena/       — Combat arena backgrounds
  shared/      — Reusable components (health bar, damage number, etc.)

scripts/
  core/        — Autoloads: GameState, SignalBus, MetaProgression
  systems/     — TimingSystem, CombatSystem, FeedbackSystem
  entities/    — Player, Enemy base classes
  exploration/ — Grid logic, TurnManager
  arena/       — ArenaManager, attack patterns
  utils/       — Helpers, constants

tests/
  unit/        — GUT unit tests

docs/          — Design docs, references
```

---

## Code Standards

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `CombatActor`, `TimingSystem` |
| Variables / Functions | snake_case | `attack_damage`, `start_timing_window()` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH`, `TIMING_WINDOW_FRAMES` |
| Signals | past-tense snake_case | `health_changed`, `timing_hit` |
| Files | snake_case | `combat_actor.gd`, `arena_manager.gd` |

### Script Layout

Order within a `.gd` file:

```gdscript
class_name ClassName
extends BaseClass

# ─── Exports ───────────────────────────────────────
# ─── Signals ───────────────────────────────────────
# ─── Constants ─────────────────────────────────────
# ─── State ─────────────────────────────────────────
# ─── Lifecycle (_ready, _process, etc.) ────────────
# ─── Public API ────────────────────────────────────
# ─── Private helpers ───────────────────────────────
```

### Principles

- **Composition over inheritance.** Export nodes as `@export var` components. Avoid deep inheritance.
- **Signals for decoupling.** Use `SignalBus` autoload or direct signals. Do not hardwire direct references between unrelated systems.
- **State machines.** Player and Enemy behaviors use `StateMachine` (explore → combat → dead).
- **No magic numbers.** Define constants at the top or in `scripts/utils/constants.gd`.
- **Static typing everywhere.** Use `-> void`, `-> int`, `: Type` on all functions and variables.
- **One class per file.** Do not stack multiple classes in a single `.gd` file.

---

## Scene Architecture

### Autoloads

Register these in `Project > Project Settings > Autoloads`:

| Name | Script | Purpose |
|------|--------|---------|
| `GameState` | `scripts/core/game_state.gd` | Screen state, pause, run state |
| `SignalBus` | `scripts/core/signal_bus.gd` | Global event bus |
| `MetaProgression` | `scripts/core/meta_progression.gd` | Unlocks, currency between runs |
| `FeedbackSystem` | `scripts/systems/feedback_system.gd` | Screenshake, particles, sound |

### Patterns

- **Arena scene:** `ArenaManager` (Node2D) owns background, spawns `Player` and `Enemy` instances.
- **UI scenes:** CanvasLayer-based, anchored to viewport.
- **Reusable components:** Export as `@export var reusable_scene: PackedScene` and instantiate.

---

## Development Commands

```bash
# Run the game (WSLg display :0 available)
~/.local/bin/godot --path /home/baltz/darkgrid

# Run headless (for MCP scene operations)
~/.local/bin/godot --headless --path /home/baltz/darkgrid --script <script>

# Run GUT tests (must install GUT addon first)
~/.local/bin/godot --headless --path /home/baltz/darkgrid -s res://addons/gut/gut_cmdln.gd

# Export HTML5 (preset must be configured in Godot first)
~/.local/bin/godot --headless --path /home/baltz/darkgrid --export-release "Web" export/index.html
```

---

## Common Gotchas

1. **Display required.** Godot needs a display for `run_project` and `launch_editor`. WSLg provides `:0`. If unavailable, use `Xvfb` or accept that only headless operations work.
2. **Headless for MCP.** Scene creation via MCP uses `--headless`. Do not confuse this with running the game.
3. **UID files (Godot 4.4+).** Godot generates `.uid` files for resources. They should be committed to git.
4. **`.import` files.** Godot creates `.import` files and `.godot/` cache. These are in `.gitignore` and must stay ignored.
5. **Browser load time.** Keep assets small. Test HTML5 export load time frequently.
6. **Signal disconnection.** Godot does not warn about disconnected signals. Always verify signal connections in the scene inspector after node renames.
7. **Scene file corruption.** Manual edits to `.tscn` files can corrupt scenes. Prefer MCP `add_node` or Godot editor for scene modifications.

---

## Session Protocol

Every session follows this sequence:

1. **Orient** — Read `PLAN.md`, check `git status`, read current milestone.
2. **Verify Baseline** — Run `run_project` smoke test. Ensure the game starts without errors before touching anything.
3. **Select One Task** — Pick the highest-priority incomplete item from the current milestone in `PLAN.md`.
4. **Implement** — Build the feature. Use MCP tools for scene creation when appropriate.
5. **Test** — Run smoke test + GUT tests. If visual changes, validate with screenshot.
6. **Update State** — Commit with a descriptive message. Mark task complete in `PLAN.md` if applicable.
7. **Clean Exit** — Confirm the game is in a working state.

**Rules:**
- One task per session. Do not batch unrelated changes.
- Commit after every successful task.
- If the agent discovers a bug (even unrelated), document it in `PLAN.md` under a "Known Issues" section, then fix or leave for a future session.
- Update `AGENTS.md` if a new gotcha is discovered.
