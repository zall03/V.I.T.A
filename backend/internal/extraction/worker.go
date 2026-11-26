package extraction

import (
	"backend/internal/assessment"
	"backend/internal/audit"
	"backend/internal/database"
	"backend/internal/encounter"
	"backend/internal/integration/ai"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"encoding/json"
	"errors"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"log/slog"
	"time"
)

type Worker struct {
	Repo    *encounter.Repository
	Gateway ai.Gateway
	Log     *slog.Logger
}

func (w *Worker) Run(ctx context.Context) error {
	timer := time.NewTicker(time.Second)
	defer timer.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-timer.C:
			if e := w.Once(ctx); e != nil && !errors.Is(e, pgx.ErrNoRows) && !errors.Is(e, context.Canceled) {
				w.Log.Error("extraction_worker_operation_failed")
			}
		}
	}
}
func (w *Worker) Once(ctx context.Context) error {
	if e := w.Repo.Q.ExhaustJobs(ctx); e != nil {
		return e
	}
	job, e := w.Repo.Q.ClaimExtraction(ctx, audit.ID(uuid.New()))
	if e != nil {
		return e
	}
	start := time.Now()
	userRow, e := w.Repo.Q.UserByID(ctx, job.CreatedBy)
	if e != nil {
		return w.fail(ctx, job, "actor_unavailable", false)
	}
	u := users.FromRow(userRow)
	en, e := encounter.Access(ctx, w.Repo.Q, u, job.EncounterID, false)
	if e != nil || en.Status == "cancelled" {
		return w.fail(ctx, job, "encounter_unavailable", false)
	}
	tr, e := w.Repo.Q.GetTranscription(ctx, database.GetTranscriptionParams{ID: job.TranscriptionID, EncounterID: job.EncounterID})
	if e != nil {
		return w.fail(ctx, job, "transcription_unavailable", false)
	}
	patient, e := w.Repo.Q.GetPatient(ctx, database.GetPatientParams{ID: en.PatientID, FacilityID: en.FacilityID})
	if e != nil {
		return w.fail(ctx, job, "patient_unavailable", false)
	}
	text := ai.Minimize(tr.Transcript, patient.FullName.String, patient.MedicalRecordNumber, patient.PatientIhsNumber.String)
	call, cancel := context.WithTimeout(ctx, 75*time.Second)
	result, e := w.Gateway.Extract(call, ai.Request{RequestID: job.RequestID, EncounterID: en.ID, Language: tr.Language, SchemaVersion: job.SchemaVersion, Transcript: text})
	cancel()
	if e != nil {
		var f *ai.Failure
		if errors.As(e, &f) {
			return w.fail(ctx, job, f.Code, f.Retryable)
		}
		return w.fail(ctx, job, "ai_failed", false)
	}
	if e = result.Data.Validate(); e != nil {
		return w.fail(ctx, job, "invalid_ai_response", false)
	}
	raw, e := json.Marshal(result)
	if e != nil {
		return e
	}
	warnings, _ := json.Marshal(result.Warnings)
	return w.Repo.Tx(ctx, func(q *database.Queries) error {
		en, e := encounter.Access(ctx, q, u, job.EncounterID, true)
		if e != nil {
			return e
		}
		if _, e = q.LockClaim(ctx, database.LockClaimParams{ID: job.ID, ClaimID: job.ClaimID}); e != nil {
			return e
		}
		if en.Status == "cancelled" {
			_, e = q.FailExtraction(ctx, database.FailExtractionParams{ID: job.ID, ClaimID: job.ClaimID, Status: "failed", ErrorCode: pgtype.Text{String: "encounter_cancelled", Valid: true}})
			return e
		}
		n, e := q.FinishExtraction(ctx, database.FinishExtractionParams{ID: job.ID, ClaimID: job.ClaimID, ExtractedData: raw, Warnings: warnings, Provider: pgtype.Text{String: result.Provider, Valid: true}, ModelName: pgtype.Text{String: result.Model, Valid: true}, ProcessingDurationMs: pgtype.Int8{Int64: time.Since(start).Milliseconds(), Valid: true}})
		if e != nil {
			return e
		}
		if n != 1 {
			return platform.Conflict
		}
		if !job.BaseAssessmentID.Valid && !en.CurrentAssessmentID.Valid && en.Status == "in_progress" {
			if _, e = assessment.Append(ctx, q, u, en, result.Data, job.ID, "pending_review"); e != nil {
				return e
			}
		}
		return audit.Write(ctx, q, u, "extraction.succeeded", en.PatientID, en.ID, uuid.Nil)
	})
}
func (w *Worker) fail(ctx context.Context, j database.AiExtraction, code string, retry bool) error {
	status := "failed"
	if retry && j.Attempts < 3 {
		status = "pending"
	}
	_, e := w.Repo.Q.FailExtraction(ctx, database.FailExtractionParams{ID: j.ID, ClaimID: j.ClaimID, Status: status, ErrorCode: pgtype.Text{String: code, Valid: true}})
	return e
}
