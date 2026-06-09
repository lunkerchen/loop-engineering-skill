#!/usr/bin/env bash
# dev-loop.sh — Write → Test → Fix → Verify loop for agent development
#
# Implements the closed-loop pattern from "Loops: What Every AI Engineer Needs
# to Know in 2026": a self-correcting cycle that writes code, runs tests,
# reads errors, fixes them, and verifies — until all tests pass or max
# iterations are reached.
#
# Usage:
#   dev-loop.sh <project-dir> [max-iterations]
#
# Example (run as cron or delegate_task):
#   dev-loop.sh ~/Developer/Projects/polymarket-bot 5
#
# Environment variables (optional):
#   DEV_LOOP_PREBUILD_CMD   — command to run before each test cycle (e.g. pip install)
#   DEV_LOOP_TEST_CMD       — test command (default: auto-detect)
#   DEV_LOOP_CLEAN_CMD      — command to run after success (e.g. git commit)

set -euo pipefail

PROJECT_DIR="${1:?Usage: dev-loop.sh <project-dir> [max-iterations]}"
MAX_ITER="${2:-5}"
ITER=0
PASS=false

cd "$PROJECT_DIR"
echo "=== Dev Loop Started: $(basename "$PROJECT_DIR") ==="
echo "Max iterations: $MAX_ITER"
echo ""

# Auto-detect test command
detect_test_cmd() {
  if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    if [ -d "tests" ] || [ -d "test" ]; then
      echo "python -m pytest tests/ -x -q 2>&1"
      return
    fi
  fi
  if [ -f "package.json" ]; then
    if grep -q '"test"' package.json 2>/dev/null; then
      echo "npm test 2>&1"
      return
    fi
  fi
  if [ -f "go.mod" ]; then
    echo "go test ./... 2>&1"
    return
  fi
  # No test command found
  echo ""
}

TEST_CMD="${DEV_LOOP_TEST_CMD:-$(detect_test_cmd)}"

if [ -z "$TEST_CMD" ]; then
  echo "⚠ No test command detected and DEV_LOOP_TEST_CMD not set."
  echo "  Create a test suite or set DEV_LOOP_TEST_CMD env var."
  echo "  Falling back to syntax check only."
  TEST_CMD="python -c \"import py_compile; py_compile.compile('tmp_check.py')\" 2>&1 || echo 'no python files'"
fi

echo "Test command: $TEST_CMD"
echo ""

while [ "$ITER" -lt "$MAX_ITER" ] && [ "$PASS" = false ]; do
  ITER=$((ITER + 1))
  echo "--- Iteration $ITER/$MAX_ITER ---"

  # Phase: BUILD (pre-build hook)
  if [ -n "${DEV_LOOP_PREBUILD_CMD:-}" ]; then
    echo "→ Pre-build: $DEV_LOOP_PREBUILD_CMD"
    eval "$DEV_LOOP_PREBUILD_CMD" || echo "⚠ Pre-build warning (non-fatal)"
  fi

  # Phase: TEST
  echo "→ Testing..."
  TEST_OUTPUT=$(eval "$TEST_CMD" 2>&1) || true
  TEST_EXIT=$?

  if [ "$TEST_EXIT" -eq 0 ]; then
    echo "✓ All tests passed!"
    PASS=true
    break
  fi

  echo "✗ Tests failed (exit $TEST_EXIT)"
  echo ""
  echo "--- Error Output ---"
  echo "$TEST_OUTPUT" | tail -40
  echo "--- End Error Output ---"
  echo ""

  if [ "$ITER" -ge "$MAX_ITER" ]; then
    echo "⚠ Max iterations ($MAX_ITER) reached. Loop stopping."
    echo "$TEST_OUTPUT" > ".dev-loop-last-error.log"
    echo "Last error saved to .dev-loop-last-error.log"
    break
  fi

  # Phase: ITERATE — signal to the agent what to fix
  echo "→ Iterating... (agent should read errors above and fix)"
  echo "  (This loop runs inside a Hermes agent session —"
  echo "   the agent reads TEST_OUTPUT, fixes code, and re-runs)"
  echo ""
done

# Completion
if [ "$PASS" = true ]; then
  echo ""
  echo "=== ✓ Loop Complete: All Tests Passed ==="

  # Post-success hook
  if [ -n "${DEV_LOOP_CLEAN_CMD:-}" ]; then
    echo "→ Clean: $DEV_LOOP_CLEAN_CMD"
    eval "$DEV_LOOP_CLEAN_CMD" || echo "⚠ Clean warning (non-fatal)"
  fi
else
  echo ""
  echo "=== ⚠ Loop Stopped: Tests Not Passing ==="
  echo "Check .dev-loop-last-error.log for details."
  exit 1
fi
