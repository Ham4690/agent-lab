---
name: repo-notes-init
description: >-
  Scaffold a personal, git-ignored `.repo-notes/` folder for a repository (a
  reviews/ subfolder + a README index). Use this whenever the user wants a
  private, non-committed notes space for understanding a repo, asks to "create
  a repo-notes folder" / "set up notes for this repo", or mentions
  `.repo-notes`. Trigger even if they don't say "skill".
---

# repo-notes-init

Create a personal, git-ignored notes folder at the project root, excluded
globally via `~/.config/git/ignore` so it never appears in `git status`.

```
${CLAUDE_PROJECT_DIR}/.repo-notes/
├── README.md      # index
├── reviews/       # PR review notes
└── architecture/  # 構造と振る舞いの概要
```

## Rules

- Never overwrite an existing `README.md`.
- Only add `.repo-notes/` to the global ignore if it isn't already there.

## Steps

```bash
set -euo pipefail

NOTES_DIR="${CLAUDE_PROJECT_DIR}/.repo-notes"
REPO_NAME="$(basename "${CLAUDE_PROJECT_DIR}")"

mkdir -p "$NOTES_DIR/reviews" "$NOTES_DIR/architecture"

if [ ! -e "$NOTES_DIR/README.md" ]; then
  cat > "$NOTES_DIR/README.md" <<EOF
# .repo-notes — ${REPO_NAME} の個人メモ

このリポジトリを理解するための自分用ノート。git管理外。

## 索引
- \`reviews/\` … PRレビューのメモ
- \`architecture/\` … 構造と振る舞いの概要

## このrepoの一言まとめ
（このリポジトリが何をするものか、入口はどこかを1〜2行で）
EOF
  echo "created: .repo-notes/README.md"
else
  echo "skipped (exists): .repo-notes/README.md"
fi

IGNORE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
mkdir -p "$(dirname "$IGNORE_FILE")"
touch "$IGNORE_FILE"
if grep -qxF ".repo-notes/" "$IGNORE_FILE" || grep -qxF ".repo-notes" "$IGNORE_FILE"; then
  echo "gitignore: already present"
else
  printf '.repo-notes/\n' >> "$IGNORE_FILE"
  echo "gitignore: added .repo-notes/"
fi

echo "✅ Done: $NOTES_DIR"
```
