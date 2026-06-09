# 🔄 Loop Engineering Skill

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![中文](https://img.shields.io/badge/README-繁體中文-red.svg)](README.zh-TW.md)
[![AI Agent](https://img.shields.io/badge/AI-Agent%20Ready-blue)](https://github.com/lunkerchen/loop-engineering-skill)
[![Hermes](https://img.shields.io/badge/Hermes-Skill-purple)](https://hermes-agent.nousresearch.com)

Design autonomous agent feedback cycles instead of hand-prompting each step.

Inspired by Rahul's "Loops: What Every AI Engineer Needs to Know in 2026" — and the core insight from Peter Steinberger (OpenClaw) and Boris Cherny (Claude Code): **stop prompting your agents. Start designing loops.**

## Features

| Feature | Description |
|---------|-------------|
| **5-Stage Framework** | DISCOVER → PLAN → EXECUTE → VERIFY → ITERATE |
| **6 Components** | Automations, Worktrees, Skills, Plugins, Subagents, Memory |
| **Single-Agent Loop** | One agent runs the full cycle on focused tasks |
| **Fleet Loop** | Orchestrator + specialists + subagents for complex goals |
| **Closed Loop** | Self-verifying cycle with stop conditions — pays off today |
| **Project Context** | VISION.md / ARCHITECTURE.md / RULES.md per project |
| **Skill Compounding** | Knowledge accumulates across loop runs |

## Architecture

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

## Quick Start

### Prerequisites
- Hermes Agent (or any LLM agent framework)
- Git (for worktrees)
- A test suite in your project (pytest, npm test, go test)

### 1. Load the skill
```
load loop-engineering
```

### 2. Set up a project for loops
```bash
# Create project context docs
touch VISION.md ARCHITECTURE.md RULES.md

# Set up parallel worktrees
bash scripts/setup-worktrees.sh /path/to/project experiments hotfix

# Run a dev loop
bash scripts/dev-loop.sh /path/to/project 5
```

### 3. Schedule nightly loops
```bash
cronjob action=create \
  name=my-project-dev-loop \
  workdir=/path/to/project \
  schedule="0 3 * * *" \
  prompt="Follow the 5-stage loop..."
```

### 4. Compound knowledge
```bash
bash scripts/skill-compounder.sh my-project /path/to/project \
  "Lesson Title" "What we learned this run"
```

## Project Structure

```
loop-engineering-skill/
├── SKILL.md                  # Hermes skill definition
├── README.md                 # English documentation
├── README.zh-TW.md           # Traditional Chinese
├── LICENSE                   # MIT license
└── scripts/
    ├── dev-loop.sh           # Write → test → fix → verify
    ├── setup-worktrees.sh    # Git worktrees for parallel agents
    └── skill-compounder.sh   # Post-loop knowledge accumulation
```

## The Core Shift

```
Old way (prompting):   You → Prompt → Agent → Output → You review → Fix → Repeat
New way (looping):     You set goal → Loop runs → Agent discovers → Plans → Executes → Verifies → Iterates → Done
```

Prompt engineers ask AI for output. **Loop engineers design systems that produce verified outcomes.**

## Cost Management

- Single-agent medium task: 50K-200K tokens
- Fleet loop + 3 specialists: 500K-2M tokens
- Scheduled daily loop: millions of tokens per week

Use cheap frontier models (DeepSeek V4 Flash, Kimi, MiniMax) for loops. Reserve expensive models for critical verification passes.

## Related Skills

- **project-context/camera-market** — C2C photography marketplace with full loop setup
- **project-context/polymarket-bot** — Live trading bot with nightly dev loop cron
- **engineering/codex** — Codex CLI delegation for coding tasks

## License

MIT — see [LICENSE](LICENSE).
