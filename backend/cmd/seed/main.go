package main

import (
	"backend/internal/database"
	"backend/internal/platform"
	"context"
	"errors"
	"github.com/go-playground/validator/v10"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"os"
	"strings"
)

func main() {
	if e := run(); e != nil {
		slog.Error("development_seed_failed")
		os.Exit(1)
	}
	slog.Info("development_seed_complete")
}
func run() error {
	if os.Getenv("APP_ENV") != "development" {
		return errors.New("seed requires APP_ENV=development")
	}
	email, password, name := strings.ToLower(os.Getenv("SEED_ADMIN_EMAIL")), os.Getenv("SEED_ADMIN_PASSWORD"), os.Getenv("SEED_FACILITY_NAME")
	if validator.New().Var(email, "required,email,max=254") != nil || len(password) < 12 || len(password) > 128 || name == "" {
		return errors.New("invalid seed configuration")
	}
	hash, e := platform.HashPassword(password)
	if e != nil {
		return e
	}
	ctx := context.Background()
	p, e := pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
	if e != nil {
		return e
	}
	defer p.Close()
	return pgx.BeginFunc(ctx, p, func(tx pgx.Tx) error {
		q := database.New(tx)
		_, e := q.UserByEmail(ctx, email)
		if e == nil {
			return errors.New("seed email exists; refusing to overwrite")
		}
		if !errors.Is(e, pgx.ErrNoRows) {
			return e
		}
		id, e := q.CreateFacility(ctx, name)
		if e != nil {
			return e
		}
		_, e = q.CreateUser(ctx, database.CreateUserParams{FacilityID: id, Email: email, Name: "Synthetic Development Administrator", PasswordHash: hash, Role: "admin"})
		return e
	})
}
