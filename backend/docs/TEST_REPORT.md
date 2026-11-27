# Actual test evidence

Frontend alignment: Flutter 3.50.1, Dart 3.14.0. `flutter analyze`: no issues
(5.2s). `flutter test`: 3 passed (existing UI flow + 2 API transport tests).

Master baseline on Windows:
- `go build ./...`: passed.
- `go test ./...`: passed (some cached).
- `go vet ./...`: passed.
- ai-service `.venv/Scripts/python.exe -m pytest -q`: 10 passed, 2 dependency
  deprecation warnings, 5.57 seconds.
- Docker/PostgreSQL integration: NOT TESTED this milestone, tools absent from PATH.
- Flutter/native STT: NOT TESTED; Flutter executable located only.
- Live Gemini, WHO clinical validation, SATUSEHAT sandbox: NOT TESTED.

Historical dependency scans/evaluation are recorded in phase-2-implementation-report;
they are not represented as newly executed checks.

Facility increment: SQLC generation passed; gofmt applied; `go build ./...`,
`go vet ./...`, `go test ./...` passed, including new facility permission tests.
No live database facility test performed.
Token TTL increment: gofmt applied, build/vet/unit tests passed; platform tests
4.885s. Database rotation with configured TTL still needs integration execution.
