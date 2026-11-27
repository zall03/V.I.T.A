# Project status

Live frontend workspace now default; retained original demo behind DEMO_MODE=true.
Backend clinical HTTP workflow wired, but database/AI end-to-end NOT TESTED.
See LIVE_FRONTEND.md; interim structured JSON editor requires further UX work.

Frontend increment: API adapter implemented, analyze and 3 tests passed. Screen
binding remains incomplete; no claim of frontend/backend end-to-end success.

Current phase: foundation/Phase 2 gap closure under master PRD.

| Area | Status | Evidence |
|---|---|---|
| Phase 1 | PARTIALLY COMPLETED | Auth/users implemented; Go checks pass; facility API missing at inspection; DB not tested |
| Phase 2 | PARTIALLY COMPLETED | Clinical modules and AI service; 10 Python tests pass; database and Compose gates unmet |
| Phase 3 | BLOCKED / pending framework | No approved source-mapped rules or queue policy |
| Phase 4 | PARTIALLY COMPLETED planning | No client/outbox/sync implementation yet |
| Phase 5 | PARTIALLY COMPLETED | Baseline tests run, further coverage needed |

Git: backend and ai-service are untracked user workspace content; preserve all.
Tools: Go and Python usable; Flutter found at C:/src/flutter/bin/flutter.bat.
Docker, psql and cmake not found in PATH. Do not infer mobile build success.
Changed this milestone: root AGENTS.md and eight tracking documents.
Milestone: facility scoped GET/admin PATCH implemented, SQLC regenerated, auth/user
compatibility aliases added. Build/vet/unit tests passed; DB behavior NOT TESTED.
Next: configurable auth TTLs, facility integration tests, Phase 2 gaps.
Update: configurable ACCESS_TOKEN_TTL/REFRESH_TOKEN_TTL implemented, validated and
wired through Compose. Build/vet/tests passed. Next: facility integration and contracts.
