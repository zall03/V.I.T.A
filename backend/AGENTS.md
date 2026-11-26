# V.I.T.A. repository instructions

Read `backend/prd disini/PRD.md` in full before development; it is the canonical
owner-supplied PRD. Read `backend/prd disini/AGENTS.md` and `backend/docs/` tracking.
Do not move or silently rewrite the source PRD.

Go/Gin modular monolith in backend owns PostgreSQL state. Stateless FastAPI in
ai-service performs extraction only. Flutter in frontend uses local whisper.cpp;
never replace it with cloud/OS STT. SQLC source lives in backend/db/queries;
regenerate generated code. Add forward Goose migrations; preserve existing files.
Handlers validate/transport, services own business rules, repositories access DB.
Use injected dependencies and contexts; no clinical payloads or secrets in logs.
Enforce role, facility, nested-object and version checks. Preserve verified history.
Mock/synthetic defaults; unapproved IITT rules disabled, no invented thresholds,
identifiers, external results or medical readiness claims. No push/deployment without
explicit authorization. Clinical care must not depend on software availability.

Checks from backend: `go build ./...`, `go vet ./...`, `go test ./...`,
`go test -tags=integration -count=1 ./tests/integration` with disposable test DB,
`go run github.com/sqlc-dev/sqlc/cmd/sqlc@v1.29.0 generate`.
AI: virtualenv Python `-m pytest -q`. Flutter: `flutter analyze`, `flutter test`.
Each phase needs actual applicable build/test evidence; blockers are not passes.
Update MASTER_PLAN, PROJECT_STATUS, IMPLEMENTATION_LOG, TEST_REPORT, BLOCKERS,
KNOWN_ISSUES and REMAINING_TASKS after milestones and before session interruption.
