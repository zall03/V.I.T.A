package users

import (
	"backend/internal/database"
	"github.com/google/uuid"
)

type User struct {
	ID              uuid.UUID `json:"id"`
	FacilityID      uuid.UUID `json:"facility_id"`
	Email           string    `json:"email"`
	Name            string    `json:"name"`
	Role            string    `json:"role"`
	Active          bool      `json:"active"`
	PractitionerIHS *string   `json:"practitioner_ihs"`
	PasswordHash    string    `json:"-"`
	Version         int64     `json:"-"`
}

func FromRow(r database.UserByIDRow) User {
	u := User{ID: r.ID, FacilityID: r.FacilityID, Email: r.Email, Name: r.Name, Role: r.Role, Active: r.Active, PasswordHash: r.PasswordHash, Version: r.TokenVersion}
	if r.PractitionerIhs.Valid {
		u.PractitionerIHS = &r.PractitionerIhs.String
	}
	return u
}
func CanManage(actor User) bool    { return actor.Active && actor.Role == "admin" }
func AllowedRole(role string) bool { return role == "nurse" || role == "queue_operator" }
