#!/bin/bash
# PreToolUse hook — runs make gate before any git commit.
# Receives tool input as JSON via stdin.
DIR="${CLAUDE_PROJECT_DIR:-.}"
INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    cmd = d.get('tool_input', d.get('input', {})).get('command', '')
    print(cmd)
except Exception:
    pass
" 2>/dev/null)
if echo "$CMD" | grep -q "git commit"; then
    make -C "$DIR" gate
fi
