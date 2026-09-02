# AGENTS.md — Operating Manual for AI Coding Agents

<!-- ЗАПОЛНИТЬ: замените абзац ниже описанием ВАШЕГО проекта. Важно: строка
     "This is a ..." должна остаться в первых 10 строках файла — её ищет
     скрипт проверки audit-harness.sh ("что это за система" в начале файла). -->
This is a harness template for AI coding agents: a project skeleton that makes agent
sessions start fast, stay in scope, verify their work, and resume cleanly.

<!-- ЗАПОЛНИТЬ: 1–2 предложения о назначении проекта (что строим и для кого). -->

## Startup Workflow

Before writing code (session start / clock-in):

1. Confirm working directory with `pwd`
2. Read this file completely
3. Read project docs if present: [Architecture](docs/ARCHITECTURE.md), [Product](docs/PRODUCT.md)
4. Run `./init.sh` to verify the environment is healthy
5. Read `feature_list.json` to see current feature state
6. Review recent commits with `git log --oneline -5`
7. Read `progress.md` and `session-handoff.md` if present

If baseline verification is failing, repair that first — do not add new scope on a broken baseline.

## Working Rules

- **One feature at a time**: pick exactly one unfinished feature from `feature_list.json` (WIP=1 — only one feature may have `state: active` at a time)
- **Verification required**: run verification commands before claiming any work done
- **Update artifacts**: before ending session, update `progress.md` and `feature_list.json`
- **Stay in scope**: do not modify files unrelated to the current feature
- **Leave clean state**: the repo must remain restartable — next session runs `./init.sh` immediately

## Constraints

<!-- ЗАПОЛНИТЬ: жёсткие запреты и ограничения вашего проекта.
     Формат: правило + "why:" — причина правила (почему оно существует). -->

- MUST NOT commit secrets, tokens, or credentials. why: security.
- MUST NOT force-push to protected branches. why: git history is the system of record.
- MUST NOT set `state: passing` directly in `feature_list.json` — run `make verify-feature F=<id>`. why: passing requires verification evidence.
- Update docs in the same commit as the code change — no stale documentation. why: docs rot fast.
- Commits are atomic: one logical operation per commit; the repo is in a consistent state after every commit. why: clean rollback.

## Required Artifacts

- `feature_list.json` — feature state tracker (source of truth)
- `progress.md` — session continuity log
- `DECISIONS.md` — decision log (decision + context + alternatives)
- `init.sh` — standard startup and verification path
- `session-handoff.md` — cross-session handoff (fill for large sessions)
- `docs/ARCHITECTURE.md`, `docs/PRODUCT.md`, `docs/quality-document.md` — topic docs
- `docs/adr/` — architecture decision records (реестр ключевых решений + [шаблон](docs/adr/ADR-TEMPLATE.md))
- `docs/api/openapi.yaml` — API contract (spec-first), `docs/diagrams/er-data-model.md` — canonical data model
- `solution/` — план-сессий многосессионных проектов: индекс (`solution/sessions.md`), канон ([solution/sessions/S00_session.md](solution/sessions/S00_session.md)), журнал противоречий (`solution/FIXES.md`)

## Feature State Rules

`feature_list.json` is the single source of truth. State machine:

`not_started` → `active` → `passing`

- Skipping states is not allowed.
- Never set `state: passing` directly — run `make verify-feature F=<id>` (or `bash scripts/verify-feature.sh <id>`); the script runs the feature's verification command and records evidence.
- A feature should be completable in one session; a large feature may span several sessions: exactly one final session closes it via `make verify-feature F=<id>`, intermediate sessions leave it `active` with a documented continuation (clean-check allowlist) and record progress in `progress.md`
- Record evidence (command and output) in `feature_list.json` and `progress.md`.

## Definition of Done

A feature is done only when runtime evidence passes — not when code is written. Three layers:

1. **Layer 1 — syntax/static**: build, compile, lint, type-check
2. **Layer 2 — runtime behavior**: tests and the feature's `verification` command from `feature_list.json`
3. **Layer 3 — system confirmation**: end-to-end run / manual check

Do not proceed to the next layer if the previous one fails. Done checklist:

- [ ] Target behavior implemented
- [ ] Required verification actually ran (tests / lint / type-check)
- [ ] Evidence recorded in `feature_list.json` and `progress.md`
- [ ] Repository remains restartable from the standard startup path (`./init.sh`)
- [ ] App reaches ready state, side effects are correct, no debug artifacts remain

Layer 3 (e2e) is required when changes cross component or domain boundaries.

## Verification Commands

```bash
# Full verification (recommended) — exits 0 when the repo is consistent
make check          # runs ./init.sh (stack auto-detection)
./init.sh           # direct path
```

<!-- ЗАПОЛНИТЬ: впишите реальные команды верификации вашего проекта,
     например: mvn test / ./gradlew check / npm test / pytest. -->
Required checks:

- Tests: `./init.sh` (auto-detects stack: Maven, Gradle, npm, Python, Go, Rust, .NET)
- Build/static: `./init.sh`

The repo is in a consistent state when `make check` exits 0.

## Architecture Boundaries

<!-- ЗАПОЛНИТЬ: опишите модель слоёв/компонентов и допустимые зависимости между ними. -->

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Constraint violations are reported with what/why/fix. Every new error category caught in code review is promoted into a rule in `.harness/arch-rules.json` (optional; create when the project grows).

## Tools & Permissions

<!-- ЗАПОЛНИТЬ: какие инструменты/MCP/интеграции доступны агенту и их границы. -->

- File edits: allowed inside project scope only
- Shell: read/debug commands freely; destructive commands require explicit user approval
- MCP/integrations: document here when added

## Observability

- Before each feature, agree on scope via a sprint contract: [templates/sprint-contract.md](templates/sprint-contract.md)
- Record verification runtime signals (command and output) in `progress.md` → Evidence of Completion
- Score completed work against [templates/evaluator-rubric.md](templates/evaluator-rubric.md) — every dimension must reach B or above

## End of Session

Before ending a session (session end / clock-out):

1. Update `progress.md` (Current State, Next Steps)
2. Update `feature_list.json` (state + evidence)
3. Record unresolved risks or blockers in `progress.md` and `DECISIONS.md`
4. Run the clean-state protocol: `make clean-check` + [templates/clean-state-checklist.md](templates/clean-state-checklist.md) — no debug artifacts remain
5. Update `docs/quality-document.md` for the module you touched (A/B/C/D per dimension)
6. Commit once work is in a safe state — commit messages explain WHY, not just what changed
7. Leave the repo clean and restartable: next session runs `./init.sh` immediately

If running low on context, do not rush to finish — stop, update `progress.md`, and commit a clean checkpoint.

Cleanup is dual-mode: immediate cleanup after every session + periodic (weekly) full sweep for structural drift.

## Escalation

- **Architecture decisions**: consult `docs/ARCHITECTURE.md` and the ADR index (`docs/adr/`); significant decisions get a new ADR, otherwise ask the user
- **Data/API changes**: sync `docs/diagrams/er-data-model.md` and `docs/api/openapi.yaml` in the same commit as the migration/code
- **Unclear requirements**: check `docs/PRODUCT.md`, otherwise ask the user
- **Repeated test failures**: update `progress.md`, flag for human review
- **Scope ambiguity**: re-read the feature's definition of done in `feature_list.json`
