package patient

import (
	"backend/internal/platform"
	"github.com/jackc/pgx/v5/pgtype"
	"strings"
	"time"
)

type Demographics struct {
	FullName       *string `json:"full_name" validate:"omitempty,min=1,max=150"`
	BirthDate      *string `json:"birth_date" validate:"omitempty,datetime=2006-01-02"`
	Sex            string  `json:"sex" validate:"required,oneof=male female other unknown"`
	IdentityStatus string  `json:"identity_status" validate:"required,oneof=identified temporary"`
	PatientIHS     *string `json:"patient_ihs_number" validate:"omitempty,min=1,max=100"`
}
type CreateDTO struct {
	Demographics
	MedicalRecordNumber string `json:"medical_record_number" validate:"omitempty,max=64"`
}
type UpdateDTO struct {
	Demographics
	Version int64 `json:"version" validate:"required,min=1"`
}

func (d Demographics) Validate() (pgtype.Date, error) {
	var date pgtype.Date
	if d.IdentityStatus == "identified" && (d.FullName == nil || strings.TrimSpace(*d.FullName) == "") {
		return date, platform.Invalid
	}
	if d.BirthDate != nil {
		v, e := time.Parse("2006-01-02", *d.BirthDate)
		if e != nil || v.After(time.Now()) {
			return date, platform.Invalid
		}
		date = pgtype.Date{Time: v, Valid: true}
	}
	return date, nil
}
