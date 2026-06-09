#!/usr/bin/env bash
# setup-worktrees.sh — Create Git worktrees for parallel agent development
#
# Worktrees let multiple Hermes agents work on different branches of the same repo
# simultaneously without conflicts. Each worktree is an independent checkout.
#
# Convention:
#   <project-root>/.worktrees/<branch-name>/
#
# Usage:
#   ./setup-worktrees.sh <project-dir> [branches...]
#     If no branches given, uses the current branch + 'experiments'
#
# Example:
#   ./setup-worktrees.sh ~/Developer/Projects/polymarket-bot feature-a feature-b
#   → creates .worktrees/feature-a/ and .worktrees/feature-b/

set -euo pipefail

PROJECT_DIR="${1:?Usage: $0 <project-dir> [branches...]}"
shift || true
cd "$PROJECT_DIR"

# Ensure it's a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "✗ Not a git repo: $PROJECT_DIR"
  exit 1
fi

REPO_NAME=$(basename "$PROJECT_DIR")
WORKTREE_BASE="$PROJECT_DIR/.worktrees"
mkdir -p "$WORKTREE_BASE"

# If no branches specified, use current + experiments
if [ $# -eq 0 ]; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  BRANCHES=("$CURRENT_BRANCH" "experiments")
else
  BRANCHES=("$@")
fi

for BRANCH in "${BRANCHES[@]}"; do
  # Check if branch exists
  if ! git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
    echo "  → Creating branch '$BRANCH'"
    git branch "$BRANCH" HEAD
  fi

  WORKTREE_PATH="$WORKTREE_BASE/$BRANCH"

  if [ -d "$WORKTREE_PATH" ]; then
    echo "  ✓ Worktree exists: $WORKTREE_PATH ($BRANCH)"
  else
    echo "  → Adding worktree: $WORKTREE_PATH ($BRANCH)"
    git worktree add "$WORKTREE_PATH" "$BRANCH" 2>&1
  fi
done

echo ""
echo "=== Worktrees for $REPO_NAME ==="
git worktree list
