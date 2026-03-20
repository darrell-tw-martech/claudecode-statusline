# Claude Code Powerline 狀態列

[English](./README.md) | [繁體中文](./README.zh-TW.md)

功能完整的雙行 Powerline 狀態列，專為 [Claude Code](https://claude.ai/code) 設計。顯示模型資訊、Git 狀態、Context 用量、配額、Session 費用等，全部以 Powerline 色塊呈現。

![帶標註的狀態列截圖](./screenshots/statusline-full.png)

## 快速開始

```bash
git clone https://github.com/darrell-tw-martech/claudecode-statusline.git
cd claudecode-statusline/statusline
./install.sh
```

或手動安裝：

```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

加入 `~/.claude/settings.json`：

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

重啟 Claude Code，狀態列會在第一次 AI 回覆後出現。

## 系統需求

- **Claude Code 2.1.80+**（需要 stdin JSON 的 `rate_limits` 欄位）
- **jq** — JSON 解析器（`brew install jq` / `apt install jq`）
- **bash** 4+（macOS 內建 3.2 也能用，建議 4+）
- **git** — 選用，branch/commit 模組需要
- **bc** — 選用，7 天配額 pacing 計算需要

## 外觀

雙行 Powerline 輸出：

```
 Opus · high  project  main*  +10/-3  3  42  ⚡2x 8d  15m
 [██▍░░░░░░░] 15%  5h ●○○○○○○○○○ 10% ⏳3h22m  7d ●●●●○○○○○○ 41%/56% 3d1h  $0.50
```

**第一行**（由左至右）：
| 區段 | 範例 | 資料來源 |
|------|------|---------|
| 模型 + Effort | `Opus · high` | `model.display_name` + transcript/settings |
| 目錄 | `project` | `workspace.current_dir` |
| 專案類型 | `JS` | 偵測設定檔（package.json 等） |
| Git 分支 | ` main*` | `git branch --show-current` |
| 異動行數 | `+10/-3` | `cost.total_lines_added/removed` |
| 今日 commit | `3` | `git log --since=today` |
| 訊息數 | `42` | transcript JSONL 行數 |
| 促銷 | `⚡2x 8d` | [季節性] 時段計算 |
| 工作時間 | `15m` | transcript 檔案 mtime |

**第二行**（由左至右）：
| 區段 | 範例 | 資料來源 |
|------|------|---------|
| Context 進度條 | `[██▍░░░░░░░] 15%` | `context_window.used_percentage` |
| 5 小時配額 | `5h ●○○○○○○○○○ 10% ⏳3h22m` | `rate_limits.five_hour` |
| 7 天配額 | `7d ●●●●○○○○○○ 41%/56% 3d1h` | `rate_limits.seven_day` |
| Session 費用 | `$0.50` | `cost.total_cost_usd` |

## 模組

腳本以標記區塊組織。在 `statusline.sh` 中搜尋 `══ MODULE:` 即可跳到各模組。

| 模組 | 行數 | 依賴 | 功能 |
|------|------|------|------|
| **CORE** | ~90 | — | JSON 解析、`pl_add`、`pl_render`、`mini_bar`。所有模組必須。 |
| **git-info** | ~15 | CORE | 分支名、dirty 標記 `*`、今日 commit 數 |
| **work-time** | ~20 | CORE | 從 transcript mtime 計算 session 時長 |
| **project-type** | ~10 | CORE | 偵測 JS/PY/RS/GO 設定檔 |
| **msg-count** | ~8 | CORE | 從 transcript JSONL 計算訊息數 |
| **context-bar** | ~3 | CORE | Context window `used_percentage` |
| **lines-changed** | ~3 | CORE | `+新增/-刪除` 行數 |
| **session-cost** | ~3 | CORE | Session 費用（美元） |
| **rate-limits** | ~40 | CORE, `mini_bar` | 5h/7d 配額 ●○ 進度條 + 重置倒數 + 7d pacing |
| **effort** | ~10 | CORE | thinking effort 等級 |
| **promo** | ~65 | CORE | [季節性] 2x 離峰追蹤器。過期後可安全刪除。 |

### 移除模組

1. 找到 `══ MODULE: <名稱> ══` 標頭
2. 刪除該標頭到下一個 `══ MODULE:` 或 `══ ASSEMBLY:` 之間的內容
3. 在 ASSEMBLY 區段移除對應的 `pl_add` 呼叫

### 新增自訂模組

1. 在 ASSEMBLY 之前新增 `══ MODULE:` 區塊
2. 從 `$JSON`（stdin）或外部指令讀取資料
3. 將顯示文字存到變數
4. 在 ASSEMBLY 裡加 `pl_add <行> <背景色> <前景色> "$YOUR_VAR"`

## Stdin JSON 參考

Claude Code 在每次 AI 回覆後，透過 stdin 傳送以下 JSON 給你的腳本。基於 2.1.80 測試。

### 完整結構

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "model": {
    "id": "claude-opus-4-6[1m]",
    "display_name": "Opus 4.6 (1M context)"
  },
  "workspace": {
    "current_dir": "/current/working/directory",
    "project_dir": "/original/project/directory",
    "added_dirs": []
  },
  "version": "2.1.80",
  "output_style": { "name": "default" },
  "cost": {
    "total_cost_usd": 0.50,
    "total_duration_ms": 120000,
    "total_api_duration_ms": 45000,
    "total_lines_added": 10,
    "total_lines_removed": 3
  },
  "context_window": {
    "total_input_tokens": 15000,
    "total_output_tokens": 5000,
    "context_window_size": 1000000,
    "current_usage": {
      "input_tokens": 1,
      "output_tokens": 148,
      "cache_creation_input_tokens": 312,
      "cache_read_input_tokens": 109405
    },
    "used_percentage": 11,
    "remaining_percentage": 89
  },
  "exceeds_200k_tokens": false,
  "rate_limits": {
    "five_hour": {
      "used_percentage": 10,
      "resets_at": 1773993600
    },
    "seven_day": {
      "used_percentage": 41,
      "resets_at": 1774245600
    }
  }
}
```

### 欄位說明

| 欄位 | 說明 |
|------|------|
| `rate_limits` | **2.1.80+**。第一次 API call 前不存在。`resets_at` 是 Unix epoch（秒）。 |
| `context_window.used_percentage` | 僅計算 input tokens（不含 output）。Session 初期可能為 `null`。 |
| `cost.total_cost_usd` | 本次 session 的累計費用。Session 結束後歸零。 |
| `vim.mode` | 僅在 vim 模式啟用時出現。值：`NORMAL`、`INSERT`。 |
| `agent.name` | 僅在使用 `--agent` flag 時出現。 |
| `worktree.*` | 僅在 `--worktree` session 中出現。 |

### Stdin 中不提供的欄位（2.1.80）

以下欄位常被需要，但不在 statusline JSON 中：

- **Permission mode**（bypass/default/plan）— 由 Claude Code UI 直接渲染
- **Sonnet 配額**（`seven_day_sonnet`）— 僅 OAuth API endpoint 提供
- **超額使用額度**（`extra_usage`）— 僅 OAuth API endpoint 提供

## Powerline 渲染

`pl_add` / `pl_render` 系統使用 256 色終端代碼：

```bash
pl_add <行> <背景色> <前景色> <文字>
```

- `行`：`1` 為上方、`2` 為下方
- 顏色：256 色代碼（例如 24=深藍、173=橘色、255=白色）
- `pl_render` 用 Powerline 箭頭 `` 連接各區段
- 箭頭顏色自動銜接：每個箭頭從目前背景色過渡到下一個背景色

### 顏色對照（本狀態列使用的顏色）

| 代碼 | 顏色 | 用途 |
|------|------|------|
| 24 | 深藍 | 模型 |
| 17 | 暗藍 | 目錄 |
| 60 | 灰藍 | 專案類型 |
| 31 | 青藍 | Git 分支 |
| 236 | 暗灰 | 異動行數 |
| 255 | 白 | 淺色區段 |
| 253 | 淺灰 | 淺色區段（交替） |
| 173 | 橘 | 促銷 2x |
| 239 | 灰 | 促銷 1x |
| 22 | 綠 | Context <50%、7d 配額 <50% |
| 136 | 黃 | Context 50-79% |
| 124 | 紅 | Context ≥80% |
| 28 | 綠 | 5h 配額 <50% |
| 130 | 黃 | 5h/7d 配額 50-69% |
| 160 | 紅 | 5h 配額 ≥70% |
| 196 | 亮紅 | 7d 配額 ≥70% |
| 94 | 棕 | Session 費用 |

## 給 AI 助手的指引

如果用戶請你設定或客製這個狀態列，請按以下流程：

1. **閱讀此 README** 了解所有模組和 stdin JSON 結構
2. **詢問用戶** 要啟用哪些模組（參考上方模組表格）
3. **複製 `statusline.sh`** 到 `~/.claude/statusline.sh`
4. **移除不需要的模組** — 刪除 `══ MODULE:` 區塊及 ASSEMBLY 中的 `pl_add` 呼叫
5. **更新 `settings.json`** 指向腳本

常見客製需求：
- 「只要配額」→ 保留 CORE + rate-limits 模組，移除其他
- 「不要促銷」→ 刪除 promo 模組和它的 pl_add
- 「換顏色」→ 修改 pl_add 的 256 色代碼
- 「單行」→ 把所有 pl_add 改成 line 1，移除 line 2 assembly

## 授權

[MIT](../LICENSE)

---

Made by [Darrell Wang](https://www.threads.net/@darrell_tw_)
