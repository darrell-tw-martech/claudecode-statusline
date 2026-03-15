# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code statusline segment that shows whether the user is in the **2x usage** (off-peak) or **1x** (peak) period during Anthropic's March 2026 promotion (3/13–3/27).

## Architecture

- **`promotion.sh`** — The statusline snippet. Two variants exist:
  - Powerline version (default): uses `pl_add <line> <bg> <fg> <text>` to render colored segments
  - Inline version (in README): uses raw ANSI escape codes, outputs `$PROMO_LABEL` variable
- **`install.sh`** — Auto-installer for Powerline-style statuslines. Detects `pl_add` usage, backs up `~/.claude/statusline.sh`, inserts snippet before `pl_render`.

## Key Logic

Peak/off-peak is determined by **UTC hour** (not local time):
- UTC 12:00–18:00 = EDT 8AM–2PM = peak (1x, muted gray)
- All other hours = off-peak (2x, orange)

Date lifecycle:
- Before `2026-03-28`: active, shows 1x/2x
- On `2026-03-28`: shows "2x ended" (red)
- From `2026-03-29`: segment disappears entirely

## Testing

No test suite. To verify:

```bash
# Test the snippet directly (Powerline version needs pl_add defined)
source promotion.sh

# Test with mocked time
TZ=UTC faketime '2026-03-15 10:00:00' bash promotion.sh  # should show 2x
TZ=UTC faketime '2026-03-15 14:00:00' bash promotion.sh  # should show 1x
TZ=UTC faketime '2026-03-28 10:00:00' bash promotion.sh  # should show ended
TZ=UTC faketime '2026-03-29 10:00:00' bash promotion.sh  # should show nothing
```

## Conventions

- Colors use 256-color terminal codes (e.g., 173=Claude orange, 239=dark gray, 124=red)
- `10#$UTC_HOUR` forces base-10 parsing to avoid octal issues with leading zeros (e.g., `08`)
- Date comparisons use string comparison (`<`) which works for ISO format dates
- **Two snippet variants must stay in sync**: `promotion.sh` (Powerline) and README inline (ANSI). They have slightly different code structure but identical behavior. When modifying one, check the other.
