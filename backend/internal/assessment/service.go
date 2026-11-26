package assessment

import (
	"backend/internal/audit"
	"backend/internal/database"
	"backend/internal/encounter"
	"backend/internal/integration/ai"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"encoding/json"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"strconv"
)

type DTO struct {
	Version            int64       `json:"version" validate:"required,min=1"`
	SourceExtractionID *uuid.UUID  `json:"source_extraction_id"`
	Data               ai.Clinical `json:"data"`
}
type VerifyDTO struct {
	Version      int64     `json:"version" validate:"required,min=1"`
	AssessmentID uuid.UUID `json:"assessment_id" validate:"required"`
}
type Service struct{ Repo *encounter.Repository }

func View(r database.ClinicalAssessment) map[string]any {
	return map[string]any{"id": r.ID, "encounter_id": r.EncounterID, "revision_number": r.RevisionNumber, "source_extraction_id": r.SourceExtractionID, "assessment_status": r.AssessmentStatus, "data": json.RawMessage(r.ClinicalData), "created_by": r.CreatedBy, "verified_by": r.VerifiedBy, "verified_at": r.VerifiedAt, "created_at": r.CreatedAt}
}

// Append requires the encounter row lock. Verified payloads are never modified.
func Append(ctx context.Context, q *database.Queries, u users.User, en database.Encounter, data ai.Clinical, source uuid.UUID, status string) (database.ClinicalAssessment, error) {
	if e := data.Validate(); e != nil {
		return database.ClinicalAssessment{}, platform.Invalid
	}
	raw, e := json.Marshal(data)
	if e != nil {
		return database.ClinicalAssessment{}, e
	}
	history, _ := json.Marshal(data.MedicalHistory)
	allergies, _ := json.Marshal(data.Allergies)
	meds, _ := json.Marshal(data.Medications)
	r, e := q.CreateAssessment(ctx, database.CreateAssessmentParams{EncounterID: en.ID, SourceExtractionID: audit.ID(source), ChiefComplaint: users.Text(data.ChiefComplaint), HistoryOfPresentIllness: users.Text(data.History), RelevantMedicalHistory: history, Allergies: allergies, Medications: meds, AssessmentStatus: status, ClinicalData: raw, CreatedBy: u.ID})
	if e != nil {
		return r, e
	}
	for code, m := range data.Vitals.All() {
		if m == nil {
			continue
		}
		var n pgtype.Numeric
		if m.Value != nil {
			if e = n.Scan(strconv.FormatFloat(*m.Value, 'f', -1, 64)); e != nil {
				return r, e
			}
		}
		var at pgtype.Timestamptz
		if m.ObservedAt != nil {
			at = pgtype.Timestamptz{Time: *m.ObservedAt, Valid: true}
		}
		if e = q.InsertVital(ctx, database.InsertVitalParams{AssessmentID: r.ID, MeasurementCode: code, NumericValue: n, MeasurementUnit: m.Unit, Availability: m.Availability, MeasurementTime: at, TimingText: users.Text(m.Timing), Source: m.Source}); e != nil {
			return r, e
		}
	}
	if e = q.SetCurrentAssessment(ctx, database.SetCurrentAssessmentParams{ID: en.ID, CurrentAssessmentID: audit.ID(r.ID)}); e != nil {
		return r, e
	}
	if e = q.InsertHistory(ctx, database.InsertHistoryParams{EncounterID: en.ID, AssessmentID: audit.ID(r.ID), ToStatus: status, ActorID: u.ID, EventType: "assessment"}); e != nil {
		return r, e
	}
	if en.Status == "ready_for_triage" {
		if e = q.InsertHistory(ctx, database.InsertHistoryParams{EncounterID: en.ID, FromStatus: pgtype.Text{String: en.Status, Valid: true}, ToStatus: "in_progress", ActorID: u.ID, EventType: "encounter"}); e != nil {
			return r, e
		}
	}
	return r, audit.Write(ctx, q, u, "assessment.revision_created", en.PatientID, en.ID, r.ID)
}
func (s *Service) Save(ctx context.Context, u users.User, id uuid.UUID, d DTO, create bool) (map[string]any, error) {
	var r database.ClinicalAssessment
	e := s.Repo.Tx(ctx, func(q *database.Queries) error {
		en, e := encounter.Access(ctx, q, u, id, true)
		if e != nil {
			return e
		}
		if en.Version != d.Version || (en.Status != "in_progress" && en.Status != "ready_for_triage") || create == en.CurrentAssessmentID.Valid {
			return platform.Conflict
		}
		source := uuid.Nil
		if d.SourceExtractionID != nil {
			source = *d.SourceExtractionID
			x, e := q.GetExtraction(ctx, database.GetExtractionParams{ID: source, EncounterID: id})
			if e != nil {
				return e
			}
			if x.Status != "succeeded" {
				return platform.Conflict
			}
		}
		r, e = Append(ctx, q, u, en, d.Data, source, "draft")
		return e
	})
	return View(r), e
}
func (s *Service) Current(ctx context.Context, u users.User, id uuid.UUID) (map[string]any, error) {
	en, e := encounter.Access(ctx, s.Repo.Q, u, id, false)
	if e != nil {
		return nil, e
	}
	if !en.CurrentAssessmentID.Valid {
		return nil, platform.NotFound
	}
	r, e := s.Repo.Q.GetAssessment(ctx, database.GetAssessmentParams{ID: uuid.UUID(en.CurrentAssessmentID.Bytes), EncounterID: id})
	v := View(r)
	v["encounter_version"] = en.Version
	return v, e
}
func (s *Service) History(ctx context.Context, u users.User, id uuid.UUID, l, o int32) ([]map[string]any, error) {
	if _, e := encounter.Access(ctx, s.Repo.Q, u, id, false); e != nil {
		return nil, e
	}
	rows, e := s.Repo.Q.ListAssessments(ctx, database.ListAssessmentsParams{EncounterID: id, Limit: l, Offset: o})
	out := make([]map[string]any, 0, len(rows))
	for _, r := range rows {
		out = append(out, View(r))
	}
	return out, e
}
func (s *Service) Verify(ctx context.Context, u users.User, id uuid.UUID, d VerifyDTO) (map[string]any, error) {
	var r database.ClinicalAssessment
	e := s.Repo.Tx(ctx, func(q *database.Queries) error {
		en, e := encounter.Access(ctx, q, u, id, true)
		if e != nil {
			return e
		}
		if en.Version != d.Version || en.Status != "in_progress" || !en.CurrentAssessmentID.Valid || uuid.UUID(en.CurrentAssessmentID.Bytes) != d.AssessmentID {
			return platform.Conflict
		}
		old, e := q.GetAssessment(ctx, database.GetAssessmentParams{ID: d.AssessmentID, EncounterID: id})
		if e != nil {
			return e
		}
		if old.AssessmentStatus != "draft" && old.AssessmentStatus != "pending_review" {
			return platform.Conflict
		}
		r, e = q.VerifyAssessment(ctx, database.VerifyAssessmentParams{ID: d.AssessmentID, EncounterID: id, VerifiedBy: audit.ID(u.ID)})
		if e != nil {
			return e
		}
		if _, e = q.TransitionEncounter(ctx, database.TransitionEncounterParams{ID: id, Status: "ready_for_triage", Version: d.Version}); e != nil {
			return e
		}
		if e = q.InsertHistory(ctx, database.InsertHistoryParams{EncounterID: id, AssessmentID: audit.ID(r.ID), FromStatus: pgtype.Text{String: old.AssessmentStatus, Valid: true}, ToStatus: "verified", ActorID: u.ID, EventType: "assessment"}); e != nil {
			return e
		}
		if e = q.InsertHistory(ctx, database.InsertHistoryParams{EncounterID: id, FromStatus: pgtype.Text{String: en.Status, Valid: true}, ToStatus: "ready_for_triage", ActorID: u.ID, EventType: "encounter"}); e != nil {
			return e
		}
		return audit.Write(ctx, q, u, "assessment.verified", en.PatientID, id, r.ID)
	})
	return View(r), e
}
