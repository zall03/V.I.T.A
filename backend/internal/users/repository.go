package users

import (
	"backend/internal/database"
	"context"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	Pool *pgxpool.Pool
	Q    *database.Queries
}

func NewRepository(p *pgxpool.Pool) *Repository { return &Repository{p, database.New(p)} }
func (r *Repository) Get(ctx context.Context, id uuid.UUID) (User, error) {
	v, e := r.Q.UserByID(ctx, id)
	return FromRow(v), e
}
func (r *Repository) ByEmail(ctx context.Context, email string) (User, error) {
	v, e := r.Q.UserByEmail(ctx, email)
	return FromRow(database.UserByIDRow(v)), e
}
func (r *Repository) Transaction(ctx context.Context, fn func(*database.Queries) error) error {
	return pgx.BeginFunc(ctx, r.Pool, func(tx pgx.Tx) error { return fn(r.Q.WithTx(tx)) })
}
func Text(v *string) pgtype.Text {
	if v == nil {
		return pgtype.Text{}
	}
	return pgtype.Text{String: *v, Valid: true}
}
func Audit(ctx context.Context, q *database.Queries, actor User, target uuid.UUID, action string) error {
	return q.Audit(ctx, database.AuditParams{FacilityID: actor.FacilityID, ActorID: actor.ID, TargetID: pgtype.UUID{Bytes: target, Valid: true}, Action: action})
}
