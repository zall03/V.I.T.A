# Live frontend increment

Default app entry now uses ClinicalWorkspace with existing theme. Original teammate
screens are retained behind explicit DEMO_MODE=true; not represented as live data.
Live workspace uses backend email/password login, nurse identity, patient list,
temporary patient creation, encounter create/start, manual text submission, AI job
enqueue/poll, assessment loading/editing, revision save and explicit verification.
Structured JSON editor is an interim UI, not the final field-by-field assessment form.
No local triage category is generated. Verified documentation does not imply triage.

Run backend stack first; create nurse using admin user management. For browser:
`flutter run -d edge --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8080`
Backend CORS_ORIGINS must include http://localhost:3000. Mobile requires reachable
backend host and appropriate HTTPS/platform configuration; localhost is device-local.
Mock provider remains clearly labeled; enabling Gemini requires backend AI settings,
explicit external processing enablement and configured model/key. No keys in Flutter.

Executed: flutter analyze no issues (4.5s); existing 3 tests pass before final unsaved
verification guard. No live Go/PostgreSQL/FastAPI E2E performed. New workspace lacks
dedicated widget test coverage. Existing UI test exercises demo only.

Remaining: polished field editor using original screens, encounter resume/history UI,
pagination, explicit retry UX, secure persistent sessions, whisper.cpp/native audio,
offline storage/sync. Backend remaining: full facility management, transcription STT
metadata/retry route, schema contract hardening, worker observability, IITT framework
and approved rules, queue/WebSocket, FHIR/SATUSEHAT outbox, sync endpoints, audit read,
comprehensive integration tests, CI and deployment/backup validation.
