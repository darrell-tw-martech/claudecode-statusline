# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code statusline segment that shows whether the user is in the **2x usage** (off-peak) or **1x** (peak) period during Anthropic's March 2026 promotion (3/13–3/27). Includes days remaining countdown and transition alerts.

## Architecture

- **`promotion.sh`** — The statusline snippet. Two variants exist:
  - Powerline version (default): uses `pl_add <line> <bg> <fg> <text>` to render colored segments
  - Inline version (in README): uses raw ANSI escape codes, outputs `$PROMO_LABEL` variable
- **`install.sh`** — Auto-installer for Powerline-style statuslines. Detects `pl_add` usage, backs up `~/.claude/statusline.sh`, inserts snippet before `pl_render`.
- **`~/.claude/promo.conf`** — Optional user config file. Controls two boolean flags:
  - `PROMO_SHOW_TRANSITION` — show "Xm→2x" countdown in last 60 min before switch
  - `PROMO_SHOW_DAYS_LEFT` — show remaining days (e.g., "10d")

## Key Logic

Peak/off-peak is determined by **UTC hour** (not local time):
- UTC 12:00–18:00 = EDT 8AM–2PM = peak (1x, muted gray)
- All other hours = off-peak (2x, orange)
- Weekends (EDT) = 2x all day

Transition countdown:
- Calculates minutes until next peak/off-peak switch
- Only shown when ≤ 60 minutes remain
- Format: `│ 42m→1x` or `│ 15m→2x` appended to main badge

Date lifecycle:
- Before `2026-03-13`: segment hidden
- `2026-03-13` to `2026-03-27`: active, shows 1x/2x with optional days left + transition
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
TZ=UTC faketime '2026-03-15 11:30:00' bash promotion.sh  # should show 2x + "│ 30m→1x"
TZ=UTC faketime '2026-03-15 17:45:00' bash promotion.sh  # should show 1x + "│ 15m→2x"
TZ=UTC faketime '2026-03-28 10:00:00' bash promotion.sh  # should show ended
TZ=UTC faketime '2026-03-29 10:00:00' bash promotion.sh  # should show nothing
```

## Conventions

- Colors use 256-color terminal codes (e.g., 173=Claude orange, 239=dark gray, 124=red)
- `10#$UTC_HOUR` forces base-10 parsing to avoid octal issues with leading zeros (e.g., `08`)
- Date comparisons use string comparison (`<`) which works for ISO format dates
- Transition uses `│` (box-drawing U+2502) as separator — chosen via A/B testing over `·`, `←`, `/`
- **Two snippet variants must stay in sync**: `promotion.sh` (Powerline) and README inline (ANSI). They have slightly different code structure but identical behavior. When modifying one, check the other.

## Statusline 技術備註

- **rate_limits stdin（2.1.80+）已取代 OAuth curl**：`~/.claude/statusline.sh` 從 stdin JSON 的 `rate_limits.five_hour` / `rate_limits.seven_day` 讀取配額，不再用 `curl https://api.anthropic.com/api/oauth/usage`。OAuth 版本備份在 `~/.claude/statusline-oauth.sh.bak`（OAuth 獨有 `seven_day_sonnet` 和 `extra_usage` 欄位）。
- **stdin JSON 不提供 permission mode**（2.1.80）：bypass/default/plan 狀態由 Claude Code UI 直接渲染，不經過 statusline script。不要再花時間調查。

## Git Push

This repo belongs to the `darrell-tw-martech` org. The user's default GitHub account is `Darrellwan`, which has no push access.

```bash
# Before push
gh auth switch --user darrell-tw-martech
git push
# After push — switch back
gh auth switch --user Darrellwan
```
