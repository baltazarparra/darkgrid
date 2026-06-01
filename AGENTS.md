# AGENTS.md — caipora

This file guides the AI coding agent (Claude Code, Kimi Code, or Cursor) when working on the **caipora** project. It is the single source of truth — `CLAUDE.md` at each level is a symlink to the `AGENTS.md` beside it.

## Project Overview

**caipora** is a browser-first 2D pixel-art roguelike set in Brazilian folk horror.

You play as the **Caipora**, guardian of the forest, awakening in a corrupted woodland where ancient pacts between humans, beasts, the dead, rivers, and enchanted beings have been broken.

The core mechanic is **timing-based combat**:
- Press **Space** at the right frame to land a **critical hit** (2x–3x damage).
- Press **Space** at the right frame to **perfect dodge** an enemy attack and **counter-attack**.

The full product spec is in `PLAN.md`. Read it before every session.

**Tone:** GORE / TERROR / SANGRENTO. The forest is hostile. The Caipora is dangerous. Do not sanitize the horror.

---

## Harness Layer — Agent Interaction Model

This project uses the **Godot MCP Server** (`@coding-solo/godot-mcp`) to let the agent create scenes, add nodes, and control the Godot editor programmatically.

### MCP Tools Available

| Tool | When to use |
|------|-------------|
| `create_scene` | Create a new `.tscn` file |
| `add_node` | Add a node to an existing scene |
| `save_scene` | Save changes to a scene |
| `load_sprite` | Load a sprite onto a node |
| `export_mesh_library` | Export a MeshLibrary resource |
| `run_project` | Run the game and capture output |
| `get_debug_output` | Read stdout/stderr from the running game |
| `stop_project` | Stop the running game process |
| `launch_editor` | Open the Godot editor |
| `get_godot_version` | Verify installed Godot version |
| `get_project_info` | Read project metadata |
| `list_projects` | List known Godot projects |
| `get_uid` | Get the UID for a resource |
| `update_project_uids` | Refresh `.uid` references project-wide |

All 14 tools are auto-approved in `.mcp.json` (the canonical MCP config; `.cursor/mcp.json` and `.kimi-code/mcp.json` are symlinks to it).

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
| Art | Pixel art — CC0 (Kenney). One pack only for consistency. |
| Audio | `.wav` SFX (jsfxr / sfxr) — no music in MVP |
| Distribution | itch.io HTML5 export |
| Tests | GUT (Godot Unit Test) |
| Agent Tools | `@coding-solo/godot-mcp` |

---

## Directory Structure

Place files in the correct directory. Do not create new top-level folders without approval.

```
assets/
  sprites/     — All sprites: characters, enemies, tiles, items (.png)
  audio/sfx/   — Sound effects (.wav, jsfxr/sfxr)
  fonts/       — Pixel font (.ttf / .otf)
  licenses/    — CC0 licenses and attribution

scenes/
  ui/          — Menus, HUD, screens
  exploration/ — Grid map, fog, tile layers
  arena/       — Combat arenas
  shared/      — Reusable components (health bar, damage number, etc.)

scripts/
  core/        — Autoloads: GameState, SignalBus, MetaProgression
  systems/     — TimingSystem, CombatSystem, FeedbackSystem
  entities/    — Caipora, Criatura base classes
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
- **State machines.** Caipora and Criatura behaviors use `StateMachine` (explore → combat → dead).
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

- **Arena scene:** `ArenaManager` (Node2D) owns background, spawns `Caipora` and `Criatura` instances.
- **UI scenes:** CanvasLayer-based, anchored to viewport.
- **Reusable components:** Export as `@export var reusable_scene: PackedScene` and instantiate.

---

## Development Commands

The harness commands live in the `Makefile` (single source of truth). Run them from
the repo root. Override the Godot binary with `make test GODOT=/path/to/godot`.

```bash
make smoke    # boot headless ~50 frames and exit (smoke test)
make test     # run the GUT regression gate (tests/unit)
make export   # build the reproducible HTML5 release into export/
make gate     # smoke + test (run before every commit)
```

Run the game with a display (WSLg provides `:0`):

```bash
~/.local/bin/godot --path .
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
8. **Tone consistency.** Do not sanitize horror. Blood, darkness, and hostility are intentional design choices.

---

## Session Protocol

Every session follows this sequence:

1. **Orient** — Read `PLAN.md`, check `git status`, read current milestone.
2. **Verify Baseline** — Run `make smoke` (or `run_project`). Ensure the game starts without errors before touching anything.
3. **Select One Task** — Pick the highest-priority incomplete item from the current milestone in `PLAN.md`.
4. **Implement** — Build the feature. Use MCP tools for scene creation when appropriate.
5. **Test** — Run `make gate` (smoke + GUT tests). If visual changes, validate with screenshot.
6. **Update State** — Commit with a descriptive message. Mark task complete in `PLAN.md` if applicable.
7. **Clean Exit** — Confirm the game is in a working state.

**Rules:**
- One task per session. Do not batch unrelated changes.
- Commit after every successful task.
- If the agent discovers a bug (even unrelated), document it in `PLAN.md` under a "Known Issues" section, then fix or leave for a future session.
- Update `AGENTS.md` if a new gotcha is discovered.
- **Never soften the horror.** The forest is hostile. The Caipora is dangerous. The blood is real.
