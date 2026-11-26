package patient

import (
	"backend/internal/database"
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"time"
)

type Patient struct {
	ID                  uuid.UUID `json:"id"`
	FacilityID          uuid.UUID `json:"facility_id"`
	MedicalRecordNumber string    `json:"medical_record_number"`
	FullName            *string   `json:"full_name"`
	BirthDate           *string   `json:"birth_date"`
	Sex                 string    `json:"sex"`
	IdentityStatus      string    `json:"identity_status"`
	Version             int64     `json:"version"`
}

func View(r database.Patient) Patient {
	p := Patient{ID: r.ID, FacilityID: r.FacilityID, MedicalRecordNumber: r.MedicalRecordNumber, Sex: r.Sex, IdentityStatus: r.IdentityStatus, Version: r.Version}
	if r.FullName.Valid {
		p.FullName = &r.FullName.String
	}
	if r.BirthDate.Valid {
		v := r.BirthDate.Time.Format("2006-01-02")
		p.BirthDate = &v
	}
	return p
}
func Nurse(c *gin.Context) {
	u := users.Current(c)
	if !u.Active || u.Role != "nurse" {
		platform.Fail(c, platform.Forbidden)
		return
	}
	c.Next()
}
func Age(birth, at time.Time) int {
	years := at.Year() - birth.Year()
	if at.Month() < birth.Month() || (at.Month() == birth.Month() && at.Day() < birth.Day()) {
		years--
	}
	return years
}
