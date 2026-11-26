# V.I.T.A. — Phase 2 Clinical Prototype

Phase 2 extends existing authentication with patients, nurse-owned encounters,
immutable transcripts, persisted extraction jobs, stateless FastAPI, optional Gemini,
assessment revisions and explicit nurse verification. No triage engine is included.

## Phase 2 quick start

Existing `.env` is preserved. Add a random `AI_SERVICE_TOKEN` of at least 32 characters
using `.env.example` as reference. Keep `AI_PROVIDER=mock` and
`EXTERNAL_AI_ENABLED=false` for synthetic development. From `backend/`:

```sh
docker compose up --build
# Separate terminal, first bootstrap only:
docker compose --profile tools run --rm seed
```

Services: PostgreSQL, migration, Go API, one bounded Go worker, FastAPI. Only API
port 8080 is published on loopback; PostgreSQL is no longer published by default.
AI code is in sibling `../ai-service`, so deploy the repository with both directories.
Admin creates a nurse via Phase 1 API; clinical routes require that nurse's login.
Server push is deferred. Deployment requires explicit server/TLS configuration.

Phase 2 docs: [architecture](docs/phase-2-architecture.md),
[API contract](docs/api-contract.md), [workflow](docs/clinical-workflow.md),
[schema](docs/database-schema.md), [AI contract](docs/ai-service-contract.md),
[privacy](docs/security-and-privacy.md), [tests](docs/testing-guide.md).

The sections below retain Phase 1 operation/security details. Phase 2 additions above
supersede old statements about absent AI functionality and published database ports.

Go/Gin modular monolith for authentication and facility-scoped user management.
PostgreSQL, pgx, SQLC, Goose, JWT, Argon2id, validator, slog and Testify.
This phase provides no clinical rules and makes no medical production-readiness claim.
Use synthetic data only.

## Local Docker setup

1. Install Docker Engine with Compose. Copy `.env.example` to `.env`.
2. Set `POSTGRES_PASSWORD` to a random local password, `JWT_SECRET` to at least
   32 random bytes, and `SEED_ADMIN_PASSWORD` to 12–128 characters. Use URL-safe
   values for the database password because Compose interpolates it into a URL.
3. Run `docker compose up --build -d`. Database health gates migration; successful
   migration gates API startup.
4. Run `docker compose --profile tools run --rm seed`. Seed requires explicit
   `APP_ENV=development`; it refuses existing email addresses and never overwrites users.
5. Check `http://localhost:8080/health/ready`. API listens on localhost port 8080.

No credentials are supplied by default. `.env` is ignored by Git and Docker builds.
Compose automatically reads `.env`; Go commands do not. Export variables when running
Go directly. Set `DATABASE_URL` with localhost host for host-side commands.

## Commands

| Action | Command |
|---|---|
| Development server | `go run .` |
| Migrate up | `go run ./cmd/migrate up` |
| Migration status | `go run ./cmd/migrate status` |
| Roll back latest migration | `go run ./cmd/migrate down` |
| Development seed | `go run ./cmd/seed` |
| Generate typed queries | `go run github.com/sqlc-dev/sqlc/cmd/sqlc@v1.29.0 generate` |
| Format | `gofmt -w main.go cmd internal tests` |
| Lint | `go vet ./...` |
| Build | `go build ./...` |
| Unit tests | `go test ./...` |
| Integration tests | `go test -tags=integration -count=1 ./tests/integration` |
| Stop containers | `docker compose down` |

Rollback removes Phase 1 tables and their data. Use only on disposable development databases.

Integration tests require `TEST_DATABASE_URL` pointing to a disposable PostgreSQL
database and permission to create schemas. Each run creates an isolated schema,
applies Goose migrations, exercises HTTP and database behavior, rolls migrations
back and drops the schema. Missing variable is a failure, not a silent skip.
Makefile provides equivalent targets. Windows users may run Go commands directly.

## Architecture

```text
main.go                 composition and graceful HTTP shutdown
cmd/migrate/            Goose CLI wrapper
cmd/seed/               explicit development-only bootstrap
internal/app/           router and dependency injection
internal/auth/          auth DTOs, repository, service, handlers
internal/users/         domain, DTOs, repository, service, handlers
internal/platform/      config, crypto, HTTP envelopes, middleware
internal/database/      generated SQLC code; regenerate, do not edit
db/migrations/          PostgreSQL schema
db/queries/             SQLC queries
docs/                   implementation plan and OpenAPI contract
tests/integration/      disposable-schema API tests
core/                   retained original router prototype
```

Facilities own users; fixed roles authorize operations. Refresh token families belong
to users. Audit records store identifiers and action names only. `organization_ihs`
and `practitioner_ihs` are nullable extension points. Future modules can consume user
identity and facility context through injected services; no Flutter, AI, queue,
IITT or SATUSEHAT behavior is included.

## API

OpenAPI 3 contract: [`docs/openapi.yaml`](docs/openapi.yaml), served at `/openapi.yaml`.
Import into Swagger Editor/UI or API tooling.

| Method | Path | Authorization |
|---|---|---|
| GET | `/health/live` | Public |
| GET | `/health/ready` | Public, PostgreSQL ping |
| POST | `/api/v1/auth/login` | Public, rate limited |
| POST | `/api/v1/auth/refresh` | Opaque refresh token, rate limited |
| POST | `/api/v1/auth/logout` | Bearer access token + owned refresh token |
| GET | `/api/v1/auth/me` | Any active supported role |
| POST | `/api/v1/auth/change-password` | Authenticated, rate limited |
| POST | `/api/v1/users` | Admin |
| GET | `/api/v1/users?limit=20&offset=0` | Admin |
| GET | `/api/v1/users/{id}` | Admin, same facility |
| PUT | `/api/v1/users/{id}` | Admin, same facility, non-admin target |
| PATCH | `/api/v1/users/{id}/active` | Admin, same facility, non-admin target |

Login body: `{"email":"admin@example.test","password":"<configured seed password>"}`.
Refresh/logout body: `{"refresh_token":"<opaque token>"}`.
Activation body: `{"active":true}`; deactivation: `{"active":false}`.
Use `Authorization: Bearer <access_token>` for protected endpoints.

Success: `{"data":{},"request_id":"uuid"}`.
Failure: `{"error":{"code":"unauthorized","message":"unauthorized"},"request_id":"uuid"}`.
Validation: 400; authentication: 401; denied role: 403; absent/cross-facility user:
404; duplicate unique field: 409; body too large: 413; rate limit: 429.
Unknown request fields are rejected. User responses exclude password and token hashes.

## Security semantics

- JWT HS256, fixed issuer/audience/algorithm, mandatory expiry, 15-minute lifetime.
- Random 256-bit opaque refresh tokens; only SHA-256 digests stored. Seven-day
  absolute family lifetime. Rotation consumes previous token atomically. Reuse
  commits family revocation before returning 401. Clients must serialize refreshes.
- Logout revokes refresh family. Already-issued access JWT remains valid up to
  15 minutes; password change, user edit and activation changes invalidate JWTs
  immediately through database token-version checks.
- Argon2id: 64 MiB, three iterations, two lanes, 16-byte salt, 32-byte output.
- Active account and current role loaded for every protected request. Unknown roles
  denied. Admin cannot create/promote/edit admin accounts or choose another facility.
- Request body limit: 16 KiB. Explicit CORS allowlist. Proxy headers untrusted.
- Login and refresh share ten requests/minute/peer-IP per process. Password change
  has its own limiter. Memory bounded to 10,000 peer entries. Multi-instance deployment
  needs a shared limiter and explicitly configured trusted ingress.
- Logs contain route templates, method, status, duration and generated request ID;
  never request bodies, raw paths, query strings, credentials or panic payloads.
- Compose is local development configuration. TLS termination and managed secrets
  belong to deployment configuration; database SSL is disabled only in local examples.

## Verification

See `docs/IMPLEMENTATION_REPORT.md` for executed checks and environment limitations.
