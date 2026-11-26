package facility

import (
	"backend/internal/database"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"github.com/google/uuid"
	"strings"
)

type Facility struct {
	ID   uuid.UUID `json:"id"`
	Name string    `json:"name"`
}
type UpdateDTO struct {
	Name string `json:"name" validate:"required,min=1,max=200"`
}
type Service struct{ Repo *users.Repository }

func permitted(u users.User) bool {
	return u.Active && (u.Role == "admin" || u.Role == "nurse" || u.Role == "queue_operator")
}
func (s *Service) Get(ctx context.Context, u users.User) (Facility, error) {
	if !permitted(u) {
		return Facility{}, platform.Forbidden
	}
	r, e := s.Repo.Q.GetFacility(ctx, u.FacilityID)
	return Facility{r.ID, r.Name}, e
}
func (s *Service) Update(ctx context.Context, u users.User, d UpdateDTO) (Facility, error) {
	if !permitted(u) || u.Role != "admin" {
		return Facility{}, platform.Forbidden
	}
	name := strings.TrimSpace(d.Name)
	if name == "" || len([]rune(name)) > 200 {
		return Facility{}, platform.Invalid
	}
	var out Facility
	e := s.Repo.Transaction(ctx, func(q *database.Queries) error {
		r, e := q.UpdateFacilityName(ctx, database.UpdateFacilityNameParams{ID: u.FacilityID, Name: name})
		if e != nil {
			return e
		}
		out = Facility{r.ID, r.Name}
		return users.Audit(ctx, q, u, u.ID, "facility.updated")
	})
	return out, e
}
