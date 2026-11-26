package encounter

import (
	"backend/internal/database"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"github.com/google/uuid"
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
func Access(ctx context.Context, q *database.Queries, u users.User, id uuid.UUID, lock bool) (database.Encounter, error) {
	if !u.Active || u.Role != "nurse" {
		return database.Encounter{}, platform.Forbidden
	}
	if lock {
		return q.LockEncounter(ctx, database.LockEncounterParams{ID: id, FacilityID: u.FacilityID, NurseID: u.ID})
	}
	return q.GetEncounter(ctx, database.GetEncounterParams{ID: id, FacilityID: u.FacilityID, NurseID: u.ID})
}
