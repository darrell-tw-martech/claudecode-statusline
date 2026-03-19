# Claude Code Statusline — 2x Promotion Tracker

Anthropic is [doubling usage limits](https://support.anthropic.com/en/articles/11360-claude-march-2026-usage-promotion) during off-peak hours through March 27, 2026. But Claude Code doesn't tell you when you're in 2x mode.

This statusline segment fixes that — showing peak/off-peak status, days remaining, and a transition countdown, right in your terminal.

## What it looks like

| Status | Badge | When |
|--------|-------|------|
| Off-peak | ![2x](https://img.shields.io/badge/%E2%9A%A1%202x%2010d-C4724A?style=flat-square) | Usage doubled |
| Peak | ![1x](https://img.shields.io/badge/%E2%9A%A1%201x%2010d-4E4E4E?style=flat-square) | Normal usage |
| Transition | ![transition](https://img.shields.io/badge/%E2%9A%A1%202x%2010d%20%E2%94%82%2042m%E2%86%921x-C4724A?style=flat-square) | Switch within 60 min |
| Ended | ![ended](https://img.shields.io/badge/%E2%9A%A1%202x%20ended-AF0000?style=flat-square) | 3/28 only, then auto-removes |

**Features:**
- Days remaining until promo ends (`10d`)
- Transition countdown when switch is within 60 minutes (`│ 42m→1x`)
- Both features are optional — configure via `~/.claude/promo.conf`

## Setup

### Option 1: Paste into your statusline.sh (30 seconds)

Copy this into your `~/.claude/statusline.sh` where you want it to appear:

```bash
# 2x Promotion (2026-03-13 ~ 2026-03-27)
# Options: set PROMO_SHOW_TRANSITION=0 or PROMO_SHOW_DAYS_LEFT=0 to disable
PROMO_SHOW_TRANSITION=1
PROMO_SHOW_DAYS_LEFT=1
[ -f "$HOME/.claude/promo.conf" ] && source "$HOME/.claude/promo.conf"
PROMO_START="2026-03-13"; PROMO_END="2026-03-28"; PROMO_GONE="2026-03-29"
TODAY_DATE=$(date '+%Y-%m-%d')
if [[ "$TODAY_DATE" < "$PROMO_GONE" ]] && [[ ! "$TODAY_DATE" < "$PROMO_START" ]]; then
    if [[ "$TODAY_DATE" < "$PROMO_END" ]]; then
        EDT_DOW=$(TZ='America/New_York' date '+%w')
        UTC_HOUR=$(date -u '+%H'); UTC_MIN=$(date -u '+%M')
        UTC_HOUR_INT=$((10#$UTC_HOUR)); UTC_MIN_INT=$((10#$UTC_MIN))
        PROMO_DAYS_LEFT=""
        if [ "$PROMO_SHOW_DAYS_LEFT" = "1" ]; then
            PROMO_END_EPOCH=$(date -j -f "%Y-%m-%d" "$PROMO_END" "+%s" 2>/dev/null)
            TODAY_EPOCH=$(date -j -f "%Y-%m-%d" "$TODAY_DATE" "+%s" 2>/dev/null)
            [ -n "$PROMO_END_EPOCH" ] && [ -n "$TODAY_EPOCH" ] && \
                PROMO_DAYS_LEFT=$(( (PROMO_END_EPOCH - TODAY_EPOCH) / 86400 ))
        fi
        if [ "$EDT_DOW" -eq 0 ] || [ "$EDT_DOW" -eq 6 ]; then
            PROMO_LABEL="\033[38;5;232;48;5;173m ⚡2x"
            [ -n "$PROMO_DAYS_LEFT" ] && PROMO_LABEL+=" ${PROMO_DAYS_LEFT}d"
            PROMO_LABEL+=" \033[0m"
        else
            IS_PEAK=0
            [ "$UTC_HOUR_INT" -ge 12 ] && [ "$UTC_HOUR_INT" -lt 18 ] && IS_PEAK=1
            PROMO_TRANSITION=""
            if [ "$PROMO_SHOW_TRANSITION" = "1" ]; then
                CURRENT_TOTAL_MIN=$((UTC_HOUR_INT * 60 + UTC_MIN_INT))
                if [ "$IS_PEAK" -eq 1 ]; then
                    MINS_TO_SWITCH=$((18 * 60 - CURRENT_TOTAL_MIN))
                elif [ "$CURRENT_TOTAL_MIN" -lt $((12 * 60)) ]; then
                    MINS_TO_SWITCH=$((12 * 60 - CURRENT_TOTAL_MIN))
                else
                    MINS_TO_SWITCH=$(( (24 * 60 - CURRENT_TOTAL_MIN) + 12 * 60 ))
                fi
                if [ "$MINS_TO_SWITCH" -le 60 ] && [ "$MINS_TO_SWITCH" -gt 0 ]; then
                    [ "$IS_PEAK" -eq 1 ] && PROMO_TRANSITION=" │ ${MINS_TO_SWITCH}m→2x" \
                                          || PROMO_TRANSITION=" │ ${MINS_TO_SWITCH}m→1x"
                fi
            fi
            if [ "$IS_PEAK" -eq 1 ]; then
                PROMO_LABEL="\033[38;5;245;48;5;239m ⚡1x"
                [ -n "$PROMO_DAYS_LEFT" ] && PROMO_LABEL+=" ${PROMO_DAYS_LEFT}d"
                PROMO_LABEL+="${PROMO_TRANSITION} \033[0m"
            else
                PROMO_LABEL="\033[38;5;232;48;5;173m ⚡2x"
                [ -n "$PROMO_DAYS_LEFT" ] && PROMO_LABEL+=" ${PROMO_DAYS_LEFT}d"
                PROMO_LABEL+="${PROMO_TRANSITION} \033[0m"
            fi
        fi
    else
        PROMO_LABEL="\033[38;5;255;48;5;124m ⚡2x ended \033[0m"
    fi
fi
```

Then add `$PROMO_LABEL` to your `echo` output. No frameworks or dependencies needed.

### Option 2: Let AI install it

If you use Claude Code or another AI coding assistant, just say:

> Read https://github.com/darrell-tw-martech/claudecode-statusline/blob/main/promotion-2026-spring/promotion.sh and add it to my statusline.sh

The code is fully commented — any AI can integrate it directly.

### Option 3: Auto-install (Powerline style)

If your statusline uses the `pl_add` function (Powerline segment style):

```bash
git clone https://github.com/darrell-tw-martech/claudecode-statusline.git
cd claudecode-statusline/promotion-2026-spring
bash install.sh
```

The script detects `~/.claude/statusline.sh`, creates a backup, and inserts the segment.

## Configuration

Create `~/.claude/promo.conf` to toggle features:

```bash
# Show transition countdown in last 60 min before switch (default: 1)
PROMO_SHOW_TRANSITION=1

# Show remaining days until promo ends (default: 1)
PROMO_SHOW_DAYS_LEFT=1
```

## Peak hours by timezone

| Timezone | Peak (1x) | Full workday in 2x? |
|----------|-----------|---------------------|
| Taiwan (CST) | 8:00 PM – 2:00 AM | Yes |
| Japan (JST) | 9:00 PM – 3:00 AM | Yes |
| India (IST) | 5:30 PM – 11:30 PM | Yes |
| Australia (AEDT) | 11:00 PM – 5:00 AM | Yes |
| UK (GMT) | 12:00 PM – 6:00 PM | No (afternoon overlap) |
| US West (PDT) | 5:00 AM – 11:00 AM | No (morning overlap) |
| US East (EDT) | 8:00 AM – 2:00 PM | No (full overlap) |

Weekends (EDT) are 2x all day.

> Off-peak usage does **not** count toward your 7-day rolling limit.

## How it works

```
Weekend (EDT Sat/Sun)        → 2x all day
Weekday UTC 12:00–18:00      → Peak (1x)
Weekday all other hours      → Off-peak (2x)
Within 60 min of switch      → Shows countdown (e.g., "│ 42m→1x")
```

The segment auto-appears on 3/13, shows "ended" on 3/28, and disappears on 3/29.

## Requirements

- Claude Code with custom statusline enabled (`~/.claude/statusline.sh`)
- Bash 3.2+ (macOS built-in)

## License

[MIT](./LICENSE)

---

Made by [Darrell Wang](https://www.threads.net/@darrell_tw_)
