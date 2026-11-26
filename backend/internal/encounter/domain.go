package encounter

import (
	"backend/internal/database"
	"github.com/google/uuid"
)

type Encounter struct {
	ID                  uuid.UUID `json:"id"`
	PatientID           uuid.UUID `json:"patient_id"`
	NurseID             uuid.UUID `json:"nurse_id"`
	Number              string    `json:"encounter_number"`
	Status              string    `json:"status"`
	Version             int64     `json:"version"`
	CurrentAssessmentID any       `json:"current_assessment_id"`
}

func View(r database.Encounter) Encounter {
	v := Encounter{ID: r.ID, PatientID: r.PatientID, NurseID: r.NurseID, Number: r.EncounterNumber, Status: r.Status, Version: r.Version}
	if r.CurrentAssessmentID.Valid {
		v.CurrentAssessmentID = uuid.UUID(r.CurrentAssessmentID.Bytes)
	}
	return v
}
func CanTransition(from, to string) bool {
	switch to {
	case "in_progress":
		return from == "draft"
	case "cancelled":
		return from == "draft" || from == "in_progress" || from == "ready_for_triage"
	case "ready_for_triage":
		return from == "in_progress"
	}
	return false
}

type CreateDTO struct {
	PatientID uuid.UUID `json:"patient_id" validate:"required"`
}
type TransitionDTO struct {
	Version int64   `json:"version" validate:"required,min=1"`
	Reason  *string `json:"reason" validate:"omitempty,min=1,max=500"`
}
