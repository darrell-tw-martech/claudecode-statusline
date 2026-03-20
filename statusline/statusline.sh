#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Claude Code Powerline Statusline                               ║
# ║  A full-featured, two-line Powerline statusline for Claude Code ║
# ║  Requires: bash, jq, git (optional), bc (optional)             ║
# ║  Tested on: Claude Code 2.1.80+ (macOS / Linux)                ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Line 1: Model·Effort → Dir → ProjType → Branch → Changes → Commits → MsgCount → [Seasonal] → WorkTime
# Line 2: Context bar → 5h quota → 7d quota → Cost
#
# ─────────────────────────────────────────────────────────
# MODULE INDEX (search "══ MODULE:" to jump)
# ─────────────────────────────────────────────────────────
# CORE          — JSON parse, pl_add, pl_render, mini_bar  (required by all)
# git-info      — branch, dirty status, today's commits    (needs: CORE)
# work-time     — session duration from transcript mtime   (needs: CORE)
# project-type  — detect JS/PY/RS/GO from config files     (needs: CORE)
# msg-count     — message count from transcript JSONL       (needs: CORE)
# context-bar   — context window usage with 8-segment bar   (needs: CORE)
# lines-changed — +added/-removed from cost data            (needs: CORE)
# session-cost  — session cost in USD                       (needs: CORE)
# rate-limits   — 5h/7d quota with ●○ bar + reset countdown (needs: CORE, mini_bar)
# effort        — thinking effort level from transcript      (needs: CORE)
# promo         — [SEASONAL] 2x off-peak promotion tracker  (needs: CORE, pl_add)
# ─────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════
# ══ CORE: JSON input + shared utilities ══
# Required by all modules. Do not remove.
# ══════════════════════════════════════════════════════════
JSON=$(cat)

# ── JSON field extraction ──
MODEL=$(echo "$JSON" | jq -r '.model.display_name // "Unknown"')
DIR=$(echo "$JSON" | jq -r '.workspace.current_dir // "Unknown"' | xargs basename)
SESSION_ID=$(echo "$JSON" | jq -r '.session_id // "Unknown"')
TRANSCRIPT_PATH=$(echo "$JSON" | jq -r '.transcript_path // ""')
NOW=$(date +%s)

# ── Powerline renderer ──
# Builds colored segments with  arrow separators.
# Usage: pl_add <line> <bg_256color> <fg_256color> <text>
#        pl_render <array_name>
L1_SEGS=()
L2_SEGS=()

pl_add() {
    local target=$1 bg=$2 fg=$3 text=$4
    if [ "$target" = "1" ]; then
        L1_SEGS+=("${bg}:${fg}:${text}")
    else
        L2_SEGS+=("${bg}:${fg}:${text}")
    fi
}

pl_render() {
    local arr_name=$1
    local out=""
    eval "local count=\${#${arr_name}[@]}"
    for ((i=0; i<count; i++)); do
        eval "local seg=\${${arr_name}[$i]}"
        IFS=':' read -r bg fg text <<< "$seg"
        out+="\033[38;5;${fg};48;5;${bg}m ${text} "
        if [ $((i+1)) -lt "$count" ]; then
            eval "local next_seg=\${${arr_name}[$((i+1))]}"
            IFS=':' read -r next_bg _ _ <<< "$next_seg"
            out+="\033[38;5;${bg};48;5;${next_bg}m"
        else
            out+="\033[0m\033[38;5;${bg}m\033[0m"
        fi
    done
    echo -e "$out"
}

# ── mini_bar: ●○ dot progress bar (10 cells) ──
# Usage: mini_bar <percentage>
# Used by: rate-limits
mini_bar() {
    local pct=$1
    local filled=$((pct / 10))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="●"; done
    for ((i=filled; i<10; i++)); do bar+="○"; done
    echo "$bar"
}

# ══════════════════════════════════════════════════════════
# ══ MODULE: git-info ══
# Branch name, dirty indicator (*), today's commit count.
# Needs: CORE
# ══════════════════════════════════════════════════════════
BRANCH=$(git branch --show-current 2>/dev/null || echo "no-git")
GIT_STATUS=""
if [ "$BRANCH" != "no-git" ]; then
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        GIT_STATUS="*"
    fi
fi

TODAY_COMMITS=""
COMMIT_COUNT=0
if [ "$BRANCH" != "no-git" ]; then
    TODAY=$(date '+%Y-%m-%d')
    COMMIT_COUNT=$(git log --oneline --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" 2>/dev/null | wc -l | xargs)
fi

# ══════════════════════════════════════════════════════════
# ══ MODULE: work-time ══
# Session duration derived from transcript file mtime.
# Needs: CORE ($TRANSCRIPT_PATH)
# ══════════════════════════════════════════════════════════
WORK_TIME=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        TRANSCRIPT_TIME=$(stat -f %m "$TRANSCRIPT_PATH" 2>/dev/null)
    else
        TRANSCRIPT_TIME=$(stat -c %Y "$TRANSCRIPT_PATH" 2>/dev/null)
    fi
    if [ -n "$TRANSCRIPT_TIME" ]; then
        WORK_SECONDS=$(( NOW - TRANSCRIPT_TIME ))
        if [ "$WORK_SECONDS" -gt 0 ]; then
            HOURS=$((WORK_SECONDS / 3600))
            MINUTES=$(((WORK_SECONDS % 3600) / 60))
            if [ "$HOURS" -gt 0 ]; then
                WORK_TIME="${HOURS}h${MINUTES}m"
            elif [ "$MINUTES" -gt 0 ]; then
                WORK_TIME="${MINUTES}m"
            else
                WORK_TIME="<1m"
            fi
        fi
    fi
fi

# ══════════════════════════════════════════════════════════
# ══ MODULE: project-type ══
# Detect project language from config files in cwd.
# Needs: CORE
# ══════════════════════════════════════════════════════════
PROJECT_TYPE=""
if [ -f "package.json" ]; then
    PROJECT_TYPE="JS"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    PROJECT_TYPE="PY"
elif [ -f "Cargo.toml" ]; then
    PROJECT_TYPE="RS"
elif [ -f "go.mod" ]; then
    PROJECT_TYPE="GO"
fi

# ══════════════════════════════════════════════════════════
# ══ MODULE: msg-count ══
# Count messages in the transcript JSONL file.
# Needs: CORE ($TRANSCRIPT_PATH)
# ══════════════════════════════════════════════════════════
MSG_COUNT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    COUNT=$(grep -c '"role":' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
    if [ "$COUNT" -gt 0 ]; then
        MSG_COUNT="$COUNT"
    fi
fi

# ══════════════════════════════════════════════════════════
# ══ MODULE: context-bar ══
# Context window usage with 8-segment Unicode block bar.
# Color thresholds: <50% green, 50-79% yellow, ≥80% red.
# Needs: CORE ($JSON)
# ══════════════════════════════════════════════════════════
PERCENT_USED=$(echo "$JSON" | jq -r '.context_window.used_percentage // 0')

# ══════════════════════════════════════════════════════════
# ══ MODULE: lines-changed ══
# Lines added/removed in the current session.
# Needs: CORE ($JSON)
# ══════════════════════════════════════════════════════════
LINES_ADDED=$(echo "$JSON" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$JSON" | jq -r '.cost.total_lines_removed // 0')

# ══════════════════════════════════════════════════════════
# ══ MODULE: session-cost ══
# Cumulative API cost for the current session.
# Needs: CORE ($JSON)
# ══════════════════════════════════════════════════════════
SESSION_COST=$(echo "$JSON" | jq -r '.cost.total_cost_usd // 0')

# ══════════════════════════════════════════════════════════
# ══ MODULE: rate-limits ══
# 5-hour and 7-day rolling quota from stdin JSON.
# Requires Claude Code 2.1.80+ (rate_limits field in stdin).
# Includes ●○ progress bar, reset countdown, and 7d pacing.
# Needs: CORE ($JSON, $NOW), mini_bar
# ══════════════════════════════════════════════════════════
LIMIT_5H=""
LIMIT_7D=""

UTIL_5H=$(echo "$JSON" | jq -r '.rate_limits.five_hour.used_percentage // empty')
RESET_5H_EPOCH=$(echo "$JSON" | jq -r '.rate_limits.five_hour.resets_at // empty')
UTIL_7D=$(echo "$JSON" | jq -r '.rate_limits.seven_day.used_percentage // empty')
RESET_7D_EPOCH=$(echo "$JSON" | jq -r '.rate_limits.seven_day.resets_at // empty')

# 5hr
UTIL_5H_INT=0
if [ -n "$UTIL_5H" ] && [ "$UTIL_5H" != "null" ]; then
    UTIL_5H_INT=${UTIL_5H%.*}
    BAR_5H=$(mini_bar "$UTIL_5H_INT")
    RESET_5H_TEXT=""
    if [ -n "$RESET_5H_EPOCH" ] && [ "$RESET_5H_EPOCH" -gt "$NOW" ] 2>/dev/null; then
        REMAIN=$((RESET_5H_EPOCH - NOW))
        RH=$((REMAIN / 3600))
        RM=$(((REMAIN % 3600) / 60))
        RESET_5H_TEXT=" ⏳${RH}h${RM}m"
    fi
    LIMIT_5H="5h ${BAR_5H} ${UTIL_5H_INT}%${RESET_5H_TEXT}"
fi

# 7day (with ideal pacing: elapsed_time / 7_days * 100)
UTIL_7D_INT=0
IDEAL_7D=""
if [ -n "$UTIL_7D" ] && [ "$UTIL_7D" != "null" ] && [ "$UTIL_7D" != "0" ]; then
    UTIL_7D_INT=${UTIL_7D%.*}
    BAR_7D=$(mini_bar "$UTIL_7D_INT")
    REMAIN_7D_TEXT=""
    if [ -n "$RESET_7D_EPOCH" ] && [ "$RESET_7D_EPOCH" -gt "$NOW" ] 2>/dev/null; then
        REMAIN_SEC=$((RESET_7D_EPOCH - NOW))
        ELAPSED=$((604800 - REMAIN_SEC))
        IDEAL_7D=$(echo "scale=0; $ELAPSED * 100 / 604800" | bc 2>/dev/null || echo "")
        R7D=$((REMAIN_SEC / 86400))
        R7H=$(((REMAIN_SEC % 86400) / 3600))
        REMAIN_7D_TEXT=" ${R7D}d${R7H}h"
    fi
    if [ -n "$IDEAL_7D" ]; then
        LIMIT_7D="7d ${BAR_7D} ${UTIL_7D_INT}%/${IDEAL_7D}%${REMAIN_7D_TEXT}"
    else
        LIMIT_7D="7d ${BAR_7D} ${UTIL_7D_INT}%${REMAIN_7D_TEXT}"
    fi
fi

# ══════════════════════════════════════════════════════════
# ══ MODULE: effort ══
# Detect current thinking effort level.
# Priority: transcript log > settings.json > default (high).
# Needs: CORE ($TRANSCRIPT_PATH)
# ══════════════════════════════════════════════════════════
EFFORT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    EFFORT=$(grep -o 'Set effort level to [a-z]*:' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 | sed 's/.*to //;s/://')
fi
if [ -z "$EFFORT" ]; then
    EFFORT=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi
EFFORT=${EFFORT:-high}

# ══════════════════════════════════════════════════════════
# ══ MODULE: promo [SEASONAL — 2026-03-13 to 2026-03-27] ══
# 2x off-peak usage tracker for Anthropic's spring 2026 promotion.
# Shows ⚡2x (off-peak, orange) or ⚡1x (peak, gray).
# Includes days-remaining countdown and transition alert.
# Safe to remove after the promotion ends.
# Outputs: $PROMO_TEXT, $PROMO_BG, $PROMO_FG (used in ASSEMBLY)
# Needs: CORE
# ══════════════════════════════════════════════════════════
PROMO_SHOW_TRANSITION=1
PROMO_SHOW_DAYS_LEFT=1
[ -f "$HOME/.claude/promo.conf" ] && source "$HOME/.claude/promo.conf"

PROMO_START="2026-03-13"
PROMO_END="2026-03-28"
PROMO_GONE="2026-03-29"
PROMO_TEXT=""
PROMO_BG=""
PROMO_FG=""
TODAY_DATE=$(date '+%Y-%m-%d')
if [[ "$TODAY_DATE" < "$PROMO_GONE" ]] && [[ ! "$TODAY_DATE" < "$PROMO_START" ]]; then
    if [[ "$TODAY_DATE" < "$PROMO_END" ]]; then
        EDT_DOW=$(TZ='America/New_York' date '+%w')
        UTC_HOUR=$(date -u '+%H')
        UTC_MIN=$(date -u '+%M')
        UTC_HOUR_INT=$((10#$UTC_HOUR))
        UTC_MIN_INT=$((10#$UTC_MIN))

        PROMO_DAYS_LEFT=""
        if [ "$PROMO_SHOW_DAYS_LEFT" = "1" ]; then
            PROMO_END_EPOCH=$(date -j -f "%Y-%m-%d" "$PROMO_END" "+%s" 2>/dev/null)
            TODAY_EPOCH=$(date -j -f "%Y-%m-%d" "$TODAY_DATE" "+%s" 2>/dev/null)
            if [ -n "$PROMO_END_EPOCH" ] && [ -n "$TODAY_EPOCH" ]; then
                PROMO_DAYS_LEFT=$(( (PROMO_END_EPOCH - TODAY_EPOCH) / 86400 ))
            fi
        fi

        if [ "$EDT_DOW" -eq 0 ] || [ "$EDT_DOW" -eq 6 ]; then
            PROMO_TEXT="⚡2x"
            [ -n "$PROMO_DAYS_LEFT" ] && PROMO_TEXT+=" ${PROMO_DAYS_LEFT}d"
            PROMO_BG=173; PROMO_FG=232
        else
            IS_PEAK=0
            if [ "$UTC_HOUR_INT" -ge 12 ] && [ "$UTC_HOUR_INT" -lt 18 ]; then
                IS_PEAK=1
            fi

            PROMO_TRANSITION=""
            if [ "$PROMO_SHOW_TRANSITION" = "1" ]; then
                CURRENT_TOTAL_MIN=$((UTC_HOUR_INT * 60 + UTC_MIN_INT))
                PEAK_START_MIN=$((12 * 60))
                PEAK_END_MIN=$((18 * 60))

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
                PROMO_BG=239; PROMO_FG=245
            else
                PROMO_TEXT="⚡2x"
                [ -n "$PROMO_DAYS_LEFT" ] && PROMO_TEXT+=" ${PROMO_DAYS_LEFT}d"
                PROMO_TEXT+="$PROMO_TRANSITION"
                PROMO_BG=173; PROMO_FG=232
            fi
        fi
    else
        PROMO_TEXT="⚡2x ended"
        PROMO_BG=124; PROMO_FG=255
    fi
fi

# ══════════════════════════════════════════════════════════
# ══ ASSEMBLY: Line 1 ══
# ══════════════════════════════════════════════════════════
# Model + Effort (deep blue bg=24)
MODEL_SHORT=$(echo "$MODEL" | sed 's/ (.*)//')
pl_add 1 24 255 "${MODEL_SHORT} · ${EFFORT}"
# Dir (dark blue bg=17)
pl_add 1 17 255 "$DIR"
# ProjType (slate bg=60)
if [ -n "$PROJECT_TYPE" ]; then
    pl_add 1 60 255 "$PROJECT_TYPE"
fi
# Branch (teal bg=31)
if [ "$BRANCH" != "no-git" ]; then
    pl_add 1 31 255 " ${BRANCH}${GIT_STATUS}"
fi
# Lines changed (dark gray bg=236)
if [ "$LINES_ADDED" -gt 0 ] 2>/dev/null || [ "$LINES_REMOVED" -gt 0 ] 2>/dev/null; then
    pl_add 1 236 255 " +${LINES_ADDED}/-${LINES_REMOVED}"
fi
# Light-background alternating segments (white 255 / light gray 253)
LIGHT_BGS=(255 253)
LIGHT_IDX=0
# Commits
if [ "$BRANCH" != "no-git" ] && [ "$COMMIT_COUNT" -gt 0 ] 2>/dev/null; then
    pl_add 1 "${LIGHT_BGS[$((LIGHT_IDX % 2))]}" 232 " $COMMIT_COUNT"
    LIGHT_IDX=$((LIGHT_IDX + 1))
fi
# MsgCount
if [ -n "$MSG_COUNT" ]; then
    pl_add 1 "${LIGHT_BGS[$((LIGHT_IDX % 2))]}" 232 " $MSG_COUNT"
    LIGHT_IDX=$((LIGHT_IDX + 1))
fi
# Promo [SEASONAL — remove this block after promotion ends]
if [ -n "$PROMO_TEXT" ]; then
    pl_add 1 "$PROMO_BG" "$PROMO_FG" "$PROMO_TEXT"
fi
# WorkTime
if [ -n "$WORK_TIME" ]; then
    pl_add 1 "${LIGHT_BGS[$((LIGHT_IDX % 2))]}" 232 " $WORK_TIME"
    LIGHT_IDX=$((LIGHT_IDX + 1))
fi

# ══════════════════════════════════════════════════════════
# ══ ASSEMBLY: Line 2 ══
# ══════════════════════════════════════════════════════════
# Context bar (dynamic bg: 22=green / 136=yellow / 124=red)
if [ "$PERCENT_USED" != "null" ] && [ "$PERCENT_USED" != "0" ] 2>/dev/null; then
    if [ "$PERCENT_USED" -ge 80 ] 2>/dev/null; then
        CTX_BG=124
    elif [ "$PERCENT_USED" -ge 50 ] 2>/dev/null; then
        CTX_BG=136
    else
        CTX_BG=22
    fi
    BLOCKS=("░" "▏" "▎" "▍" "▌" "▋" "▊" "▉" "█")
    TOTAL_UNITS=$((PERCENT_USED * 8 / 10))
    FILLED=$((TOTAL_UNITS / 8))
    PARTIAL=$((TOTAL_UNITS % 8))
    EMPTY=$((10 - FILLED - (PARTIAL > 0 ? 1 : 0)))
    BAR=""
    for ((i=0; i<FILLED; i++)); do BAR+="█"; done
    if [ "$PARTIAL" -gt 0 ]; then BAR+="${BLOCKS[$PARTIAL]}"; fi
    for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
    pl_add 2 "$CTX_BG" 255 " [${BAR}] ${PERCENT_USED}%"
fi
# 5h quota (dynamic bg: <50=green28 / 50-69=yellow130 / ≥70=red160)
if [ -n "$LIMIT_5H" ]; then
    if [ "$UTIL_5H_INT" -ge 70 ] 2>/dev/null; then
        pl_add 2 160 255 "$LIMIT_5H"
    elif [ "$UTIL_5H_INT" -ge 50 ] 2>/dev/null; then
        pl_add 2 130 255 "$LIMIT_5H"
    else
        pl_add 2 28 255 "$LIMIT_5H"
    fi
fi
# 7d quota (dynamic bg: <50=green22 / 50-69=yellow130 / ≥70=red196)
if [ -n "$LIMIT_7D" ]; then
    if [ "$UTIL_7D_INT" -ge 70 ] 2>/dev/null; then
        pl_add 2 196 255 "$LIMIT_7D"
    elif [ "$UTIL_7D_INT" -ge 50 ] 2>/dev/null; then
        pl_add 2 130 255 "$LIMIT_7D"
    else
        pl_add 2 22 255 "$LIMIT_7D"
    fi
fi
# Session cost (brown bg=94)
if [ "$SESSION_COST" != "0" ] && [ "$SESSION_COST" != "null" ]; then
    COST_FORMATTED=$(printf '%.2f' "$SESSION_COST" 2>/dev/null || echo "$SESSION_COST")
    pl_add 2 94 255 " \$${COST_FORMATTED}"
fi

# ══════════════════════════════════════════════════════════
# ══ OUTPUT ══
# ══════════════════════════════════════════════════════════
pl_render L1_SEGS
if [ ${#L2_SEGS[@]} -gt 0 ]; then
    pl_render L2_SEGS
fi
