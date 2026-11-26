# Security and privacy

Default synthetic data and mock provider. External processing requires explicit
EXTERNAL_AI_ENABLED=true, configured model and key. Before real patient data is
processed externally, obtain institutional approval, privacy/legal review, provider
data-handling and retention review, and appropriate contractual safeguards. Technical
controls alone do not establish regulatory compliance or medical readiness.

Go minimizes known patient names, local MRNs and IHS identifiers plus common labeled
identifiers/number patterns. This is incomplete de-identification: free text can retain
names, addresses, rare conditions and indirect identifiers. Do not treat redaction as
anonymization or permission to process patient data externally.

Clinical endpoints deny non-nurses; facility and assigned-nurse checks protect nested
resources. SQL is parameterized. Optimistic versions and row locks prevent lost edits.
AI jobs use leases and fencing, preserve failures and never automatically verify.
Internal tokens use constant-time comparison. No raw provider errors are returned.

Logs contain status/duration/request IDs only. Uvicorn access logging disabled.
Audit stores actor/resource/action metadata and has no public read route. Cancellation
reasons and clinical histories remain protected database content, never log messages.

Compose exposes only Go API on loopback. DB and AI have no published ports. Internal
network is isolated; AI has separate egress for explicitly enabled Gemini. Production
deployment must provide TLS ingress, encrypted volumes/backups, restricted DB accounts,
secret storage/rotation, retention/deletion policy and tested restoration procedures.
No server push or deployment was performed.
