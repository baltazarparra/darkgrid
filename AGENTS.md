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

All MCP tools are auto-approved in `.mcp.json` (the canonical MCP config; `.cursor/mcp.json` and `.kimi-code/mcp.json` are symlinks to it).

### Godot Path

- Executable: `/home/baltz/.local/bin/godot` (v4.6.3-stable)
- Project: `/home/baltz/caipora`
- Display: `:0` (WSLg — works for `run_project` and `launch_editor`)
- Headless mode is used automatically by MCP for scene operations.

---

## Directory Structure

Do not create new top-level folders without approval.

---

## Code Standards

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

When modifying input, arena, exploration, or timing — run `/validate-controls` first.

---

## Common Gotchas

1. **Display required.** Godot needs a display for `run_project` and `launch_editor`. WSLg provides `:0`. If unavailable, use `Xvfb` or accept that only headless operations work.
2. **Headless for MCP.** Scene creation via MCP uses `--headless`. Do not confuse this with running the game.
3. **UID files (Godot 4.4+).** Godot generates `.uid` files for resources. They should be committed to git.
4. **`.import` files.** Godot creates `.import` files and `.godot/` cache. These are in `.gitignore` and must stay ignored.
5. **Browser load time.** Keep assets small. Test HTML5 export load time frequently.
6. **Signal disconnection.** Godot does not warn about disconnected signals. Always verify signal connections in the scene inspector after node renames.
7. **Scene file corruption.** Manual edits to `.tscn` files can corrupt scenes. Prefer the Godot editor for scene modifications. **MCP `add_node` is also unsafe on scenes whose scripts reference autoloads**: the MCP runner loads scenes without autoloads, scripts fail to compile, and the re-saved `.tscn` silently loses scripts/exports/UIDs (and writes broken property values). After ANY MCP scene operation, check `git diff` on the `.tscn` and restore via git if mangled. For nodes only needed at runtime, prefer adding them from code (e.g. `ArenaBackdrop` adds the P1 `CanvasModulate` in `_ready()`).
8. **Tone consistency.** Do not sanitize horror. Blood, darkness, and hostility are intentional design choices.
9. **Dual input paths.** Two consumers, two sources: keyboard uses native Godot polling (`Input.is_action_pressed`); the touch D-pad (`ControlsHud`) injects via `Input.action_press` + `Input.parse_input_event`. Always run `/validate-controls` before committing changes to input, arena, exploration, or timing.
10. **Three target platforms.** iPhone 17 portrait Safari (~393px wide): `PortraitGuard` autoload (layer 128) shows "gire o dispositivo" overlay. Android Chrome PWA landscape: manifest locks orientation, safe areas handled by `ControlsHud`. Tablet+ landscape: arena zoom capped at 2.0x in `arena_manager.gd`. Run `/validate-platforms` before committing any UI, camera, or safe-area change.
11. **Version is build-stamped from git.** `make export` derives the version from the git commit count (`beta 2.<commits>`) and generates `scripts/core/build_info.gd` (gitignored) + `export/version.json`. The menu reads `build_info.gd` first and falls back to `project.godot`'s `config/version` (`"beta 2 (dev)"`) only when run from the editor. Do NOT hand-edit a version number expecting it to show up in the build — edit the scheme in the `Makefile` `export` target instead.
12. **New `class_name` needs `--import`, and GUT can lie green.** After creating a script with a new `class_name`, run `godot --headless --import` before `make test` — the global class cache in `.godot/` doesn't refresh on a plain test run, every script referencing the new class fails to parse, and **GUT silently skips test files that fail to parse** ("does not extend GutTest") while still reporting "All tests passed". After adding test files, confirm the total test count went UP in the GUT summary.

---

## Session Protocol

Run `/session-orient` at the start of each session (skill in `.claude/skills/session-orient/`).

**Rules:**
- One task per session. Do not batch unrelated changes.
- Commit after every successful task.
- If the agent discovers a bug (even unrelated), document it in `PLAN.md` under a "Known Issues" section, then fix or leave for a future session.
- Update `AGENTS.md` if a new gotcha is discovered.
- **Never soften the horror.** The forest is hostile. The Caipora is dangerous. The blood is real.
