---
name: tdd-dev
description: Drive feature and bugfix implementation strictly through Test-Driven Development (red → green → refactor), grounded in the repository's own design conventions. Before writing any production code, this skill writes a failing test first; it then runs the project's lint (static analysis) and its custom architecture/dependency-direction linter as quality gates, and finishes every task with a dependency-version security audit. Use this skill whenever the user asks to implement a feature, fix a bug, add an endpoint/function/class, or "write code" for anything non-trivial — and especially when they say "TDD", "test first", "test-driven", "テスト駆動", "テストから", "きちんとテストを書いて実装", or ask that the change respect the existing architecture. Trigger it even when the user does not explicitly say "TDD" or "skill", as long as they are asking for real production code changes rather than a throwaway snippet or a pure question.
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

# tdd-dev 🧪

Implement production code changes by **letting tests drive the design**. The unit of progress is not "a feature written" but "a failing test made to pass, then the code cleaned up." This skill enforces that discipline and wraps it in the repository's own quality gates so the result fits the codebase instead of fighting it.

The point of TDD here is not ceremony. Writing the test first forces you to state the expected behavior precisely before you have any implementation to bias you, keeps the design testable, and gives you a safety net for the refactor step. If you skip straight to production code "and add tests after," you lose all three benefits — so this skill does not allow that shortcut.

## Language policy 🌐

- **This SKILL.md and everything under the skill directory are written in English.**
- **Converse with the user in Japanese.** Every chat-facing message — clarifying questions, progress reports (RED/GREEN/REFACTOR status), the final summary — is in Japanese.
- Code, test names, commit messages, and tool output stay in whatever the repository already uses. Do not translate identifiers.

## When to use

Trigger when the user wants real code written or changed:

- "Implement a discount calculation for the cart", "add a `/users/:id` endpoint", "fix the off-by-one in pagination"
- Explicit TDD requests: "TDDで実装して", "テストから書いて", "test-first で"
- Any request that should respect existing architecture: "既存の設計に沿って追加して"

Do **not** trigger for: pure questions ("how does X work"), throwaway one-liners the user explicitly wants quick and dirty, or reviews of existing code (use a review skill for that).

## The core loop 🔁

Work in **small vertical slices**. For each slice, go through the full cycle before starting the next. Never batch many features into one giant red phase — small cycles keep the feedback tight and the diff reviewable.

### 0. Ground yourself in the repository's design (do this first, once per task)

Before writing a single test, learn how this repo expects code to be shaped. Skipping this is the most common way well-tested code still gets rejected — it passes but violates the intended architecture. Read, in order of what exists:

- `architecture.md`, `ARCHITECTURE.md`, `docs/architecture*`, `docs/adr/**`, ADRs, `DESIGN.md` , `docs/design-docs/`, `docs/design_docs/`
- `CONTRIBUTING.md`, `CLAUDE.md`, `AGENTS.md`, `.cursorrules` — coding conventions
- The custom-linter config itself (see `references/tooling.md`) — it encodes the *enforced* dependency direction, which is the ground truth even when the prose docs are stale
- The nearest existing sibling module to what you're building — mirror its layering, naming, and test style

Summarize to the user in Japanese, in one or two sentences, the constraints you'll follow (e.g. "domain 層は infra を import しない方針に従う"). This confirms you understood before you invest in code.

### 1. 🔴 RED — write one failing test

Write a test that expresses the next small piece of desired behavior, and **run it to watch it fail**. The failure must be for the right reason (assertion not met / missing function), not a typo or import error. A test that fails for the wrong reason proves nothing.

- Name the test after the behavior, following the repo's existing test conventions.
- Assert on observable behavior, not on implementation internals — otherwise the refactor step can't move.
- Report to the user: which behavior, and the confirmed failure (in Japanese).

If the very first run *passes*, stop and investigate — either the behavior already exists (say so) or the test is not actually exercising anything.

### 2. 🟢 GREEN — minimal code to pass

Write the **smallest** change that makes the test pass. Resist implementing the whole feature or "obvious" extras — those belong to their own later cycles with their own tests. Run the test and confirm it, plus the rest of the suite, is green.

If making it pass requires touching many files or a design decision, that's a signal the slice is too big — consider narrowing it.

### 3. 🧹 REFACTOR — clean up under a green bar

With tests passing, improve the code and the tests: remove duplication, clarify names, align with the design conventions from step 0. Re-run the suite after each change to stay green. This is where architectural fit is restored — do not skip it just because the test already passes.

Repeat 1–3 until the task's behavior is fully covered. Then run the quality gates.

## Quality gates (run before declaring the task done) 🚦

These are not optional finishing touches — they are how you verify the change is *acceptable*, not merely *working*. Detect the actual tools from the repo; see `references/tooling.md` for detection and commands per ecosystem. Do not invent a tool the repo doesn't use.

1. **Lint / static analysis.** Run the project's configured linter and formatter (eslint, ruff, golangci-lint, clippy, etc.). Fix what it flags in your diff. If it reports pre-existing issues outside your change, mention them but don't scope-creep into fixing them unasked.

2. **Custom architecture linter (dependency direction).** Many mature repos enforce *which package may depend on which* — import-linter, dependency-cruiser, go-arch-lint, ArchUnit, deptry, etc. This is the guardrail that keeps layers honest (e.g. domain not importing infrastructure). Run it if present. A violation here means your change is architecturally wrong even if every unit test is green — fix the dependency direction, don't suppress the rule. If no such linter exists, note that and rely on the step-0 conventions instead.

Run these as separate Bash calls (not chained with `&&`), so a failure in one is legible on its own.

## Completion: dependency-version security audit 🔒

Every time the task reaches "done," audit the security of the dependency **versions** in play — especially if you added or bumped any dependency, but do a baseline scan regardless. Newly pulled-in packages are the highest-risk moment for introducing a known-vulnerable version.

Use the repo's native audit tool, or the language-agnostic `osv-scanner` as a fallback (see `references/tooling.md`). Report findings to the user in Japanese:

- If vulnerabilities are found, surface them plainly — package, severity, and the fixed version to upgrade to. Do **not** silently upgrade across a major version without flagging it; that can be a breaking change.
- If clean, state so in one line.

> Security note: this audit reports *known-vulnerable versions*. It is not a guarantee of safety. For anything alarming (a high/critical CVE in a direct dependency), call it out explicitly rather than burying it.

## Reporting to the user 🗣️

Keep the user oriented without drowning them. During the loop, a terse Japanese line per phase transition is enough (`🔴 <behavior> のテスト追加 → 失敗確認`, `🟢 実装 → 通過`, `🧹 リファクタ完了`). At the end, give a short Japanese summary: what behavior is now covered, gate results (lint / arch-linter pass/fail), and the security-audit result. Don't paste full tool logs unless something failed and the detail is needed.

## Anti-patterns to avoid ⚠️

- Writing production code before the failing test exists. (The whole point is lost.)
- Writing a test that passes on the first run and calling it "red." (It tested nothing.)
- One enormous test covering the entire feature. (Small slices; tight feedback.)
- Asserting on internals so refactor becomes impossible.
- Suppressing an architecture-linter rule to make a violation "pass."
- Declaring done without running lint, arch-linter, and the security audit.

## References

- `references/tooling.md` — per-ecosystem detection and exact commands for lint, custom architecture linters, and dependency security audit. Read it when you reach the quality-gate or audit step and need the right command for the repo's stack.
