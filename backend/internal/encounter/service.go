package encounter

import (
	"backend/internal/audit"
	"backend/internal/database"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"strings"
)

type Service struct{ Repo *Repository }

func (s *Service) Get(ctx context.Context, u users.User, id uuid.UUID) (Encounter, error) {
	r, e := Access(ctx, s.Repo.Q, u, id, false)
	return View(r), e
}
func (s *Service) List(ctx context.Context, u users.User, patient uuid.UUID, l, o int32) ([]Encounter, error) {
	if !u.Active || u.Role != "nurse" {
		return nil, platform.Forbidden
	}
	if patient != uuid.Nil {
		if _, e := s.Repo.Q.GetPatient(ctx, database.GetPatientParams{ID: patient, FacilityID: u.FacilityID}); e != nil {
			return nil, e
		}
	}
	rows, e := s.Repo.Q.ListEncounters(ctx, database.ListEncountersParams{FacilityID: u.FacilityID, NurseID: u.ID, PatientID: audit.ID(patient), Limit: l, Offset: o})
	out := make([]Encounter, 0, len(rows))
	for _, r := range rows {
		out = append(out, View(r))
	}
	return out, e
}
func (s *Service) Create(ctx context.Context, u users.User, d CreateDTO) (Encounter, error) {
	if !u.Active || u.Role != "nurse" {
		return Encounter{}, platform.Forbidden
	}
	var r database.Encounter
	e := s.Repo.Tx(ctx, func(q *database.Queries) error {
		if _, e := q.GetPatient(ctx, database.GetPatientParams{ID: d.PatientID, FacilityID: u.FacilityID}); e != nil {
			return e
		}
		var e error
		r, e = q.CreateEncounter(ctx, database.CreateEncounterParams{FacilityID: u.FacilityID, PatientID: d.PatientID, NurseID: u.ID, EncounterNumber: uuid.NewString()})
		if e != nil {
			return e
		}
		if e = q.InsertHistory(ctx, database.InsertHistoryParams{EncounterID: r.ID, ToStatus: "draft", ActorID: u.ID, EventType: "encounter"}); e != nil {
			return e
		}
		return audit.Write(ctx, q, u, "encounter.created", d.PatientID, r.ID, uuid.Nil)
	})
	return View(r), e
}
func (s *Service) Transition(ctx context.Context, u users.User, id uuid.UUID, to string, d TransitionDTO) (Encounter, error) {
	var out database.Encounter
	e := s.Repo.Tx(ctx, func(q *database.Queries) error {
		r, e := Access(ctx, q, u, id, true)
		if e != nil {
			return e
		}
		if r.Version != d.Version || !CanTransition(r.Status, to) {
			return platform.Conflict
		}
		if to == "cancelled" && (d.Reason == nil || strings.TrimSpace(*d.Reason) == "") {
			return platform.Invalid
		}
		out, e = q.TransitionEncounter(ctx, database.TransitionEncounterParams{ID: id, Status: to, CancellationReason: users.Text(d.Reason), Version: d.Version})
		if e != nil {
			return e
		}
		if e = q.InsertHistory(ctx, database.InsertHistoryParams{EncounterID: id, FromStatus: pgtype.Text{String: r.Status, Valid: true}, ToStatus: to, ActorID: u.ID, EventType: "encounter", Reason: users.Text(d.Reason)}); e != nil {
			return e
		}
		return audit.Write(ctx, q, u, "encounter."+to, r.PatientID, id, uuid.Nil)
	})
	return View(out), e
}
func (s *Service) History(ctx context.Context, u users.User, id uuid.UUID) ([]map[string]any, error) {
	if _, e := Access(ctx, s.Repo.Q, u, id, false); e != nil {
		return nil, e
	}
	rows, e := s.Repo.Q.ListHistory(ctx, id)
	out := make([]map[string]any, 0, len(rows))
	for _, r := range rows {
		out = append(out, map[string]any{"id": r.ID, "event_type": r.EventType, "from_status": r.FromStatus, "to_status": r.ToStatus, "actor_id": r.ActorID, "reason": r.Reason, "created_at": r.CreatedAt})
	}
	return out, e
}
