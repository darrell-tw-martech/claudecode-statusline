#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Claude Code Statusline Installer                               ║
# ║  Copies statusline.sh to ~/.claude/ and updates settings.json   ║
# ╚══════════════════════════════════════════════════════════════════╝
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/statusline.sh"
TARGET="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

# ── Pre-flight checks ──
if [ ! -f "$SOURCE" ]; then
    echo "Error: statusline.sh not found in $SCRIPT_DIR"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install it first:"
    echo "  macOS:  brew install jq"
    echo "  Ubuntu: sudo apt install jq"
    exit 1
fi

mkdir -p "$HOME/.claude"

# ── Backup existing statusline ──
if [ -f "$TARGET" ]; then
    BACKUP="$TARGET.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$TARGET" "$BACKUP"
    echo "Backed up existing statusline to: $BACKUP"
fi

# ── Install ──
cp "$SOURCE" "$TARGET"
chmod +x "$TARGET"
echo "Installed statusline.sh to: $TARGET"

# ── Update settings.json ──
if [ -f "$SETTINGS" ]; then
    # Check if statusLine is already configured
    EXISTING=$(jq -r '.statusLine.command // empty' "$SETTINGS" 2>/dev/null)
    if [ -n "$EXISTING" ]; then
        echo "settings.json already has statusLine configured: $EXISTING"
        echo -n "Overwrite? [y/N] "
        read -r REPLY
        if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
            echo "Skipped settings.json update. You can manually set:"
            echo '  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }'
            exit 0
        fi
    fi
    # Add/update statusLine field
    TMP=$(mktemp)
    jq '.statusLine = { "type": "command", "command": "~/.claude/statusline.sh" }' "$SETTINGS" > "$TMP"
    mv "$TMP" "$SETTINGS"
    echo "Updated settings.json with statusLine config"
else
    # Create minimal settings.json
    echo '{ "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" } }' | jq . > "$SETTINGS"
    echo "Created settings.json with statusLine config"
fi

echo ""
echo "Done! Restart Claude Code to see your new statusline."
echo "The statusline updates after each assistant response."
