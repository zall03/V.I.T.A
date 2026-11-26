# Known issues

- Database migrations and transaction behavior remain unverified against live DB.
- Phase 2 OpenAPI clinical response schemas are incomplete.
- Patient PATCH replaces demographics rather than partial field merge (documented).
- Worker lacks operational heartbeat endpoint and explicit retry route.
- Free-text identifier minimization cannot guarantee anonymization.
- AI mock recognizes one exact fixture only; not general extraction.
- Go/Python schema strictness differs; shared contract fixture tests needed.
- Two Python dependency deprecation warnings remain.
- New facility/compatibility routes need OpenAPI and database integration coverage.
- OpenAPI still fixes expires_in to 900; update to reflect configurable lifetime.
