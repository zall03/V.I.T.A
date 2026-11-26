.PHONY: dev up down migrate migrate-down seed sqlc fmt lint build test integration check
dev:
	go run .
up:
	docker compose up --build -d
down:
	docker compose down
migrate:
	go run ./cmd/migrate up
migrate-down:
	go run ./cmd/migrate down
seed:
	go run ./cmd/seed
sqlc:
	go run github.com/sqlc-dev/sqlc/cmd/sqlc@v1.29.0 generate
fmt:
	gofmt -w main.go cmd internal
lint:
	go vet ./...
build:
	go build ./...
test:
	go test ./...
integration:
	go test -tags=integration -count=1 ./tests/integration
check: lint build test
