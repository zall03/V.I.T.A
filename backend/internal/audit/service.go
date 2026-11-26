package audit

import (
	"backend/internal/database"
	"backend/internal/users"
	"context"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

func ID(id uuid.UUID) pgtype.UUID { return pgtype.UUID{Bytes: id, Valid: id != uuid.Nil} }
func Write(ctx context.Context, q *database.Queries, u users.User, action string, patient, encounter, assessment uuid.UUID) error {
	return q.ClinicalAudit(ctx, database.ClinicalAuditParams{FacilityID: u.FacilityID, ActorID: u.ID, Action: action, PatientID: ID(patient), EncounterID: ID(encounter), AssessmentID: ID(assessment)})
}
