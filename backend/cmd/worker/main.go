package main

import (
	"backend/internal/encounter"
	"backend/internal/extraction"
	"backend/internal/integration/ai"
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	log := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	if e := run(log); e != nil {
		log.Error("worker_failed")
		os.Exit(1)
	}
}
func run(log *slog.Logger) error {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	p, e := pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
	if e != nil {
		return e
	}
	defer p.Close()
	if e = p.Ping(ctx); e != nil {
		return e
	}
	gateway, e := ai.NewClient(os.Getenv("AI_SERVICE_URL"), os.Getenv("AI_SERVICE_TOKEN"))
	if e != nil {
		return e
	}
	w := extraction.Worker{Repo: encounter.NewRepository(p), Gateway: gateway, Log: log}
	return w.Run(ctx)
}
