# Phase 1 implementation report

## Delivered

- Modular Gin application with dependency injection and auth/user domain modules.
- PostgreSQL Goose migration for facilities, roles, users, refresh_tokens and audit_logs.
- SQLC v1.29.0 generated pgx access code and reproducible query configuration.
- Argon2id passwords, 15-minute JWTs, hashed opaque refresh tokens, seven-day
  absolute expiry, transactional rotation and committed reuse-family revocation.
- Login, refresh, logout, current identity, password change and admin user CRUD subset
  (create/list/detail/update/activation/deactivation).
- Facility isolation, fixed role allowlist, inactive-account denial, account-version
  invalidation, audit writes, safe response DTOs and structured metadata-only logs.
- Request IDs, panic handling, CORS allowlist, bounded rate limiter, 16 KiB request
  limit, strict JSON DTO validation, liveness and database readiness.
- Dockerfile, Compose dependencies, development seed, Makefile, environment example,
  OpenAPI contract, operational README and automated tests.

## Executed verification

Environment: Windows, Go 1.27.4.

| Check | Result |
|---|---|
| SQLC generation | Passed; SQL ambiguity found and fixed before regeneration |
| gofmt | Applied |
| go vet ./... | Passed |
| go build ./... | Passed |
| go test ./... | Passed |
| Integration test compilation | Passed |
| Integration execution | Blocked: TEST_DATABASE_URL missing |
| PostgreSQL migrations up/down | Not executed against live PostgreSQL |
| Docker image build / Compose startup | Not executed; Docker unavailable in PATH |

Unit tests cover password verification/salting, JWT expiration/signature, opaque
token randomness/digests, deny-by-default roles, sensitive-field exclusion, body
limits, strict JSON, CORS, rate limits and panic/log redaction.

Integration suite covers auth, refresh rotation/reuse/expiry, logout, password
invalidation, role denial, cross-facility denial, inactive accounts, user lifecycle,
sensitive response fields and migration rollback. Database-dependent behavior remains
unverified in this environment until the suite runs against PostgreSQL.

## Remaining verification

1. Configure `.env` and run `docker compose up --build -d`.
2. Run development seed and inspect `/health/ready`.
3. Set `TEST_DATABASE_URL` for a disposable PostgreSQL database, then run
   `go test -tags=integration -count=1 ./tests/integration`.

No real secrets or patient data were added. Existing Flutter files and original
`core/router.go` were retained. No medical production-readiness claim is made.
