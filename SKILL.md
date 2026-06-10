---
name: loop-engineering
description: "Loop Engineering framework: design autonomous agent feedback cycles instead of hand-prompting each step"
version: 1.1.0
---

# Loop Engineering

Design repeatable feedback cycles that guide AI agents from attempt to verified outcome — without constant human intervention.

## Core Shift

```
Old way (prompting):   You -> Prompt -> Agent -> Output -> You review -> You fix -> Repeat
New way (looping):     You set goal -> Loop runs -> Agent discovers -> Plans -> Executes -> Verifies -> Iterates -> Done
```

Prompt engineers ask AI for output. Loop engineers design systems that produce verified outcomes.

## Why Loops Fail — The 5 Agent Killers

Most people blame the model when a loop fails. The real problem is loop design.

| # | Killer | Symptom | Fix |
|---|--------|---------|-----|
| 1 | **Context Collapse** | Step 12 forgets what Step 1 wanted. Long tasks eat context; the model keeps running but stops making progress. | Decompose into sub-loops with clean scope. Each sub-loop has its own goal, context, and verifier. Use `delegate_task` for isolation. |
| 2 | **No Self-Correction** | Hits error → retries same approach → hits error again. Infinite expensive spin. | Add diagnostic step: capture error → analyze root cause → decide new approach. Never retry blindly. |
| 3 | **No Verifier** | "Finished" ≠ correct. No independent check means the agent has no way to know it actually succeeded. Self-critique doesn't count — the same context that produced the output can't judge it objectively. | Always use a **separate context** for verification. Worker and verifier must be independent API calls with no shared history. |
| 4 | **No Guardrails** | Agent can delete files, spend money, call external APIs without constraints. | Define action boundaries in RULES.md. Use `terminal` restrictions, budget caps, and read-only mode where possible. |
| 5 | **No Memory** | Every run starts from zero. Same mistakes repeat across sessions. | Extract **general rules** from failures (not just logs). Persist them. Load before next run. |

Diagnose failing loops by checking these 5 first.

## The 5 Stages (every good loop)

```
DISCOVER -> PLAN -> EXECUTE -> VERIFY -> ITERATE (or DONE)
```

Pass verification -> ship. Fail -> diagnose -> loop with new approach.

### 0. Goal — define what done means precisely
### 1. DISCOVER — explore context, gather constraints, understand state
### 2. PLAN — map the approach, decompose into sub-tasks, select model tier
### 3. EXECUTE — only what the agent actually needs. Capture output + metadata.
### 4. VERIFY — independent check in a SEPARATE context
### 5. ITERATE or DONE — decide: pass = done, fail = correct then loop

## Loop Architecture (Worker + Verifier)

```
                    ┌─────────────────────────────────┐
                    │           LOOP CONTROLLER       │
                    │  (orchestrator / cron trigger)   │
                    └──────────┬──────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │    GOAL + CONTEXT   │
                    │  (what done means)  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  1. DISCOVER + PLAN  │
                    │  (decompose, route)  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  2. WORKER (ctx A)   │
                    │  execute -> produce  │
                    └──────────┬──────────┘
                               │  output
                    ┌──────────▼──────────┐
                    │  3. VERIFIER (ctx B) │
                    │  independent check   │
                    │  no shared history   │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  4. GATE            │
                    │  pass? fail?        │
                    └──────┬──────┬───────┘
                           │      │
                        PASS    FAIL
                           │      │
                    ┌──────▼┐  ┌──▼──────────────┐
                    │ DONE  │  │ 5. DIAGNOSE      │
                    └───────┘  │ root cause       │
                               │ extract rule     │
                               │ new approach     │
                               └──┬───────────────┘
                                  │  back to EXECUTE
                                  └─────────────────→
```

**Critical rule**: Worker (Context A) and Verifier (Context B) must be independent API calls. No shared message history. A verifier that inherits the worker's context inherits its blind spots.

```python
# worker builds in context A
worker = client.messages.create(model="...", messages=[{"role": "user", "content": prompt}])

# verifier grades in context B — completely independent
verifier = client.messages.create(
    model="...",
    messages=[{"role": "user", "content": f"Grade this output against this rubric:\n\nOUTPUT: {worker.text}\n\nRUBRIC: {rubric}"}]
)
# No shared history. No bias. Clean judgment.
```

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

### Tiered Model Routing

Don't use your best model for every task. Route by task type:

| Task Type | Complexity | Model Tier | Example |
|-----------|-----------|------------|---------|
| Architecture decision, hard bug diagnosis, multi-file reasoning, final verification | High | Best (Fable 5 / Opus) | "Is this refactor safe?" |
| Medium reasoning, code generation, review | Medium | Mid (Sonnet 4 / DeepSeek V4 Flash) | "Write this feature" |
| Data extraction, reformatting, boilerplate, simple edit, routine retry | Low | Cheap (Haiku / MiniMax) | "Format this output" |

```python
def route_task(task_type, complexity):
    if task_type in ("architecture_decision", "hard_bug_diagnosis",
                     "multi_file_reasoning", "final_verification",
                     "ambiguity_resolution") or complexity == "high":
        return "best-model"        # Fable 5, Opus
    elif task_type in ("data_extraction", "reformatting",
                       "boilerplate_generation", "simple_edit",
                       "routine_retry") and complexity == "low":
        return "cheap-model"       # Haiku, MiniMax
    else:
        return "mid-model"         # Sonnet, DeepSeek V4 Flash
```

Rule: Only escalate to the expensive model when judgment matters. Most loop iterations are cheap — verification is where you spend.

### Self-Correction: Never Retry Blindly

When EXECUTE fails:
1. **Capture** error + what was attempted
2. **Diagnose** root cause in a separate call
3. **Decide** new approach (different strategy, not same one louder)
4. **Optionally extract rule** — learn for next time

```
                   FAIL
                    │
           ┌────────▼────────┐
           │ 1. Capture      │
           │ error + context │
           └────────┬────────┘
                    │
           ┌────────▼────────┐
           │ 2. Diagnose     │
           │ root cause      │  ← separate API call
           └────────┬────────┘
                    │
           ┌────────▼────────┐
           │ 3. Extract rule │
           │ for memory      │  ← optional, one-shot
           └────────┬────────┘
                    │
           ┌────────▼────────┐
           │ 4. New approach │
           │ → back to PLAN  │
           └─────────────────┘
```

### Memory as Rules, Not Logs

Don't store raw failure logs. Extract a **general rule** from each failure:

```python
def extract_rule(client, failed_attempt, error_output):
    response = client.messages.create(
        model="best-model",
        messages=[{"role": "user", "content": f"""
A task just failed. Extract ONE general rule to remember for next time.

WHAT FAILED:
{failed_attempt}

ERROR:
{error_output}

Write a single clear rule that would prevent this failure in the future.
Format: "RULE: [concise general principle]"
Do not write a note about this specific case.
Write a rule that applies broadly.
"""}]
    )
    return response.text

def load_memory(memory_file):
    try:
        with open(memory_file, "r") as f:
            return f.read()
    except FileNotFoundError:
        return "No memory yet."

def save_memory(memory_file, new_rule):
    with open(memory_file, "a") as f:
        f.write(new_rule + "\n")
```

Load memory at the start of each loop run so the agent doesn't repeat past mistakes.
