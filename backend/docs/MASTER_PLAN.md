# Master execution plan

Mobile biometric login increment built on Android; device acceptance and stronger
hardware auth-bound storage remain pending. See BIOMETRIC_LOGIN.md.

Canonical requirements: `../prd disini/PRD.md` v1.0. Preserve existing implementation.

1. FR-01/02/18/19: review foundation, facility management, configurable TTLs,
   compatibility aliases, stronger database/runtime verification.
2. FR-03–10: close Phase 2 contract/worker gaps, STT provenance and whisper.cpp
   native integration, shared schema fixtures and real local Go/FastAPI tests.
3. FR-11–14: source/approval-gated deterministic triage framework, persisted human
   decisions, approved-policy queue and authenticated durable-event WebSocket.
4. FR-15–17: authoritative profile review, guarded sandbox client/outbox and
   idempotent synchronization with explicit conflicts.
5. FR-18/19: CI, negative security tests, E2E, deployment/backup docs, evaluation.

No phase declared complete until acceptance gates pass. Continue independent work
when external governance, credentials, infrastructure or devices are unavailable.

Foundation milestone implemented: minimal facility read/admin name update and API
aliases; verified via SQLC/build/vet/unit tests, database acceptance still pending.
Configurable token TTL milestone implemented and unit-tested; defaults preserved.
