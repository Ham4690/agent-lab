# Tooling detection & commands

This file maps each quality gate to concrete, per-ecosystem commands. **Detect what the repo actually uses first** — inspect config files and manifests — then run the matching command. Never install a global tool or introduce one the repo doesn't already depend on; if nothing is configured, say so rather than inventing a gate.

Detection heuristic: look at the manifest / lockfile to identify the ecosystem, then grep for the specific tool's config.

| Ecosystem | Manifest signal |
|-----------|-----------------|
| Node/TS   | `package.json`, `pnpm-lock.yaml`, `yarn.lock` |
| Python    | `pyproject.toml`, `requirements*.txt`, `poetry.lock`, `uv.lock` |
| Go        | `go.mod` |
| Rust      | `Cargo.toml` |
| Java/Kotlin | `pom.xml`, `build.gradle(.kts)` |
| Ruby      | `Gemfile` |

Prefer the project's own script alias when one exists (`package.json` `scripts.lint`, a `Makefile` target like `make lint` / `make test`, a `justfile`, `tox`, `nox`). A repo-defined alias encodes the intended flags — use it over a raw tool call.

## Test runner (for the RED/GREEN loop)

Run the narrowest scope that proves the point (single test/file) during the loop; run the full suite before the quality gates.

- Node/TS: `vitest`, `jest`, `node --test`, `mocha` — check `scripts.test`
- Python: `pytest`, `unittest`, `nox`/`tox`
- Go: `go test ./...` (or a specific package)
- Rust: `cargo test`
- Java/Kotlin: `mvn test`, `./gradlew test`
- Ruby: `rspec`, `rake test`

## Gate 1 — Lint / static analysis

| Ecosystem | Common tools | Config signal | Command (prefer repo alias) |
|-----------|--------------|---------------|-----------------------------|
| Node/TS   | ESLint, Biome, Prettier, `tsc` | `.eslintrc*`, `eslint.config.*`, `biome.json` | `npm run lint` / `npx eslint .` / `npx tsc --noEmit` |
| Python    | Ruff, Flake8, Pylint, mypy | `ruff.toml`, `[tool.ruff]`, `.flake8`, `[tool.mypy]` | `ruff check .` / `mypy .` |
| Go        | golangci-lint, `go vet` | `.golangci.yml` | `golangci-lint run` / `go vet ./...` |
| Rust      | Clippy | (built in) | `cargo clippy -- -D warnings` |
| Java/Kotlin | Checkstyle, Spotless, detekt, ktlint | plugin in `build.gradle`/`pom.xml` | `./gradlew check` / `mvn verify` |
| Ruby      | RuboCop | `.rubocop.yml` | `rubocop` |

Fix issues introduced by your diff. Pre-existing issues outside your change: mention, don't scope-creep.

## Gate 2 — Custom architecture / dependency-direction linter

These enforce **which package may depend on which** — the layering guardrail. Their config file is also the authoritative statement of the intended architecture (read it in SKILL.md step 0).

| Ecosystem | Tool | Config signal | Command |
|-----------|------|---------------|---------|
| Python    | import-linter | `.importlinter`, `[importlinter]` in setup.cfg/pyproject | `lint-imports` |
| Python    | deptry (unused/misplaced deps) | `[tool.deptry]` | `deptry .` |
| Node/TS   | dependency-cruiser | `.dependency-cruiser.js(on)` | `npx depcruise src` (or `scripts` alias) |
| Node/TS   | eslint-plugin-boundaries / import/no-restricted-paths | rule blocks in eslint config | covered by `eslint` run |
| Go        | go-arch-lint | `.go-arch-lint.yml` | `go-arch-lint check` |
| Go        | depguard (via golangci-lint) | `depguard` in `.golangci.yml` | covered by `golangci-lint run` |
| Java/Kotlin | ArchUnit | test classes using `com.tngtech.archunit` | runs as part of the test suite |
| Java      | Konsist (Kotlin) | tests using `com.lemonappdev.konsist` | runs as part of the test suite |

If none is configured, there is no automated architecture gate — fall back to the design conventions gathered in step 0 and eyeball your imports against them. Never add or weaken a rule just to pass; a violation means the change is misplaced.

## Completion — dependency-version security audit

Prefer the ecosystem-native audit. `osv-scanner` (Google OSV) is a good **language-agnostic fallback** that reads most lockfiles.

| Ecosystem | Native command | Notes |
|-----------|----------------|-------|
| Node/TS   | `npm audit` / `pnpm audit` / `yarn npm audit` | Use the matching package manager |
| Python    | `pip-audit` | reads installed env or `-r requirements.txt`; also `uv pip audit` where available |
| Go        | `govulncheck ./...` | reachability-aware; low false positives |
| Rust      | `cargo audit` | needs `cargo-audit` installed |
| Java/Kotlin | `./gradlew dependencyCheckAnalyze` (OWASP) / `mvn org.owasp:dependency-check-maven:check` | |
| Ruby      | `bundle audit` | |
| Any       | `osv-scanner --lockfile <path>` or `osv-scanner -r .` | language-agnostic fallback |

Report per finding: package, current version, severity/CVE, fixed version. Flag anything high/critical in a **direct** dependency explicitly. Do not auto-bump across a major version without telling the user it may be breaking.
