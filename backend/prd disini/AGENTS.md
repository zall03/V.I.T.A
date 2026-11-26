# V.I.T.A. — Coding Agent Instructions

## Required reading and source of truth

Before changing code, read root `PRD.md` in full. It is the persistent product requirements and technical baseline covering all phases. Also read existing repository instructions, README, and any available `docs/MASTER_PLAN.md`, `PROJECT_STATUS.md`, `ARCHITECTURE_DECISIONS.md`, `IMPLEMENTATION_LOG.md`, `TEST_REPORT.md`, `BLOCKERS.md`, `KNOWN_ISSUES.md`, and `REMAINING_TASKS.md` (under `docs/`). Inspect actual code, Git status, migrations and tests. Never assume a previous phase is implemented. Respect higher-priority instructions and explicit owner authorization; if requirements conflict, record the issue and preserve safety. Do not silently change the PRD.

## Non-negotiable project constraints

- Go/Gin core backend and PostgreSQL own application state. Python FastAPI is a stateless internal Gemini extraction service. No direct mobile-to-Gemini/SATUSEHAT calls.
- whisper.cpp is mandatory for local Indonesian multilingual STT. Do not replace it with cloud STT. If Flutter repository/toolchain is absent, deliver contract/harness and mark native integration blocked.
- AI extracts only explicit clinical information; never diagnoses, recommends treatment, assigns triage, invents missing values or follows transcript instructions. Preserve source transcript, AI draft, human revision and verification independently. Late AI cannot overwrite newer human work.
- Clinical rules require exact authoritative WHO IITT sources and clinical approval. No invented thresholds. Unapproved rules disabled. Human confirms or overrides recommendation; care must never wait for AI or paperwork.
- FHIR mapping requires applicable official SATUSEHAT profiles. Mock/sandbox default; no real production submission or fabricated identifiers.
- Synthetic data and mock external providers by default. No real patient data sent externally without explicit authorized governance. No secrets or clinical payloads in operational logs. Enforce facility/object authorization, secure tokens and safe audit access.
- Preserve Git changes and existing migrations; no destructive commands, production deployment or remote push without authorization.

## Execution protocol

1. Inspect baseline, run available tests and record failures. Create/update the persistent tracking files listed in PRD §21 if missing.
2. Map unfinished requirement IDs to phases; implement in small, testable increments. Do not stop after planning. Preserve working behavior and avoid unnecessary rewrites.
3. For each increment run relevant formatting, static checks, build and tests; fix regressions; update progress, architectural decisions, blockers and test evidence.
4. Missing credentials, device, authoritative clinical sources or approvals: mark blocked, use explicitly labeled mocks/test-only rules, and continue independent implementation. Do not bypass safety gates.
5. Before context/session interruption, persist current status, exact next task, commands, failures and changed files. Resume from these files next session, not from scratch.
6. Final report per requirement/phase: COMPLETED / PARTIALLY COMPLETED / BLOCKED / NOT TESTED. Report actual evidence, not fabricated metrics or unrun tests. No clinical validation, compliance or production-ready claim based on software tests.

## Verification commands

Discover actual project commands in README/Makefile/CI. Expected commands where configured: `go test ./...`, `go vet ./...`, `go build ./...`, Python `pytest`, SQLC generation, Goose migration against an isolated test DB, `docker compose config`, Docker build and mock E2E. Do not invent passing outputs or run destructive migrations. Document unavailable tools. Live Gemini/SATUSEHAT tests must be opt-in, authorized, and synthetic-only.

## Resume task

Read PRD.md and tracking documents, verify repository state, then continue the next unfinished feasible phase. Update documentation continuously. The goal is a functioning and honestly documented development prototype, not autonomous clinical deployment.
