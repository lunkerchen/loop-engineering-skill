#!/usr/bin/env bash
# skill-compounder.sh — Post-loop skill knowledge compounding
#
# After a development loop completes, this script captures what was learned
# and patches the relevant skill file so knowledge compounds across runs.
#
# This implements the article's principle: "Skills — project knowledge that
# compounds every run."
#
# Usage:
#   skill-compounder.sh <skill-name> <project-dir> <lesson-title> <lesson-body>
#
# Example:
#   skill-compounder.sh polymarket-bot ~/Developer/Projects/polymarket-bot \
#     "WebSocket reconnection" "After 3 disconnects, switch to REST fallback"
#
# The lesson is appended to the skill's pitfall/reference section.

set -euo pipefail

SKILL_NAME="${1:?Usage: skill-compounder.sh <skill-name> <project-dir> <lesson-title> <lesson-body>}"
PROJECT_DIR="${2:?}"
LESSON_TITLE="${3:?}"
LESSON_BODY="${4:?}"

SKILL_DIR="$HOME/.hermes/skills/$SKILL_NAME"
SKILL_FILE="$SKILL_DIR/SKILL.md"
LEARNINGS_FILE="$SKILL_DIR/references/learnings.md"

# Ensure skill exists
if [ ! -d "$SKILL_DIR" ]; then
  echo "✗ Skill not found: $SKILL_NAME"
  echo "  Available skills:"
  ls "$HOME/.hermes/skills/"
  exit 1
fi

mkdir -p "$SKILL_DIR/references"

# Create or append to learnings file
TODAY=$(date '+%Y-%m-%d')
ENTRY="\n## $TODAY — $LESSON_TITLE\n\n$LESSON_BODY\n\n*Source: $PROJECT_DIR*"

if [ -f "$LEARNINGS_FILE" ]; then
  echo -e "$ENTRY" >> "$LEARNINGS_FILE"
else
  cat > "$LEARNINGS_FILE" << EOF
# Skill Knowledge Log: $SKILL_NAME

Lessons learned from each loop run. Knowledge compounds over time.

$(echo -e "$ENTRY")
EOF
fi

echo "✓ Appended to $LEARNINGS_FILE"
echo ""
echo "=== Last 3 entries ==="
tail -20 "$LEARNINGS_FILE"
