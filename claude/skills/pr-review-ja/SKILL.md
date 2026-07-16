---
name: pr-review-ja
description: Review a GitHub Pull Request (read-only) and write findings to a Markdown file under docs/my-review/. Checks bugs, security, performance, design, and tests (TDD perspective) in a fixed order, and outputs missing test cases as given/when/then specs. Use whenever the user asks to review a PR, e.g. "PRレビューして", "PRをレビュー", "コードレビューして", "PR確認して", "プルリクエストを見て", "review this PR", "レビュー #<number>", or pastes a GitHub PR URL asking for review. Never posts comments to GitHub and never modifies code.
allowed-tools: Bash(gh pr view *) Bash(gh pr checkout *) Bash(gh pr diff *) Bash(gh auth status) Bash(gh repo view *) Bash(git status *) Bash(git log *) Bash(git diff *) Bash(git rev-parse *) Bash(git checkout *) Bash(git switch *) Bash(rg *) Bash(date *) Bash(mkdir -p docs/my-review) Read Grep Glob Write
---

# pr-review-ja

Read-only PR review skill. Reviews a GitHub Pull Request against a fixed checklist and writes the findings as a Japanese Markdown report under `docs/my-review/` in the reviewed repository. It never changes code, never comments on GitHub, and never approves/merges anything.

**Language policy**: This document is in English, but ALL interaction with the user (questions, warnings, progress, final summary) MUST be in Japanese, and the output `*.md` report MUST be written in Japanese.

## Hard constraints (read-only)

- NEVER modify, commit, push, amend, or rebase anything in the reviewed repository.
- NEVER approve, merge, close, or post comments/reviews to GitHub (`gh pr review`, `gh pr comment`, `gh pr merge` are all forbidden).
- The ONLY allowed writes are: creating `docs/my-review/` (if absent) and writing the review report file into it.
- The ONLY allowed branch operation is `gh pr checkout <number>` plus switching back to the original branch afterwards.
- Missing tests are reported as *specifications only*. Implementing tests is the responsibility of a separate skill (`pr-test-fill-ja`), not this one.

## Workflow

### 1. Resolve the target PR

Accepted inputs: a PR URL (`https://github.com/<owner>/<repo>/pull/<number>`) or "repository name + PR number". If neither is present in the user's request, ask the user for it (in Japanese) before doing anything else.

### 2. Preflight checks

```bash
gh auth status
```

- If `gh` is not installed or not authenticated: tell the user (in Japanese) and ask how they want to proceed (e.g. install `gh`, run `gh auth login`, or provide the diff another way). Do not silently fall back.
- Confirm the current directory is a clone of the target repository (compare `git remote get-url origin` / `gh repo view` with the PR's repo). If it is not, tell the user and ask them to `cd` into (or clone) the right repository.
- Check the working tree:

```bash
git status --porcelain
```

If the tree is dirty, WARN the user in Japanese that `gh pr checkout` will switch branches, and get explicit confirmation before continuing.

- Record the current branch so it can be restored later:

```bash
git rev-parse --abbrev-ref HEAD
```

### 3. Fetch PR metadata and check out the branch

```bash
gh pr view <number> --json title,author,baseRefName,headRefName,additions,deletions,files,url
gh pr checkout <number>
```

### 4. Review

Start from the diff, but you MAY and SHOULD read the whole checked-out working tree to raise review quality — e.g. use `rg` to find callers of changed functions, existing tests, and related configuration:

```bash
gh pr diff <number>
git diff origin/<baseRefName>...HEAD
rg "<changed symbol>" --type-add 'src:*.{py,ts,go,rb,java}' -n
```

Check the following perspectives **in this exact order**. For any perspective with no findings, explicitly state 「問題なし」 in the report — do NOT invent findings to fill a section.

1. 🐛 **Bugs / logic inconsistencies** — boundary values, null/None handling, exception handling
2. 🔒 **Security** — injection, missing authn/authz, hardcoded secrets
3. ⚡ **Performance** — N+1 queries, unnecessary full scans, inefficient queries/loops, idempotency
4. 🏛 **Design / readability** — separation of concerns, naming, duplication, excessive complexity
5. 🧪 **Tests (TDD perspective)**
   - Do tests verify *behavior*, or are they brittle tests coupled to implementation internals?
   - Do the tests actually prevent regressions for this change?
   - Enumerate missing cases (boundary values, error paths, idempotency, …) and write them out as test *specifications* at "given X / when Y / then Z" granularity.
   - Do NOT implement tests here (that is `pr-test-fill-ja`'s job).

### 5. Write the report

- Output directory: `docs/my-review/` at the root of the **reviewed repository** (create it if it does not exist).
- Filename: `pr<number>_<yyyymmdd>_<slug>.md`
  - `<number>`: PR number digits only (`#6` → `pr6`)
  - `<yyyymmdd>`: the date the review is executed (use `date +%Y%m%d`)
  - `<slug>`: 2–4 word summary of the PR title, lowercase ASCII snake_case only (no Japanese). Example: `pr6_20260711_mysql2trino_dump.md`
- If a file with the same name already exists, do NOT overwrite it. Save as a re-review by appending `_r2`, `_r3`, … (e.g. `pr6_20260711_mysql2trino_dump_r2.md`).
- The report content MUST follow the template below exactly.

### 6. Restore state and report back

- Switch back to the branch recorded in step 2 (`git checkout <original-branch>`). The report file is untracked, so it survives the switch.
- Tell the user (in Japanese) where the report was written and give a one-paragraph summary of the most important findings.

## Report writing rules

- Concise Japanese. No verbose preamble, no excuses.
- Order findings by severity, highest first. Severity scale is fixed to these 4 levels:
  - 🔴 これは直そう！ … must fix before merge
  - 🟠 直すと良さそう … strongly recommended
  - 🟡 できれば直したい … nice to fix
  - 🟢 ちょいメモ … nits
- Every finding gets an ID of "severity prefix + sequence number": `[C-1]`, `[H-1]`, `[M-1]`, `[L-1]` (C=Critical / H=High / M=Medium / L=Low). IDs make findings referenceable in later re-reviews.
- Every finding MUST include all three of: なぜ問題か (reason), 具体例 (before), 修正案 (after: code or steps).
- References: prefer official documentation and primary sources. Do not list a URL unless you are certain it is correct; if unsure, write 「要確認」. Fabricating references is absolutely forbidden.
- Use emoji at key points for visual scanning by less-experienced readers — do not overuse.
- Use mermaid diagrams ONLY when a diagram is genuinely clearer than text (data-flow changes, state transitions, DB schema diffs). No decorative diagrams.
- When showing a destructive command, put it in a `bash` code block and state its blast radius right next to it.

## Report template (output EXACTLY in this structure)

````markdown
# PRレビュー: #<PR番号> <PRタイトル>

## 📋 メタ情報

- **PR**: <URL>
- **作成者**: <author>
- **ブランチ**: `<headRefName>` → `<baseRefName>`
- **変更規模**: +<additions> / -<deletions>（<ファイル数> ファイル）
- **レビュー実施日**: <yyyy-mm-dd>

## 🔎 サマリ

<変更内容の要約と総評を2〜4文で。>

## 指摘事項（重要度順）

<指摘が1件も無い場合は「指摘なし 🎉」とのみ記載。>

### [C-1] 🔴 これは直そう！ <指摘タイトル>

- **場所**: `path/to/file.ext` L42
- **観点**: 🐛 バグ（🔒 / ⚡ / 🏛 / 🧪 のいずれか）
- **なぜ問題か**: <理由を簡潔に。>

**具体例（before）**:

```<lang>
<問題のコード>
```

**修正案（after）**:

```<lang>
<修正後のコード、またはコードで示せない場合は手順>
```

<以降、[H-1] 🟠 直すと良さそう / [M-1] 🟡 できれば直したい / [L-1] 🟢 ちょいメモ を同じ構造で重要度順に列挙する。>

## ✅ 観点別チェック結果

1. 🐛 バグ・ロジック不整合: <該当指摘ID を列挙 / 問題なし>
2. 🔒 セキュリティ: <該当指摘ID を列挙 / 問題なし>
3. ⚡ パフォーマンス: <該当指摘ID を列挙 / 問題なし>
4. 🏛 設計・可読性: <該当指摘ID を列挙 / 問題なし>
5. 🧪 テスト: <該当指摘ID を列挙 / 問題なし>

## 🧪 追加すべきテスト仕様

> テストの実装は `pr-test-fill-ja` skill の責務。ここでは仕様の提示のみ。

<不足テストが無い場合は「追加不要」とのみ記載。>

### T-1: <テスト名>

- **given**: <前提条件 X>
- **when**: <操作 Y>
- **then**: <期待結果 Z>
- **種別**: <境界値 / 異常系 / 冪等性 / リグレッション>

## 📚 参考文献

- <公式ドキュメント等の一次情報。確証が無い URL は載せず「要確認」と明記する。>
````

## References

- GitHub CLI manual, `gh pr checkout` / `gh pr view` / `gh pr diff`: https://cli.github.com/manual/gh_pr
- Google Engineering Practices, "How to do a code review": https://google.github.io/eng-practices/review/reviewer/
- Claude Code Skills frontmatter reference: https://code.claude.com/docs/ja/skills#frontmatter-reference
