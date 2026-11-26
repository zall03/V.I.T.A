package auth

import (
	"backend/internal/database"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"errors"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"strings"
	"time"
)

type Service struct {
	Repo       *Repository
	Tokens     platform.Tokens
	DummyHash  string
	RefreshTTL time.Duration
}

func (s *Service) issue(ctx context.Context, q *database.Queries, u users.User, family uuid.UUID, expiry time.Time) (Pair, error) {
	raw, e := platform.Opaque()
	if e != nil {
		return Pair{}, e
	}
	access, e := s.Tokens.Access(u.ID, u.Version)
	if e != nil {
		return Pair{}, e
	}
	e = q.InsertRefresh(ctx, database.InsertRefreshParams{UserID: u.ID, FamilyID: family, TokenHash: platform.Digest(raw), ExpiresAt: pgtype.Timestamptz{Time: expiry, Valid: true}})
	return Pair{access, raw, "Bearer", int(s.Tokens.Lifetime() / time.Second)}, e
}
func (s *Service) Login(ctx context.Context, d LoginDTO) (Pair, error) {
	u, e := s.Repo.ByEmail(ctx, strings.ToLower(d.Email))
	if errors.Is(e, pgx.ErrNoRows) {
		platform.VerifyPassword(s.DummyHash, d.Password)
		return Pair{}, platform.Unauthorized
	}
	if e != nil {
		return Pair{}, e
	}
	if !platform.VerifyPassword(u.PasswordHash, d.Password) || !u.Active {
		return Pair{}, platform.Unauthorized
	}
	var out Pair
	e = s.Repo.Transaction(ctx, func(q *database.Queries) error {
		if _, e := q.LockUser(ctx, u.ID); e != nil {
			return e
		}
		r, e := q.UserByID(ctx, u.ID)
		if e != nil {
			return e
		}
		if !r.Active || r.PasswordHash != u.PasswordHash {
			return platform.Unauthorized
		}
		u = users.FromRow(r)
		ttl := s.RefreshTTL
		if ttl == 0 {
			ttl = 7 * 24 * time.Hour
		}
		out, e = s.issue(ctx, q, u, uuid.New(), time.Now().Add(ttl))
		if e != nil {
			return e
		}
		return users.Audit(ctx, q, u, u.ID, "auth.login")
	})
	return out, e
}
func (s *Service) Refresh(ctx context.Context, raw string) (Pair, error) {
	t, e := s.Repo.Q.FindRefresh(ctx, platform.Digest(raw))
	if errors.Is(e, pgx.ErrNoRows) {
		return Pair{}, platform.Unauthorized
	}
	if e != nil {
		return Pair{}, e
	}
	var out Pair
	denied := false
	e = s.Repo.Transaction(ctx, func(q *database.Queries) error {
		if _, e := q.LockUser(ctx, t.UserID); e != nil {
			return e
		}
		t, e = q.LockRefresh(ctx, platform.Digest(raw))
		if e != nil {
			return e
		}
		r, e := q.UserByID(ctx, t.UserID)
		if e != nil {
			return e
		}
		u := users.FromRow(r)
		if t.ConsumedAt.Valid || t.RevokedAt.Valid {
			denied = true
			if e = q.RevokeFamily(ctx, t.FamilyID); e != nil {
				return e
			}
			return users.Audit(ctx, q, u, u.ID, "auth.refresh_reuse")
		}
		if !u.Active || !t.ExpiresAt.Time.After(time.Now()) {
			denied = true
			return q.RevokeFamily(ctx, t.FamilyID)
		}
		if e = q.ConsumeRefresh(ctx, t.ID); e != nil {
			return e
		}
		out, e = s.issue(ctx, q, u, t.FamilyID, t.ExpiresAt.Time)
		return e
	})
	if e != nil {
		return Pair{}, e
	}
	if denied {
		return Pair{}, platform.Unauthorized
	}
	return out, nil
}
func (s *Service) Logout(ctx context.Context, u users.User, raw string) error {
	return s.Repo.Transaction(ctx, func(q *database.Queries) error {
		if _, e := q.LockUser(ctx, u.ID); e != nil {
			return e
		}
		t, e := q.LockRefresh(ctx, platform.Digest(raw))
		if errors.Is(e, pgx.ErrNoRows) {
			return nil
		}
		if e != nil {
			return e
		}
		if t.UserID != u.ID {
			return platform.Unauthorized
		}
		if e = q.RevokeFamily(ctx, t.FamilyID); e != nil {
			return e
		}
		return users.Audit(ctx, q, u, u.ID, "auth.logout")
	})
}
func (s *Service) Password(ctx context.Context, u users.User, d PasswordDTO) error {
	if d.CurrentPassword == d.NewPassword {
		return platform.Invalid
	}
	hash, e := platform.HashPassword(d.NewPassword)
	if e != nil {
		return e
	}
	return s.Repo.Transaction(ctx, func(q *database.Queries) error {
		if _, e := q.LockUser(ctx, u.ID); e != nil {
			return e
		}
		r, e := q.UserByID(ctx, u.ID)
		if e != nil {
			return e
		}
		if !r.Active || r.TokenVersion != u.Version || !platform.VerifyPassword(r.PasswordHash, d.CurrentPassword) {
			return platform.Unauthorized
		}
		if e = q.ChangePassword(ctx, database.ChangePasswordParams{ID: u.ID, PasswordHash: hash}); e != nil {
			return e
		}
		if e = q.RevokeUser(ctx, u.ID); e != nil {
			return e
		}
		return users.Audit(ctx, q, u, u.ID, "auth.password_changed")
	})
}
func (s *Service) Authenticate(ctx context.Context, raw string) (users.User, error) {
	c, e := s.Tokens.Parse(raw)
	if e != nil {
		return users.User{}, platform.Unauthorized
	}
	id, _ := uuid.Parse(c.Subject)
	u, e := s.Repo.Get(ctx, id)
	if errors.Is(e, pgx.ErrNoRows) {
		return u, platform.Unauthorized
	}
	if e != nil {
		return u, e
	}
	if !u.Active || u.Version != c.Version {
		return users.User{}, platform.Unauthorized
	}
	switch u.Role {
	case "admin", "nurse", "queue_operator":
		return u, nil
	}
	return users.User{}, platform.Forbidden
}
