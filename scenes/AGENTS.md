# AGENTS.md — scenes/

This folder contains all Godot `.tscn` scene files.

## Structure

```
scenes/
  ui/          — Menus, HUD, screens (CanvasLayer-based)
  exploration/ — Grid map, fog, tile layers
  arena/       — Combat arena backgrounds
  shared/      — Reusable components (health bar, damage number, timing cue)
```

## Rules

1. **One logical screen per scene.** `main_menu.tscn`, `exploration.tscn`, `arena.tscn`, `game_over.tscn`.
2. **Reusable components go in `shared/`.** Export them as `PackedScene` and instantiate where needed.
3. **Use `unique_name_in_owner = true` for nodes accessed from code.** Name them with `snake_case`.
4. **UI scenes:** CanvasLayer root, Control children, anchor to viewport edges.
5. **Arena scenes:** Node2D root, TileMapLayer or Sprite2D for background, spawn points as Marker2D nodes.
6. **Save scenes via MCP or Godot editor.** Do not hand-edit `.tscn` files.

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Screen scenes | `{screen_name}.tscn` | `main_menu.tscn`, `arena.tscn` |
| UI components | `{component_name}.tscn` | `health_bar.tscn`, `timing_cue.tscn` |
| Shared components | `{component_name}.tscn` | `damage_number.tscn` |
