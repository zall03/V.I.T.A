# Phase 1 implementation plan

Repository inspection: existing backend contains a minimal custom HTTP router;
frontend contains the standard Flutter counter application and platform scaffolds.
No existing API contract, database schema, or clinical domain implementation exists.

## Architecture

Modular monolith: `internal/auth`, `internal/users`, shared `internal/platform`,
SQLC-generated `internal/database`. Each business module separates DTOs, service,
repository, and HTTP handler. Composition root injects dependencies.
Legacy `core` prototype is retained. No clinical functionality belongs to Phase 1.

## Schema

Facilities own users. Users reference fixed roles. Refresh tokens reference users,
carry a family UUID, SHA-256 digest, expiration, consumption and revocation timestamps.
Audit logs contain action and identifiers only. All primary keys are UUIDs and
timestamps are timestamptz. IHS identifiers remain nullable.

## Security decisions

Access JWT lifetime: 15 minutes. Refresh lifetime: 7 days with absolute family
expiration. Rotation locks user and token records within a transaction. Reuse commits
family revocation before returning unauthorized. Access authentication checks current
account status, token version, facility and role from PostgreSQL. Password changes
invalidate all sessions. Administrators can manage nurse and queue_operator accounts
within their facility; administrator provisioning is development seed only.

## Delivery sequence

1. Schema, SQLC queries, configuration and security primitives.
2. Auth and user repositories/services/handlers; HTTP middleware.
3. Development seed, Docker Compose, OpenAPI and operational documentation.
4. Unit and database integration tests, formatting, vet and build.

Docker is absent from the initial environment. Database checks must be reported
separately from checks actually executed; missing infrastructure is not a test pass.
