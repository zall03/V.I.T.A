# Resume / remaining work

Biometric acceptance: test real Android sensor opt-in, restart/unlock, cancellation,
expired refresh, logout deletion; validate iOS Keychain entitlements/build separately.

Run new deployment workflow on main after configuring development environment and
server env; diagnose CI/database errors without skipping tests. Add HTTPS ingress
and Flutter web hosting separately. See SSH_DEPLOYMENT.md.

Live integration next: run actual stack E2E, add workspace widget tests, polish native
field editor and resume/retry/history flows. LIVE_FRONTEND.md records limitations.

Active user request: align updated frontend with existing backend. API adapter added;
next wire explicit live login/profile and clinical DTO/workflow without reusing demo
clinical classifications. See FRONTEND_ALIGNMENT.md. Entire screen binding pending.

Read root AGENTS, canonical PRD and all tracking before changes.
Facility scoped read/admin update and aliases implemented; unit checks passed.
Immediate next: configurable auth TTLs, facility integration tests and OpenAPI
entries for new aliases/facility routes. Database test infrastructure still required.
TTL configuration now implemented and tested. Remaining immediate tasks are facility
integration tests and OpenAPI updates including configurable expires_in.
Then close Phase 2 schema/provenance/worker gaps, native STT inspection, source-gated
triage framework, queue, WebSocket, FHIR client/outbox, sync, CI and E2E.
Do not treat planning or disabled endpoints as completed domain functionality.
Detailed roadmap: MASTER_PLAN.md; actual baseline evidence: TEST_REPORT.md.
