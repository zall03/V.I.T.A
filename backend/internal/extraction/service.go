package extraction

import (
	"backend/internal/audit"
	"backend/internal/database"
	"backend/internal/encounter"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"encoding/json"
	"errors"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type DTO struct {
	RequestID       uuid.UUID `json:"request_id" validate:"required"`
	TranscriptionID uuid.UUID `json:"transcription_id" validate:"required"`
}
type Service struct{ Repo *encounter.Repository }

func View(r database.AiExtraction) map[string]any {
	var data any
	if len(r.ExtractedData) > 0 {
		data = json.RawMessage(r.ExtractedData)
	}
	return map[string]any{"id": r.ID, "encounter_id": r.EncounterID, "transcription_id": r.TranscriptionID, "request_id": r.RequestID, "status": r.Status, "data": data, "error_code": r.ErrorCode, "attempts": r.Attempts, "created_at": r.CreatedAt, "completed_at": r.CompletedAt}
}
func (s *Service) Create(ctx context.Context, u users.User, id uuid.UUID, d DTO) (map[string]any, error) {
	var r database.AiExtraction
	e := s.Repo.Tx(ctx, func(q *database.Queries) error {
		en, e := encounter.Access(ctx, q, u, id, true)
		if e != nil {
			return e
		}
		old, e := q.GetExtractionByRequest(ctx, database.GetExtractionByRequestParams{EncounterID: id, RequestID: d.RequestID})
		if e == nil {
			if old.TranscriptionID != d.TranscriptionID {
				return platform.Conflict
			}
			r = old
			return nil
		}
		if !errors.Is(e, pgx.ErrNoRows) {
			return e
		}
		if en.Status != "in_progress" {
			return platform.Conflict
		}
		if _, e = q.GetTranscription(ctx, database.GetTranscriptionParams{ID: d.TranscriptionID, EncounterID: id}); e != nil {
			return e
		}
		r, e = q.CreateExtraction(ctx, database.CreateExtractionParams{EncounterID: id, TranscriptionID: d.TranscriptionID, RequestID: d.RequestID, CreatedBy: u.ID, BaseAssessmentID: en.CurrentAssessmentID})
		if e != nil {
			return e
		}
		return audit.Write(ctx, q, u, "extraction.queued", en.PatientID, id, uuid.Nil)
	})
	return View(r), e
}
func (s *Service) Get(ctx context.Context, u users.User, id, x uuid.UUID) (map[string]any, error) {
	if _, e := encounter.Access(ctx, s.Repo.Q, u, id, false); e != nil {
		return nil, e
	}
	r, e := s.Repo.Q.GetExtraction(ctx, database.GetExtractionParams{ID: x, EncounterID: id})
	return View(r), e
}
func (s *Service) List(ctx context.Context, u users.User, id uuid.UUID, l, o int32) ([]map[string]any, error) {
	if _, e := encounter.Access(ctx, s.Repo.Q, u, id, false); e != nil {
		return nil, e
	}
	rows, e := s.Repo.Q.ListExtractions(ctx, database.ListExtractionsParams{EncounterID: id, Limit: l, Offset: o})
	out := make([]map[string]any, 0, len(rows))
	for _, r := range rows {
		out = append(out, View(r))
	}
	return out, e
}
