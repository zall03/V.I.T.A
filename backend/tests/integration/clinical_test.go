//go:build integration

package integration

import (
	"backend/internal/assessment"
	"backend/internal/database"
	"backend/internal/encounter"
	"backend/internal/extraction"
	"backend/internal/integration/ai"
	"backend/internal/patient"
	"backend/internal/platform"
	"backend/internal/transcription"
	"backend/internal/users"
	"context"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"github.com/stretchr/testify/require"
	"io"
	"log/slog"
	"os"
	"sync"
	"testing"
)

func TestClinicalWorkflow(t *testing.T) {
	url := os.Getenv("TEST_DATABASE_URL")
	require.NotEmpty(t, url, "TEST_DATABASE_URL required")
	ctx := context.Background()
	base, e := pgxpool.New(ctx, url)
	require.NoError(t, e)
	defer base.Close()
	schema := "clinical_" + uuid.NewString()[:8]
	_, e = base.Exec(ctx, "CREATE SCHEMA "+schema)
	require.NoError(t, e)
	defer func() { _, _ = base.Exec(ctx, "DROP SCHEMA "+schema+" CASCADE") }()
	cfg, e := pgxpool.ParseConfig(url)
	require.NoError(t, e)
	cfg.ConnConfig.RuntimeParams["search_path"] = schema
	p, e := pgxpool.NewWithConfig(ctx, cfg)
	require.NoError(t, e)
	defer p.Close()
	db := stdlib.OpenDB(*cfg.ConnConfig)
	defer db.Close()
	require.NoError(t, goose.SetDialect("postgres"))
	require.NoError(t, goose.Up(db, "../../db/migrations"))
	q := database.New(p)
	facility, e := q.CreateFacility(ctx, "Synthetic Clinical Facility")
	require.NoError(t, e)
	id, e := q.CreateUser(ctx, database.CreateUserParams{FacilityID: facility, Role: "nurse", Email: "nurse@example.test", Name: "Synthetic Nurse", PasswordHash: "unused-test-hash"})
	require.NoError(t, e)
	u := users.User{ID: id, FacilityID: facility, Role: "nurse", Active: true}
	ps := patient.Service{Repo: patient.NewRepository(p)}
	er := encounter.NewRepository(p)
	es := encounter.Service{Repo: er}
	ts := transcription.Service{Repo: er}
	xs := extraction.Service{Repo: er}
	as := assessment.Service{Repo: er}
	pat, e := ps.Create(ctx, u, patient.CreateDTO{Demographics: patient.Demographics{IdentityStatus: "temporary", Sex: "unknown"}})
	require.NoError(t, e)
	require.Nil(t, pat.BirthDate)
	foreign := u
	foreign.FacilityID = uuid.New()
	_, e = ps.Get(ctx, foreign, pat.ID)
	require.Error(t, e)
	en, e := es.Create(ctx, u, encounter.CreateDTO{PatientID: pat.ID})
	require.NoError(t, e)
	en, e = es.Transition(ctx, u, en.ID, "in_progress", encounter.TransitionDTO{Version: en.Version})
	require.NoError(t, e)
	d := transcription.DTO{ClientReferenceID: uuid.New(), Transcript: "Synthetic unknown clinical information", Language: "id-ID", Source: "manual_text"}
	tr, e := ts.Create(ctx, u, en.ID, d)
	require.NoError(t, e)
	tr2, e := ts.Create(ctx, u, en.ID, d)
	require.NoError(t, e)
	require.Equal(t, tr.ID, tr2.ID)
	d.Transcript = "different"
	_, e = ts.Create(ctx, u, en.ID, d)
	require.ErrorIs(t, e, platform.Conflict)
	other, e := es.Create(ctx, u, encounter.CreateDTO{PatientID: pat.ID})
	require.NoError(t, e)
	other, e = es.Transition(ctx, u, other.ID, "in_progress", encounter.TransitionDTO{Version: other.Version})
	require.NoError(t, e)
	_, e = xs.Create(ctx, u, other.ID, extraction.DTO{RequestID: uuid.New(), TranscriptionID: tr.ID})
	require.Error(t, e)
	job, e := xs.Create(ctx, u, en.ID, extraction.DTO{RequestID: uuid.New(), TranscriptionID: tr.ID})
	require.NoError(t, e)
	jobID := job["id"].(uuid.UUID)
	data := ai.Clinical{Symptoms: []ai.Finding{}, MedicalHistory: []ai.Finding{}, Medications: []ai.Finding{}, Allergies: ai.Allergy{Status: "unknown", Items: []ai.Finding{}}}
	worker := extraction.Worker{Repo: er, Gateway: ai.MockGateway{Result: ai.Result{Status: "success", SchemaVersion: "1.0", PromptVersion: "clinical_extraction_v1", Provider: "mock", Model: "synthetic", RequiresVerification: true, Data: data}}, Log: slog.New(slog.NewJSONHandler(io.Discard, nil))}
	// Simulate crashed claim, then recover it using a fresh fencing token.
	_, e = p.Exec(ctx, "UPDATE ai_extractions SET status='processing',attempts=1,lease_until=now()-interval '1 second',claim_id=$2 WHERE id=$1", jobID, uuid.New())
	require.NoError(t, e)
	require.NoError(t, worker.Once(ctx))
	stored, e := q.GetExtraction(ctx, database.GetExtractionParams{ID: jobID, EncounterID: en.ID})
	require.NoError(t, e)
	require.Equal(t, "succeeded", stored.Status)
	require.Equal(t, int32(2), stored.Attempts)
	current, e := as.Current(ctx, u, en.ID)
	require.NoError(t, e)
	version := current["encounter_version"].(int64)
	assessmentID := current["id"].(uuid.UUID)
	_, e = as.Verify(ctx, u, en.ID, assessment.VerifyDTO{Version: version, AssessmentID: assessmentID})
	require.NoError(t, e)
	en, e = es.Get(ctx, u, en.ID)
	require.NoError(t, e)
	require.Equal(t, "ready_for_triage", en.Status)
	// Exactly one concurrent correction may append against the same encounter version.
	results := make(chan error, 2)
	var wg sync.WaitGroup
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := as.Save(ctx, u, en.ID, assessment.DTO{Version: en.Version, Data: data}, false)
			results <- err
		}()
	}
	wg.Wait()
	close(results)
	success, conflict := 0, 0
	for err := range results {
		if err == nil {
			success++
		} else {
			require.ErrorIs(t, err, platform.Conflict)
			conflict++
		}
	}
	require.Equal(t, 1, success)
	require.Equal(t, 1, conflict)
	_, e = as.Verify(ctx, u, en.ID, assessment.VerifyDTO{Version: version, AssessmentID: assessmentID})
	require.ErrorIs(t, e, platform.Conflict)
	old, e := q.GetAssessment(ctx, database.GetAssessmentParams{ID: assessmentID, EncounterID: en.ID})
	require.NoError(t, e)
	require.Equal(t, "verified", old.AssessmentStatus)
	// Manual fallback needs no extraction or AI service.
	_, e = as.Save(ctx, u, other.ID, assessment.DTO{Version: other.Version, Data: data}, true)
	require.NoError(t, e)
	var count int
	require.NoError(t, p.QueryRow(ctx, "SELECT count(*) FROM audit_logs WHERE encounter_id=$1", en.ID).Scan(&count))
	require.Greater(t, count, 4)
	require.NoError(t, goose.DownTo(db, "../../db/migrations", 0))
}
