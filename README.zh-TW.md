# 🔄 Loop Engineering Skill — Loop 工程技能

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![English](https://img.shields.io/badge/README-English-green.svg)](README.md)
[![AI Agent](https://img.shields.io/badge/AI-Agent%20Ready-blue)](https://github.com/lunkerchen/loop-engineering-skill)
[![Hermes](https://img.shields.io/badge/Hermes-Skill-purple)](https://hermes-agent.nousresearch.com)

設計自主 agent 反饋循環，取代手動下指令的開發模式。

靈感來自 Rahul 的「Loops: What Every AI Engineer Needs to Know in 2026」— 以及 Peter Steinberger (OpenClaw) 和 Boris Cherny (Claude Code) 的核心洞察：**不要再 prompt 你的 agent 了，開始設計 loops。**

## 功能特色

| 功能 | 說明 |
|------|------|
| **5 階段框架** | DISCOVER → PLAN → EXECUTE → VERIFY → ITERATE |
| **6 個元件** | Automations, Worktrees, Skills, Plugins, Subagents, Memory |
| **單一 Agent 循環** | 一個 agent 完成完整 cycle，適合聚焦任務 |
| **Fleet Loop** | Orchestrator + specialists + subagents 處理複雜目標 |
| **Closed Loop** | 自我驗證，有停止條件 — 真正會賺錢的那種 |
| **專案上下文** | 每個專案有 VISION.md / ARCHITECTURE.md / RULES.md |
| **知識累積** | 每次 loop 執行的教訓會持續沉澱 |

## 架構

```
┌─────────────────────────────────────────────────────┐
│                    LOOP ENGINEERING                  │
│                                                     │
│  GOAL → CONTEXT → ACTION → FEEDBACK → STOP          │
│         ↓                                            │
│    ┌──────────┐                                      │
│    │ DISCOVER │                                      │
│    └────┬─────┘                                      │
│         ↓                                            │
│    ┌──────────┐                                      │
│    │  PLAN    │                                      │
│    └────┬─────┘                                      │
│         ↓                                            │
│    ┌──────────┐                                      │
│    │ EXECUTE  │                                      │
│    └────┬─────┘                                      │
│         ↓                                            │
│    ┌──────────┐     FAIL                              │
│    │ VERIFY   ├──────→ ITERATE ──────┐               │
│    └────┬─────┘                      │               │
│         ↓ PASS                       │               │
│    ┌──────────┐                      │               │
│    │   DONE   │                      │               │
│    └──────────┘                      │               │
│         └────────────────────────────┘               │
└─────────────────────────────────────────────────────┘
```

## 快速開始

### 環境需求
- Hermes Agent（或其他 LLM agent 框架）
- Git（用於 worktrees）
- 專案的測試套件（pytest, npm test, go test）

### 1. 載入技能
```
load loop-engineering
```

### 2. 設定專案
```bash
# 建立專案上下文文件
touch VISION.md ARCHITECTURE.md RULES.md

# 設定平行 worktrees
bash scripts/setup-worktrees.sh /path/to/project experiments hotfix

# 執行開發循環
bash scripts/dev-loop.sh /path/to/project 5
```

### 3. 排程夜間循環
```bash
cronjob action=create \
  name=my-project-dev-loop \
  workdir=/path/to/project \
  schedule="0 3 * * *" \
  prompt="Follow the 5-stage loop..."
```

### 4. 累積知識
```bash
bash scripts/skill-compounder.sh my-project /path/to/project \
  "Lesson Title" "What we learned this run"
```

## 專案結構

```
loop-engineering-skill/
├── SKILL.md                  # Hermes skill 定義
├── README.md                 # 英文文件
├── README.zh-TW.md           # 繁體中文
├── LICENSE                   # MIT 授權
└── scripts/
    ├── dev-loop.sh           # 寫 → 測 → 修 → 驗證
    ├── setup-worktrees.sh    # Git worktrees 平行開發
    └── skill-compounder.sh   # 每次 loop 後的知識累積
```

## 核心轉變

```
舊方式 (prompting):   You → Prompt → Agent → Output → 你 review → 你修 → 重複
新方式 (looping):     你設目標 → Loop 跑 → Agent 探索 → 規劃 → 執行 → 驗證 → 迭代 → 完成
```

Prompt engineer 問 AI 要 output。**Loop engineer 設計系統產出 verified outcome。**

## 成本管理

- 單一 agent 中型任務：5 萬–20 萬 tokens
- Fleet loop + 3 個 specialists：50 萬–200 萬 tokens
- 每日排程循環：每週數百萬 tokens

使用便宜的 frontier 模型（DeepSeek V4 Flash, Kimi, MiniMax）跑 loop。昂貴模型留給關鍵驗證環節。

## 相關技能

- **project-context/camera-market** — C2C 攝影器材市集，完整 loop 設定
- **project-context/polymarket-bot** — 即時交易 bot，夜間 dev loop cron
- **engineering/codex** — Codex CLI 委派編碼任務

## 授權

MIT — 見 [LICENSE](LICENSE)。
