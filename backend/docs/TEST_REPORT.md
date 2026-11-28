# Actual test evidence

Biometric increment: final flutter test 3 passed; flutter analyze no issues (4.7s);
Android debug APK built (43s). Tests cover fallback, not actual sensor verification.

Admin recovery increment: gofmt, go build ./..., go vet ./..., go test ./... passed.
Recovery database transaction and remote command NOT TESTED against live database.

Android debug build: raised frontend Android Gradle Plugin 9.1.0 to 9.1.1 to satisfy
installed Flutter minimum. `flutter build apk --debug
--dart-define=API_BASE_URL=https://vita.senindrai.my.id` passed (135.1s), output
frontend/build/app/outputs/flutter-apk/app-debug.apk. Gradle/AGP/Kotlin future-support
warnings remain. Device installation and live API requests NOT TESTED by this build.

SSH workflow: source added; GitHub Actions execution, shell runtime and remote server
deployment NOT TESTED in this session. No credentials accessed or external deploy run.

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
