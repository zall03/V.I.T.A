package users

import (
	"backend/internal/database"
	"backend/internal/platform"
	"context"
	"github.com/google/uuid"
	"strings"
)

type Service struct{ Repo *Repository }

func (s *Service) Detail(ctx context.Context, a User, id uuid.UUID) (User, error) {
	if !CanManage(a) {
		return User{}, platform.Forbidden
	}
	u, e := s.Repo.Get(ctx, id)
	if e != nil {
		return u, e
	}
	if u.FacilityID != a.FacilityID {
		return User{}, platform.NotFound
	}
	return u, nil
}
func (s *Service) List(ctx context.Context, a User, limit, offset int32) ([]User, error) {
	if !CanManage(a) {
		return nil, platform.Forbidden
	}
	rows, e := s.Repo.Q.ListUsers(ctx, database.ListUsersParams{FacilityID: a.FacilityID, Limit: limit, Offset: offset})
	out := make([]User, 0, len(rows))
	for _, r := range rows {
		out = append(out, FromRow(database.UserByIDRow(r)))
	}
	return out, e
}
func (s *Service) Create(ctx context.Context, a User, d CreateDTO) (User, error) {
	if !CanManage(a) || !AllowedRole(d.Role) {
		return User{}, platform.Forbidden
	}
	hash, e := platform.HashPassword(d.Password)
	if e != nil {
		return User{}, e
	}
	var id uuid.UUID
	e = s.Repo.Transaction(ctx, func(q *database.Queries) error {
		var err error
		id, err = q.CreateUser(ctx, database.CreateUserParams{FacilityID: a.FacilityID, Email: strings.ToLower(d.Email), Name: d.Name, PasswordHash: hash, Role: d.Role, PractitionerIhs: Text(d.PractitionerIHS)})
		if err != nil {
			return err
		}
		return Audit(ctx, q, a, id, "user.created")
	})
	if e != nil {
		return User{}, e
	}
	return s.Repo.Get(ctx, id)
}
func (s *Service) Modify(ctx context.Context, a User, id uuid.UUID, d *UpdateDTO, active *bool) (User, error) {
	if !CanManage(a) {
		return User{}, platform.Forbidden
	}
	if d != nil && !AllowedRole(d.Role) {
		return User{}, platform.Forbidden
	}
	e := s.Repo.Transaction(ctx, func(q *database.Queries) error {
		if _, e := q.LockUser(ctx, id); e != nil {
			return e
		}
		r, e := q.UserByID(ctx, id)
		if e != nil {
			return e
		}
		if r.FacilityID != a.FacilityID {
			return platform.NotFound
		}
		if r.Role == "admin" {
			return platform.Forbidden
		}
		if d != nil {
			_, e = q.UpdateUser(ctx, database.UpdateUserParams{ID: id, FacilityID: a.FacilityID, Name: d.Name, Email: strings.ToLower(d.Email), Role: d.Role, PractitionerIhs: Text(d.PractitionerIHS)})
		} else {
			_, e = q.SetActive(ctx, database.SetActiveParams{ID: id, FacilityID: a.FacilityID, Active: *active})
		}
		if e != nil {
			return e
		}
		if e = q.RevokeUser(ctx, id); e != nil {
			return e
		}
		return Audit(ctx, q, a, id, "user.updated")
	})
	if e != nil {
		return User{}, e
	}
	return s.Repo.Get(ctx, id)
}
