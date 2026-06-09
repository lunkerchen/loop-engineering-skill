---
name: loop-engineering
description: "Loop Engineering framework: design autonomous agent feedback cycles instead of hand-prompting each step"
version: 1.0.0
---

# Loop Engineering

Design repeatable feedback cycles that guide AI agents from attempt to verified outcome — without constant human intervention.

## Core Shift

```
Old way (prompting):   You -> Prompt -> Agent -> Output -> You review -> You fix -> Repeat
New way (looping):     You set goal -> Loop runs -> Agent discovers -> Plans -> Executes -> Verifies -> Iterates -> Done
```

Prompt engineers ask AI for output. Loop engineers design systems that produce verified outcomes.

## The 5 Stages (every good loop)

```
DISCOVER -> PLAN -> EXECUTE -> VERIFY -> ITERATE
```
Pass verification -> ship. Fail -> loop again.

### 1. Goal — define what done means precisely
### 2. Context — VISION.md, ARCHITECTURE.md, RULES.md per project
### 3. Action — only what the agent actually needs
### 4. Feedback — tests, type checks, linters, structured errors
### 5. Stop condition — when the loop knows its finished

## The 6 Components

| Component | Purpose | Hermes Impl |
|-----------|---------|-------------|
| **Automations** | Heartbeat, triggers discovery | `cronjob` with schedule |
| **Worktrees** | Parallel agents, no collisions | `git worktree add` -> `.worktrees/<branch>/` |
| **Skills** | Knowledge compounds every run | `project-context/*` skills + VISION/ARCH/RULES docs |
| **Plugins** | Loop acts in real tools (DB, Slack, Linear) | MCP tools, delegate_task |
| **Subagents** | Maker never same as checker | delegate_task role=leaf/orchestrator |
| **Memory** | Loop never forgets between runs | .dev-loop-state.md, memory, skill-compounder.sh |

## Two Scales

### Single-Agent Loop
One agent runs whole cycle.
- Good for: focused tasks, simple goals
- Hermes: one session, `max_spawn_depth=1`

### Fleet Loop
Orchestrator -> specialists -> subagents
- delegate_task with role=orchestrator
- Requires `max_spawn_depth >= 2` in config
- Each subagent runs its own DISCOVER->PLAN->EXECUTE->VERIFY->ITERATE

## Two Loop Types

| Type | Characteristic | Use When | Cost |
|------|---------------|----------|------|
| **Open loop** | Exploratory, expensive | Need to discover unknowns | High |
| **Closed loop** | Bounded, self-verifying | Need verified outcomes | Low — stops when done |

Closed loop is the one that pays off.

## Setup Checklist

### Per Project
- [ ] VISION.md — what, why, non-goals
- [ ] ARCHITECTURE.md — system layers, data flow
- [ ] RULES.md — agent constraints (red/yellow/green)
- [ ] `project-context/<name>` skill — loads all 3 docs
- [ ] Worktrees: `setup-worktrees.sh <dir> [branches...]`
- [ ] `.dev-loop-state.md` — cross-run memory

### Infrastructure
- [ ] config.yaml: `max_spawn_depth: 2` (fleet loops)
- [ ] Test suite — the verification gate
- [ ] `dev-loop.sh` — write -> test -> fix -> verify
- [ ] `skill-compounder.sh` — post-loop learning

### Cron Jobs
- [ ] Dev loop: nightly 3AM (D->P->E->V->I)
- [ ] Maintenance: periodic (nightly scrubs)
- [ ] Watchdog: frequent (health checks)

## Scripts

### dev-loop.sh
```bash
~/.hermes/scripts/dev-loop.sh <project-dir> [max-iters]
```
Auto-detects test command, runs, reads errors, iterates.
Envs: DEV_LOOP_PREBUILD_CMD, DEV_LOOP_TEST_CMD, DEV_LOOP_CLEAN_CMD

### setup-worktrees.sh
```bash
~/.hermes/scripts/setup-worktrees.sh <project-dir> [branches...]
```
Creates `.worktrees/<branch>/` per branch. Default: current + experiments.

### skill-compounder.sh
```bash
~/.hermes/scripts/skill-compounder.sh <skill-name> <project-dir> <title> <body>
```
Appends lesson to skill's `references/learnings.md`.

## Cost Management

- Single-agent medium task: 50K-200K tokens
- Fleet loop + 3 specialists: 500K-2M tokens
- Scheduled daily loop: millions/week

Use cheap frontier models (DeepSeek V4 Flash, Kimi, MiniMax) for loops.
Reserve expensive models (Opus, GPT-5) for critical verification passes.
