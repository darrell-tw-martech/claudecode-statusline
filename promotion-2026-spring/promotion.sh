# Claude Code Statusline — 2x Usage Promotion Segment
# Promotion period: 2026-03-13 ~ 2026-03-27
# Weekdays: off-peak (2x) = outside EDT 8AM-2PM (UTC 12:00-18:00)
# Weekends: 2x all day
#
# Features:
#   - Shows ⚡2x (off-peak) or ⚡1x (peak) with Powerline colors
#   - Countdown: days left until promo ends
#   - Transition alert: "Xm→2x" when switch is within 60 minutes
#   - Configurable via ~/.claude/promo.conf
#
# Options (create ~/.claude/promo.conf to override):
#   PROMO_SHOW_TRANSITION=1  — show transition countdown in last 60 min
#   PROMO_SHOW_DAYS_LEFT=1   — show remaining days (e.g., "10d")
#
# Requirements:
#   - pl_add function defined in your statusline.sh
#   - Format: pl_add <line> <bg_color> <fg_color> <text>
#
# Usage:
#   Source or paste this snippet into your statusline.sh
#   Place it where you want the segment to appear

# ── 2x Promotion ──
PROMO_SHOW_TRANSITION=1
PROMO_SHOW_DAYS_LEFT=1
[ -f "$HOME/.claude/promo.conf" ] && source "$HOME/.claude/promo.conf"

PROMO_START="2026-03-13"
PROMO_END="2026-03-28"  # Last active day is 3/27
PROMO_GONE="2026-03-29" # Disappears after 3/28
TODAY_DATE=$(date '+%Y-%m-%d')
if [[ "$TODAY_DATE" < "$PROMO_GONE" ]] && [[ ! "$TODAY_DATE" < "$PROMO_START" ]]; then
    if [[ "$TODAY_DATE" < "$PROMO_END" ]]; then
        EDT_DOW=$(TZ='America/New_York' date '+%w')
        UTC_HOUR=$(date -u '+%H')
        UTC_MIN=$(date -u '+%M')
        UTC_HOUR_INT=$((10#$UTC_HOUR))
        UTC_MIN_INT=$((10#$UTC_MIN))

        # Days left (countdown to PROMO_END)
        PROMO_DAYS_LEFT=""
        if [ "$PROMO_SHOW_DAYS_LEFT" = "1" ]; then
            PROMO_END_EPOCH=$(date -j -f "%Y-%m-%d" "$PROMO_END" "+%s" 2>/dev/null)
            TODAY_EPOCH=$(date -j -f "%Y-%m-%d" "$TODAY_DATE" "+%s" 2>/dev/null)
            if [ -n "$PROMO_END_EPOCH" ] && [ -n "$TODAY_EPOCH" ]; then
                PROMO_DAYS_LEFT=$(( (PROMO_END_EPOCH - TODAY_EPOCH) / 86400 ))
            fi
        fi

        if [ "$EDT_DOW" -eq 0 ] || [ "$EDT_DOW" -eq 6 ]; then
            # Weekend: 2x all day
            PROMO_TEXT="⚡2x"
            [ -n "$PROMO_DAYS_LEFT" ] && PROMO_TEXT+=" ${PROMO_DAYS_LEFT}d"
            pl_add 1 173 232 "$PROMO_TEXT"
        else
            # Weekday: check peak hours (UTC 12-18 = EDT 8AM-2PM = peak 1x)
            IS_PEAK=0
            if [ "$UTC_HOUR_INT" -ge 12 ] && [ "$UTC_HOUR_INT" -lt 18 ]; then
                IS_PEAK=1
            fi

            # Transition detection: minutes until next switch
            PROMO_TRANSITION=""
            if [ "$PROMO_SHOW_TRANSITION" = "1" ]; then
                CURRENT_TOTAL_MIN=$((UTC_HOUR_INT * 60 + UTC_MIN_INT))
                PEAK_START_MIN=$((12 * 60))   # UTC 12:00
                PEAK_END_MIN=$((18 * 60))     # UTC 18:00

                if [ "$IS_PEAK" -eq 1 ]; then
                    MINS_TO_SWITCH=$((PEAK_END_MIN - CURRENT_TOTAL_MIN))
                else
                    if [ "$CURRENT_TOTAL_MIN" -lt "$PEAK_START_MIN" ]; then
                        MINS_TO_SWITCH=$((PEAK_START_MIN - CURRENT_TOTAL_MIN))
                    else
                        MINS_TO_SWITCH=$(( (24 * 60 - CURRENT_TOTAL_MIN) + PEAK_START_MIN ))
                    fi
                fi

                if [ "$MINS_TO_SWITCH" -le 60 ] && [ "$MINS_TO_SWITCH" -gt 0 ]; then
                    if [ "$IS_PEAK" -eq 1 ]; then
                        PROMO_TRANSITION=" │ ${MINS_TO_SWITCH}m→2x"
                    else
                        PROMO_TRANSITION=" │ ${MINS_TO_SWITCH}m→1x"
                    fi
                fi
            fi

            if [ "$IS_PEAK" -eq 1 ]; then
                PROMO_TEXT="⚡1x"
                [ -n "$PROMO_DAYS_LEFT" ] && PROMO_TEXT+=" ${PROMO_DAYS_LEFT}d"
                PROMO_TEXT+="$PROMO_TRANSITION"
                pl_add 1 239 245 "$PROMO_TEXT"
            else
                PROMO_TEXT="⚡2x"
                [ -n "$PROMO_DAYS_LEFT" ] && PROMO_TEXT+=" ${PROMO_DAYS_LEFT}d"
                PROMO_TEXT+="$PROMO_TRANSITION"
                pl_add 1 173 232 "$PROMO_TEXT"
            fi
        fi
    else
        # Day after promotion ends — red reminder
        pl_add 1 124 255 "⚡2x ended"
    fi
fi
