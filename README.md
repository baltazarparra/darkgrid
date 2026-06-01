# darkgrid

> A combat-focused 2D pixel-art roguelike built with Godot 4.6.  
> Play it in the browser on [itch.io](https://itch.io) (link coming soon).

---

## What is darkgrid?

**darkgrid** reimagines the roguelike combat loop with a **timing-based action system** inspired by *Legend of Dragoon* and *Clair Obscur*.

- **Press Space at the right moment** to land a **critical hit** (2x–3x damage).
- **Press Space at the right moment** to **perfect dodge** an enemy attack and **counter-attack**.

Every strike, dodge, and death is packed with juicy feedback: screen shake, particle bursts, hit-stop frames, and crisp sound effects.

### Gameplay Loop

1. **Explore** — Move on a grid between arenas (turn-based).
2. **Fight** — Enter an arena and battle in real-time with timing mechanics.
3. **Die or Win** — Learn from failure. Unlock permanent upgrades. Try again.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Engine | Godot 4.6.3 |
| Language | GDScript |
| Art | Pixel art (16×16 / 32×32 sprites) |
| Audio | `.ogg` music, `.wav` SFX |
| Platform | Browser-first (HTML5 / itch.io) |
| AI Agent | Kimi-k2.6 via Kimi Code CLI + Godot MCP |

---

## Project Structure

```
darkgrid/
├── assets/          — Sprites, tilesets, audio, fonts
├── scenes/          — Godot scenes (UI, exploration, arena, shared)
├── scripts/         — GDScript source code
│   ├── core/        — Autoloads (GameState, SignalBus, MetaProgression)
│   ├── systems/     — TimingSystem, CombatSystem, FeedbackSystem
│   ├── entities/    — Player, Enemy
│   ├── exploration/ — Grid logic, TurnManager
│   ├── arena/       — ArenaManager, attack patterns
│   └── utils/       — Helpers, constants
├── tests/           — GUT unit tests
├── docs/            — Design documents
├── PLAN.md          — Full product & technical specification
├── AGENTS.md        — AI agent harness instructions
└── .kimi-code/mcp.json — Kimi Code MCP configuration
```

---

## Running Locally

```bash
# Requires Godot 4.6+ installed at ~/.local/bin/godot
# Display :0 must be available (WSLg on Windows, native X11 on Linux)

~/.local/bin/godot --path /home/baltz/darkgrid
```

### Running Tests

```bash
# Requires GUT addon installed
~/.local/bin/godot --headless --path /home/baltz/darkgrid -s res://addons/gut/gut_cmdln.gd
```

### Exporting to HTML5

```bash
# Configure the Web export preset in Godot first
~/.local/bin/godot --headless --path /home/baltz/darkgrid --export-release "Web" export/index.html
```

---

## MCP (Model Context Protocol)

This project uses the **Godot MCP Server** (`@coding-solo/godot-mcp`) so AI agents can interact directly with the Godot editor and runtime.

### Available MCP Tools

| Tool | Description |
|------|-------------|
| `create_scene` | Create a new `.tscn` file |
| `add_node` | Add a node to an existing scene |
| `save_scene` | Save changes to a scene |
| `run_project` | Run the game and capture output |
| `get_debug_output` | Read stdout/stderr from the running game |
| `stop_project` | Stop the running game |
| `launch_editor` | Open the Godot editor |

### Configuration

- **Kimi Code CLI:** `.kimi-code/mcp.json`
- **Cursor:** `.cursor/mcp.json`
- **Wrapper script:** `scripts/mcp-wrapper.sh` (sets `GODOT_PATH`)

---

## Development Harness

This project follows **Harness Engineering** principles:

- **Feedforward:** `AGENTS.md` and `PLAN.md` guide the agent before it acts.
- **Feedback:** Smoke tests, GUT unit tests, and visual screenshots validate every change.
- **Memory:** Git commits, milestone tracking in `PLAN.md`, and evolving `AGENTS.md`.

Read `AGENTS.md` before contributing (human or agent).

---

## Milestones

| Phase | Goal | Status |
|-------|------|--------|
| 1 | Grid + Player movement | 🔲 Not started |
| 2 | Arena + Timing system | 🔲 Not started |
| 3 | Enemy AI + Boss | 🔲 Not started |
| 4 | Meta-progression + Polish | 🔲 Not started |
| 5 | Export HTML5 + itch.io | 🔲 Not started |

See `PLAN.md` for full milestone details.

---

## License

MIT
