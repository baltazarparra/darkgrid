#!/bin/bash
# Wrapper script for Godot MCP Server
# Automatically sets GODOT_PATH for the darkgrid project

export GODOT_PATH="${HOME}/.local/bin/godot"
export DEBUG="${DEBUG:-true}"

exec npx @coding-solo/godot-mcp "$@"
