# Claude Code Statusline — 2x Usage Promotion Segment
# Promotion period: 2026-03-13 ~ 2026-03-27
# Weekdays: off-peak (2x) = outside EDT 8AM-2PM (UTC 12:00-18:00)
# Weekends: 2x all day
#
# Requirements:
#   - pl_add function defined in your statusline.sh
#   - Format: pl_add <line> <bg_color> <fg_color> <text>
#
# Usage:
#   Source or paste this snippet into your statusline.sh
#   Place it where you want the segment to appear (e.g., after message count)

# ── 2x Promotion ──
PROMO_END="2026-03-28"  # Last active day is 3/27
PROMO_GONE="2026-03-29" # Disappears after 3/28
TODAY_DATE=$(date '+%Y-%m-%d')
if [[ "$TODAY_DATE" < "$PROMO_GONE" ]]; then
    if [[ "$TODAY_DATE" < "$PROMO_END" ]]; then
        # Check EDT day of week (0=Sun, 6=Sat)
        EDT_DOW=$(TZ='America/New_York' date '+%w')
        if [ "$EDT_DOW" -eq 0 ] || [ "$EDT_DOW" -eq 6 ]; then
            # Weekend: 2x all day
            pl_add 1 173 232 "⚡2x"
        else
            # Weekday: check peak hours
            UTC_HOUR=$(date -u '+%H')
            UTC_HOUR_INT=$((10#$UTC_HOUR))
            if [ "$UTC_HOUR_INT" -ge 12 ] && [ "$UTC_HOUR_INT" -lt 18 ]; then
                # Peak (EDT 8AM-2PM) — muted gray
                pl_add 1 239 245 "⚡1x"
            else
                # Off-peak — Claude orange, usage doubled
                pl_add 1 173 232 "⚡2x"
            fi
        fi
    else
        # Day after promotion ends — red reminder
        pl_add 1 124 255 "⚡2x ended"
    fi
fi
