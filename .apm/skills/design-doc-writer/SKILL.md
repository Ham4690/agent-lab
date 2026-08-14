---
name: design-doc-writer
description: Interactively gathers design requirements from the user through structured Q&A and generates a Japanese-language software design document following Google's design doc conventions (Context & Scope, Goals/Non-Goals, Design, Alternatives Considered, Cross-Cutting Concerns). Saves to docs/design_docs/<filename>.md at project root. Trigger when user requests design documentation, describes a system/feature/API before implementation, or mentions design docs — proactively suggest even if the request is vague or not explicitly framed as "design doc".
---

# Design Doc Writer

Interactive skill that creates a Japanese-language software design document before implementation, following Google's design doc conventions (https://www.industrialempathy.com/posts/design-docs-at-google/). Engages the user through structured Q&A to extract requirements and design rationale, then saves the doc to `docs/design_docs/<filename>.md` at the project root.

**Core principle:** The value is not filling a template, but surfacing trade-offs in the design decision. Ask questions in a way users can answer, but do not skip the hard parts.

## Overall Flow

1. Identify the project root
2. Gather requirements via interactive Q&A (ask progressively, not all at once)
3. Create a draft and get user confirmation
4. Decide on filename and save to `docs/design_docs/`
5. Present a brief completion summary

Details for each step follow.

---

## Step 1: Identify the Project Root

- Run `git rev-parse --show-toplevel` and use it as the project root if it succeeds.
- If it fails (not a git repo), ask the user to confirm whether the current working directory can be treated as the root.
- Create the `docs/design_docs/` directory during save if it doesn't exist (`mkdir -p`).

## Step 2: Requirements Gathering (Interactive Q&A)

**Key principle:** Do not ask all questions at once. Draw out information progressively through natural conversation. Reuse information already visible in chat history or uploaded documents—don't ask again.

Conduct Q&A in Japanese (以下の質問例は日本語で行う). User interaction is in Japanese.

Gather information in this order (mapped to Google Design Docs structure):

### 2.1 Context and Scope
Ask about the problem/situation, existing systems involved, and prerequisite knowledge. This is *not* a requirements list—focus on the **background a reader needs to understand the situation**, not detailed specs. Questions in Japanese:
> 例：「どんな課題や状況があってこのシステム/機能を作るのですか？」「既存のどのシステムに関係していますか？」

### 2.2 Goals and Non-Goals
Extract the system's objectives (bullet points OK) and explicitly clarify non-goals. Non-Goals are not "things you won't do," but "things that *could* be goals but we intentionally exclude." Example in Japanese:
> 例：「ACID準拠は今回のスコープに含めますか、それとも意図的に対象外としますか？」

### 2.3 Design (The Actual Implementation)
Discuss high-level architecture (is a system context diagram needed?), public/internal APIs (if any, at conceptual level), data storage (what data, what shape?), and the degree of constraint (greenfield or legacy-constrained?). If constrained, ask specifically what existing factors are blocking choices.

### 2.4 Alternatives Considered
Ask about other designs/approaches the user considered. Why were they not chosen? **This is the highest-value section.** Even if the user says "not really," probe once: "Were there really no other options, or is this design so obviously best that no alternatives crossed your mind?"

### 2.5 Cross-Cutting Concerns
Cover security, privacy, observability (metrics/logs/traces). If you detect from context that the project uses Java/Spring Boot or middleware like Kafka/Pulsar, ask about observability design specifics tied to those technologies.

### Stance
- Accept "I don't know" or "not yet decided" answers—record them honestly as TBD or "under review."
- Adjust doc length to fit scope. A small improvement may warrant a "mini design doc" (1–3 pages equivalent), keeping all sections but staying concise.
- If the user says they've covered enough, move to the next step—don't force all items if the conversation feels complete.

## Step 3: Draft Creation and User Review

Write the draft following the structure in `references/template.md`. Before saving, present the key points to the user in the conversation for review—especially **Goals/Non-Goals** and **Alternatives Considered**. Incorporate minor feedback directly; if there are major misalignments, ask follow-up questions.

## Step 4: Filename Decision and Save

- Filenames use English kebab-case by default: `<topic-slug>.md` (e.g., `auto-bidding-cache-redesign.md`).
  - Optionally ask the user about adding a date prefix (e.g., `2026-07-11-auto-bidding-cache-redesign.md`).
  - If the user prefers a Japanese filename, defer to that.
- Save to: `<project_root>/docs/design_docs/<filename>.md`
- Create the directory if it doesn't exist.
- If a file with the same name already exists, ask the user before overwriting (different name or overwrite?).

## Step 5: Completion Summary

- Report the saved file path to the user.
- Briefly summarize the document's main sections (do not re-paste the full text).
- Ask if there are any changes the user wants to make before sharing for review.

---

## Reference Files

- `references/template.md` — The Markdown template to fill when creating drafts. Headings are in Japanese (for user output), with inline English comments for clarification.
