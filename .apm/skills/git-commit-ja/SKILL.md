---
name: git-commit-ja
description: Review staged changes, analyze repository commit history conventions (granularity, style, prefix rules), and automatically generate concise commit messages in Japanese and execute commits. Use when the user requests "commit this", "create a commit message", "commit this", "generate message from diff", or when multiple concerns are mixed requiring granularity adjustment.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git commit *)
---

# git-commit-ja

Analyzes already-staged (`git add` completed) changes and repository commit history to create concise, accurate commit messages in Japanese and automatically execute commits. More than just summarizing diffs, this skill also judges **granularity** (whether changes are overstuffed into one commit) and proposes splitting if needed, plus automatically executes the commit.

## Output Policy (Important)

This skill's steps 1-5 (diff retrieval, past log review, granularity judgment, message creation, final review) are performed **silently as internal processing and their intermediate progress is NOT output in the conversation**. Do not write out headings like "convention check", "granularity judgment", or "final review", nor explain the reasoning behind judgments or thoughts.

Only the following **final results** are output in the conversation:

- If commit succeeds: present only the result of `git commit` (commit hash and first line of message) concisely. Do not ask "is this okay?" or re-show the message proposal (this skill is designed to commit without asking).
- Only if step 5 detects issues (secrets leakage, etc.): present the reason specifically.
- Only if there are no staged changes: inform the user.

## Scope of Responsibility (Important)

Assume `git add` has already been performed by the user or prior work. This skill is responsible for **reviewing staged content, creating a commit message, and executing the commit**.

- If no staged changes exist, do NOT run `git add` on your own. Simply inform the user and suggest candidates for what should be staged.
- Automatic execution of `git commit` is within this skill's scope (see `allowed-tools` frontmatter), but only if step 5's final review finds no issues.
- Do NOT push. Pre-push history cleanup is the responsibility of the separate skill `git-push-ja`.

## When to Use

- When you want a commit message for staged changes
- When staged changes mix multiple concerns (feature + refactor + formatting, etc.) and need granularity assessment
- When you want to match the repo's commit writing style (Conventional Commits, prefix presence, body, tone)

## Procedure

**Execution Note (all steps)**: Execute the following git commands as separate, independent Bash calls—do NOT chain them with `&&` or `;`. The `allowed-tools` prefix match applies only to single, non-chained commands; chained commands like `cmd1 && cmd2` trigger confirmation prompts for security reasons.

Steps 1-5 below are internal processing and do NOT output intermediate progress (headings, reasoning, proposals). Output only per the "Output Policy" above.

### 1. Retrieve staged diff

```bash
git status
```
```bash
git diff --staged
```

- Use `--staged` only. Unstaged changes (`git diff` without flag) are not included in this commit.
- If `git diff --staged` is empty, inform the user and stop (do not auto-stage; only suggest candidates).

### 2. Learn the repository's "conventions" from past log

```bash
git log --oneline -30
```
```bash
git log -10 --stat
```

Check these aspects:

| Aspect | Example |
|--------|---------|
| Prefix convention | `feat:` `fix:` (Conventional Commits), `【fix】` style, or no prefix |
| Language | Japanese, English, or mixed — observed for context only. Regardless of the log's language, this skill ALWAYS writes the commit message in Japanese (see step 4) |
| Tone | "~する" (do), "~しました" (formal past), or command form ("Add xxx") |
| Actual granularity | File count and line count per commit tendency (via `git log --stat`) |
| Body presence | Title-only or with bullet-point body explanation |

**Prioritize the repository's actual conventions over generic Conventional Commits rules.** If the repo has no clear convention (sparse log or inconsistent), use the "Default Policy" below.

### 3. Classify changes and judge granularity

Categorize changes:

- `feat` - new feature, spec addition
- `fix` - bug fix
- `refactor` - structure change without behavior change
- `style` - formatting, whitespace, lint fixes only
- `test` - test additions/changes
- `docs` - documentation only
- `chore` - build config, dependency updates, etc.

**Split proposal criteria:**

- Two or more categories above AND they are independent and meaningful → consider splitting
  - Example: "feature addition" + "unrelated file formatting"
  - Example: "bug fix" + "separate issue feature" in same diff
- These do NOT need splitting (keep together):
  - Implementation code + corresponding tests
  - Implementation + accompanying config, type definitions, OpenAPI schema
  - Refactor + implementation for one purpose (if staged refactor is the purpose itself)
- Many files but single purpose → no split needed. Few files but two purposes → consider split.

**Only if splitting is judged necessary**, output this judgment to conversation (include `git add -p` breakdown and confirm which granularity to proceed with). If no split is needed, output nothing and proceed to step 4.

### 4. Create commit message

**Language (non-negotiable):**
- Title and body are ALWAYS written in concise Japanese, even if the past log is in English. This overrides the "follow repo conventions" rule of step 2 — conventions apply to prefix, tone, and granularity only, never to language.
- The Conventional Commits prefix (`feat:`, `fix(scope):`, etc.) stays in English. Technical terms, product names, and identifiers may remain in ASCII (e.g. `Bearer トークン検証を preemptive 認証に変更`).

**Title line:**
- Aim for ~50 chars; focus on "why/what changes" not "what was changed"
- If past log has prefix convention, follow it. Otherwise use Default Policy below.
- Keep tone consistent: "~する" or command form (match past log style)

**Body (if needed):**
- Multiple files/intents, or "why" is not obvious from diff alone → add bullet-point explanation in Japanese
- Simple single-line changes → no body (avoid over-verbosity)

### Default Policy (when repo has no clear convention)

Base on Conventional Commits format, description in Japanese:

```
<type>(<scope>): <変更内容の簡潔な日本語の説明>

- <補足 1（日本語）>
- <補足 2（日本語）>
```

- `<type>`: feat / fix / refactor / style / test / docs / chore
- `<scope>`: main module/directory changed (optional)
- Body only if change is not self-evident

### 5. Final review before commit

Check staged diff against:

- **Unintended files mixed in**: `.env`, credentials, build artifacts, `.DS_Store`, temp files
- **Debug traces**: `console.log`, `print`, `fmt.Println`, etc., or commented-out code
- **Secrets/credentials**: API keys, tokens, password-like strings

Output nothing if all clear; proceed to step 6. Only if issues found, do NOT commit and state them specifically (this is the exception to the silent-processing rule).

### 6. Execute commit and show result only

- Execute `git commit` with the created message; no confirmation needed
- Output to conversation: **commit hash and title line only** in ~1 line (e.g., `Committed a1b2c3d: feat(auth): Bearer トークン検証を preemptive 認証に変更`). No proposal text, no review results, no confirmation questions.
- If step 3 proposed splitting, re-stage via `git add -p` for the relevant parts, then commit each; show results ~1 line per commit.
- Do NOT `git push` unless explicitly instructed (push is `git-push-ja` skill's responsibility).

## Output Format Examples

**Normal (no issues, no split):**

```
Committed a1b2c3d: feat(auth): Bearer トークン検証を preemptive 認証に変更
```

**With split:**

```
Committed a1b2c3d: feat(auth): Preemptive 認証への切り替え
Committed e4f5g6h: style(auth): 未使用の import を削除
```

**Issue detected (details output only in this case):**

```
commitを見送りました。ステージ済みdiffに .env が含まれています。unstageしてから再実行してください。
```

## References

- Conventional Commits spec: https://www.conventionalcommits.org/
- Chris Beams, "How to Write a Git Commit Message": https://cbea.ms/git-commit/
- Google Engineering Practices, "How to Write a CL Description": https://google.github.io/eng-practices/review/developer/cl-descriptions.html
- Pro Git book, "Commit message" chapter: https://git-scm.com/book/en/v2
- Angular commit message guidelines: https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md
- Claude Code Skills frontmatter reference: https://code.claude.com/docs/skills#frontmatter-reference
