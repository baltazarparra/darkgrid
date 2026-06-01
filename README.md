# darkgrid

Roguelike game built with Godot 4.6

## MCP (Model Context Protocol)

This project has the [Godot MCP Server](https://github.com/Coding-Solo/godot-mcp) installed and configured.

### Installed Tools

- `launch_editor` — Launch Godot editor for this project
- `run_project` — Run the project and capture output
- `get_debug_output` — Get current debug output and errors
- `stop_project` — Stop the running project
- `get_godot_version` — Get installed Godot version
- `list_projects` — List Godot projects in a directory
- `get_project_info` — Get project metadata
- `create_scene` — Create a new scene file
- `add_node` — Add a node to an existing scene
- `load_sprite` — Load a sprite into a Sprite2D node
- `export_mesh_library` — Export a scene as MeshLibrary
- `save_scene` — Save changes to a scene
- `get_uid` / `update_project_uids` — UID management (Godot 4.4+)

### Configuration Files

- `mcp.json` — Generic MCP client configuration
- `.cursor/mcp.json` — Cursor IDE configuration
- `scripts/mcp-wrapper.sh` — Wrapper script with `GODOT_PATH` preset

### Godot Location

- Executable: `~/.local/bin/godot` (v4.6.3-stable)

### Project Structure

```
darkgrid/
├── project.godot
├── icon.svg
├── scenes/
├── scripts/
├── assets/
├── mcp.json
└── scripts/mcp-wrapper.sh
```
