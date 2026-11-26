package patient

import (
	"backend/internal/database"
	"context"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	Pool *pgxpool.Pool
	Q    *database.Queries
}

func NewRepository(p *pgxpool.Pool) *Repository { return &Repository{p, database.New(p)} }
func (r *Repository) Tx(ctx context.Context, fn func(*database.Queries) error) error {
	return pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error { return fn(r.Q.WithTx(tx)) })
}
