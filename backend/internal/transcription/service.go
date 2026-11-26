package transcription

import (
	"backend/internal/audit"
	"backend/internal/database"
	"backend/internal/encounter"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"errors"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"strings"
)

type DTO struct {
	ClientReferenceID uuid.UUID `json:"client_reference_id" validate:"required"`
	Transcript        string    `json:"transcript" validate:"required,max=8000"`
	Language          string    `json:"language" validate:"required,oneof=id-ID en-US"`
	Source            string    `json:"source" validate:"required,oneof=on_device_stt manual_text"`
}
type Transcription struct {
	ID                uuid.UUID `json:"id"`
	EncounterID       uuid.UUID `json:"encounter_id"`
	ClientReferenceID uuid.UUID `json:"client_reference_id"`
	Transcript        string    `json:"transcript"`
	Language          string    `json:"language"`
	Source            string    `json:"source"`
}

func View(r database.Transcription) Transcription {
	return Transcription{r.ID, r.EncounterID, r.ClientReferenceID, r.Transcript, r.Language, r.Source}
}

type Service struct{ Repo *encounter.Repository }

func (s *Service) Create(ctx context.Context, u users.User, id uuid.UUID, d DTO) (Transcription, error) {
	var out database.Transcription
	if strings.TrimSpace(d.Transcript) == "" {
		return View(out), platform.Invalid
	}
	e := s.Repo.Tx(ctx, func(q *database.Queries) error {
		r, e := encounter.Access(ctx, q, u, id, true)
		if e != nil {
			return e
		}
		old, e := q.GetTranscriptionByReference(ctx, database.GetTranscriptionByReferenceParams{EncounterID: id, ClientReferenceID: d.ClientReferenceID})
		if e == nil {
			if old.Transcript != d.Transcript || old.Language != d.Language || old.Source != d.Source {
				return platform.Conflict
			}
			out = old
			return nil
		}
		if !errors.Is(e, pgx.ErrNoRows) {
			return e
		}
		if r.Status != "in_progress" {
			return platform.Conflict
		}
		out, e = q.CreateTranscription(ctx, database.CreateTranscriptionParams{EncounterID: id, Transcript: d.Transcript, Language: d.Language, Source: d.Source, ClientReferenceID: d.ClientReferenceID, CreatedBy: u.ID})
		if e != nil {
			return e
		}
		return audit.Write(ctx, q, u, "transcription.created", r.PatientID, id, uuid.Nil)
	})
	return View(out), e
}
func (s *Service) List(ctx context.Context, u users.User, id uuid.UUID, l, o int32) ([]Transcription, error) {
	if _, e := encounter.Access(ctx, s.Repo.Q, u, id, false); e != nil {
		return nil, e
	}
	rows, e := s.Repo.Q.ListTranscriptions(ctx, database.ListTranscriptionsParams{EncounterID: id, Limit: l, Offset: o})
	out := make([]Transcription, 0, len(rows))
	for _, r := range rows {
		out = append(out, View(r))
	}
	return out, e
}
