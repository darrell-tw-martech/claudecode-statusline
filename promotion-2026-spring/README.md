# ⚡ Claude Code Statusline — 2x Promotion Indicator

Show whether you're in the **2x usage** window directly in your Claude Code statusline.

**Promotion period:** March 13 – 27, 2026 ([Anthropic announcement](https://support.anthropic.com/en/articles/11360-claude-march-2026-usage-promotion))

## What it looks like

| Status | Segment | When |
|--------|---------|------|
| **Off-peak (doubled)** | `⚡2x` on orange | Outside EDT 8AM–2PM |
| **Peak (normal)** | `⚡1x` on gray | EDT 8AM–2PM |
| **Ended** | `⚡2x ended` on red | March 28 only |

The segment automatically disappears after March 28.

## Time zones

The promotion doubles your 5-hour usage outside **8 AM – 2 PM ET (EDT, UTC-4)**.

| Your timezone | Off-peak (2x) | Peak (1x) |
|---------------|---------------|-----------|
| UTC | 18:00 – 12:00 next day | 12:00 – 18:00 |
| PT (PDT) | 5 AM – 11 PM | 5 AM – 11 AM *(wait, see note)* |
| JST (UTC+9) | 3:00 AM – 9:00 PM | 9:00 PM – 3:00 AM |
| CST/TW (UTC+8) | 2:00 AM – 8:00 PM | 8:00 PM – 2:00 AM |
| CET (UTC+1) | 7:00 PM – 1:00 PM next day | 1:00 PM – 7:00 PM |

> Note: The bonus usage **does not** count against your weekly (7-day) limit.

## Installation

### Option 1: Auto-install

```bash
git clone https://github.com/Darrellwan/claudecode-statusline.git
cd claudecode-statusline/promotion-2026-spring
bash install.sh
```

This will:
- Detect your `~/.claude/statusline.sh`
- Create a backup
- Insert the promotion segment

### Option 2: Copy & paste

Copy the contents of [`promotion.sh`](./promotion.sh) into your `statusline.sh`.

Place it wherever you want the segment to appear. It uses the `pl_add` function:

```bash
# pl_add <line_number> <bg_256color> <fg_256color> <text>
pl_add 1 173 232 "⚡2x"   # orange bg, black text
pl_add 1 239 245 "⚡1x"   # gray bg, gray text
pl_add 1 124 255 "⚡2x ended"  # red bg, white text
```

If your statusline doesn't use `pl_add`, adapt the color codes:
- Off-peak: `\033[38;5;232;48;5;173m ⚡2x \033[0m`
- Peak: `\033[38;5;245;48;5;239m ⚡1x \033[0m`
- Ended: `\033[38;5;255;48;5;124m ⚡2x ended \033[0m`

### Option 3: Ask your AI

If you use Claude Code (or any AI coding assistant), just say:

> Read https://github.com/Darrellwan/claudecode-statusline/blob/main/promotion-2026-spring/promotion.sh and add this 2x promotion indicator to my statusline.sh

The snippet is self-contained and well-commented — any AI can integrate it.

## Requirements

- Claude Code with custom statusline (`~/.claude/statusline.sh`)
- Bash 3.2+ (macOS compatible)
- A Powerline-style statusline with `pl_add` function (or adapt the ANSI codes)

## How it works

The script checks UTC hour to determine peak vs. off-peak:

```
UTC 12:00–18:00 = EDT 8AM–2PM = Peak (1x)
All other hours = Off-peak (2x)
```

Date checks ensure the segment only shows during the promotion (3/13–3/27), displays a one-day "ended" notice on 3/28, and fully disappears on 3/29.

## License

[MIT](./LICENSE)

---

Made by [Darrell Wang](https://github.com/Darrellwan) · [Threads @darrell_tw_](https://www.threads.net/@darrell_tw_)
