# Implementation log

Added automatic main-branch SSH deployment with pinned actions, isolated PostgreSQL
CI tests, verified SSH host keys, release directories, persistent server env, explicit
migrations and health checks. No push/deployment executed during implementation.

Live workspace added: login, patients, temporary intake, encounter, transcript, AI
polling, revision and verification via API. No fabricated triage category. Original
demo preserved explicitly. Analyze passed and 3 existing tests passed.

## Frontend alignment increment
Added backend API adapter and two transport tests; pinned http dependency. Existing
UI flow test retained. Flutter analyze and all three tests passed. Adapter not wired
to demo screens yet. See FRONTEND_ALIGNMENT.md for exact remaining integration.

## Master baseline
- Read owner AGENTS and full 450-line PRD, README and prior report.
- Inspected Git, existing migrations/auth/API/Compose through previous context and
  current repository state. No existing master tracking documents found.
- Re-ran Go build/test/vet and Python tests successfully.
- Created persistent tracking; no completed modules recreated or secrets read.

## Facility foundation increment
- Added internal/facility service, handler and deny-before-database tests.
- Added SQLC facility read/update queries and generated code.
- Added GET/PATCH /api/v1/facilities/me and compatible PATCH auth/password,
  users/:id, users/:id/status aliases. Existing routes retained.
- SQLC generation, gofmt, build, vet and unit tests passed.

## Configurable token lifetime
- Added validated whole-second Go durations, default 15m access / 168h refresh.
- JWT expiration and expires_in use access configuration; initial family expiry uses
  refresh configuration. Rotation retains original absolute family expiration.
- Updated Compose and env example, preserved local .env.
- Added default/invalid/custom duration and signed JWT lifetime tests; Go checks pass.
