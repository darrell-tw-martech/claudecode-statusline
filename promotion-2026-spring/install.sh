#!/bin/bash
# Auto-install 2x promotion segment into Claude Code statusline
# Usage: bash install.sh [path-to-statusline.sh]

set -e

STATUSLINE="${1:-$HOME/.claude/statusline.sh}"

if [ ! -f "$STATUSLINE" ]; then
    echo "❌ Statusline not found: $STATUSLINE"
    echo "Usage: bash install.sh [path-to-statusline.sh]"
    exit 1
fi

# Check if already installed
if grep -q "2x Promotion" "$STATUSLINE" 2>/dev/null; then
    echo "⚠️  Already installed. Remove the existing block first if you want to reinstall."
    exit 0
fi

# Read the snippet
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNIPPET="$SCRIPT_DIR/promotion.sh"

if [ ! -f "$SNIPPET" ]; then
    echo "❌ promotion.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Detect pl_add function
if ! grep -q "pl_add" "$STATUSLINE"; then
    echo "⚠️  Your statusline.sh doesn't use pl_add()."
    echo "   This snippet requires a Powerline-style statusline with pl_add function."
    echo "   See README.md for manual integration instructions."
    exit 1
fi

# Backup
cp "$STATUSLINE" "${STATUSLINE}.bak.$(date +%s)"
echo "📋 Backup saved: ${STATUSLINE}.bak.*"

# Find insertion point: before the last pl_render call
# This places the segment at the end of Line 1
INSERTION_LINE=$(grep -n "pl_render" "$STATUSLINE" | head -1 | cut -d: -f1)

if [ -n "$INSERTION_LINE" ]; then
    # Insert before first pl_render
    {
        head -n $((INSERTION_LINE - 1)) "$STATUSLINE"
        echo ""
        cat "$SNIPPET"
        echo ""
        tail -n +$INSERTION_LINE "$STATUSLINE"
    } > "${STATUSLINE}.tmp"
    mv "${STATUSLINE}.tmp" "$STATUSLINE"
    echo "✅ Installed! The ⚡2x segment will appear in your statusline."
else
    # Fallback: append before last line
    echo "" >> "$STATUSLINE"
    cat "$SNIPPET" >> "$STATUSLINE"
    echo "✅ Installed (appended to end). You may need to adjust placement."
fi

echo ""
echo "📍 Promotion active: 2026-03-13 ~ 2026-03-27"
echo "   Off-peak (2x): outside EDT 8AM-2PM"
echo "   The segment auto-removes after 2026-03-28"
