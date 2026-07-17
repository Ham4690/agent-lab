#!/bin/bash
set -euo pipefail

# Resolve this script's directory, following symlinks, so it works from any
# clone location or working directory.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# scripts/ -> claude/ -> claude/skills
SKILLS_SRC="$(cd "$SCRIPT_DIR/../skills" && pwd)"
SKILLS_LINK="$HOME/.claude/skills"

mkdir -p "$SKILLS_LINK"

for SKILL_SRC in "$SKILLS_SRC"/*/; do
  SKILL_NAME=$(basename "$SKILL_SRC")
  SKILL_LINK="$SKILLS_LINK/$SKILL_NAME"

  # Check if symlink exists and points to correct location
  if [ -L "$SKILL_LINK" ] && [ "$(readlink "$SKILL_LINK")" = "$SKILL_SRC" ]; then
    echo "✓ $SKILL_NAME (already linked)"
  else
    # Remove old/incorrect link or file
    [ -e "$SKILL_LINK" ] && rm -rf "$SKILL_LINK"
    ln -s "$SKILL_SRC" "$SKILL_LINK"
    echo "✓ $SKILL_NAME (linked)"
  fi
done

echo "✅ All skills set up"
