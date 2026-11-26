# Testing guide

```sh
go run github.com/sqlc-dev/sqlc/cmd/sqlc@v1.29.0 generate
gofmt -w main.go cmd internal tests
go vet -tags=integration ./...
go build ./...
go test ./...
go test -tags=integration -count=1 ./tests/integration
go run golang.org/x/vuln/cmd/govulncheck@v1.10.0 ./...
```

Integration requires TEST_DATABASE_URL for disposable PostgreSQL with schema creation
permission. It fails explicitly without it. Each suite creates a unique schema.
Clinical suite exercises migration, unknown identity, isolation, duplicate transcripts,
cross-encounter rejection, worker lease recovery, verification, concurrent corrections,
immutable verified revisions, manual fallback and audits. Phase 1 suite preserved.

AI service:
```sh
python -m pip install -r requirements.txt
python -m pytest -q
python evaluate.py
python -m pip_audit --progress-spinner off
python export_openapi.py
```

Gemini calls mocked in automated tests. No API key required. Evaluation dataset has
14 synthetic cases; fixture mock intentionally fails general extraction tasks. Report
actual matching counts, never interpret fixture scores as Gemini or clinical accuracy.
Real Gemini evaluation remains opt-in and must use synthetic inputs only.

Compose smoke test: start stack, seed admin, create nurse through Phase 1 API, login
as nurse, create temporary patient, create/start encounter, submit transcript, enqueue,
poll status, fetch assessment, verify using current encounter version.
