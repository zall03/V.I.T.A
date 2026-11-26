package patient

import (
	"backend/internal/audit"
	"backend/internal/database"
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"errors"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"strings"
)

type Service struct{ Repo *Repository }

func (s *Service) Get(ctx context.Context, u users.User, id uuid.UUID) (Patient, error) {
	if u.Role != "nurse" || !u.Active {
		return Patient{}, platform.Forbidden
	}
	r, e := s.Repo.Q.GetPatient(ctx, database.GetPatientParams{ID: id, FacilityID: u.FacilityID})
	return View(r), e
}
func (s *Service) List(ctx context.Context, u users.User, search string, l, o int32) ([]Patient, error) {
	if u.Role != "nurse" || !u.Active {
		return nil, platform.Forbidden
	}
	if len(search) > 150 {
		return nil, platform.Invalid
	}
	rows, e := s.Repo.Q.ListPatients(ctx, database.ListPatientsParams{FacilityID: u.FacilityID, Search: search, Limit: l, Offset: o})
	out := make([]Patient, 0, len(rows))
	for _, r := range rows {
		out = append(out, View(r))
	}
	return out, e
}
func (s *Service) Create(ctx context.Context, u users.User, d CreateDTO) (Patient, error) {
	if u.Role != "nurse" || !u.Active {
		return Patient{}, platform.Forbidden
	}
	date, e := d.Validate()
	if e != nil {
		return Patient{}, e
	}
	mrn := strings.TrimSpace(d.MedicalRecordNumber)
	if mrn == "" {
		if d.IdentityStatus != "temporary" {
			return Patient{}, platform.Invalid
		}
		mrn = "TEMP-" + uuid.NewString()
	}
	var r database.Patient
	e = s.Repo.Tx(ctx, func(q *database.Queries) error {
		var err error
		r, err = q.CreatePatient(ctx, database.CreatePatientParams{FacilityID: u.FacilityID, MedicalRecordNumber: mrn, FullName: users.Text(d.FullName), BirthDate: date, Sex: d.Sex, IdentityStatus: d.IdentityStatus, PatientIhsNumber: users.Text(d.PatientIHS), CreatedBy: u.ID})
		if err != nil {
			return err
		}
		return audit.Write(ctx, q, u, "patient.created", r.ID, uuid.Nil, uuid.Nil)
	})
	return View(r), e
}
func (s *Service) Update(ctx context.Context, u users.User, id uuid.UUID, d UpdateDTO) (Patient, error) {
	if _, e := s.Get(ctx, u, id); e != nil {
		return Patient{}, e
	}
	date, e := d.Validate()
	if e != nil {
		return Patient{}, e
	}
	var r database.Patient
	e = s.Repo.Tx(ctx, func(q *database.Queries) error {
		var err error
		r, err = q.UpdatePatient(ctx, database.UpdatePatientParams{ID: id, FacilityID: u.FacilityID, FullName: users.Text(d.FullName), BirthDate: date, Sex: d.Sex, IdentityStatus: d.IdentityStatus, PatientIhsNumber: users.Text(d.PatientIHS), Version: d.Version})
		if errors.Is(err, pgx.ErrNoRows) {
			return platform.Conflict
		}
		if err != nil {
			return err
		}
		return audit.Write(ctx, q, u, "patient.updated", id, uuid.Nil, uuid.Nil)
	})
	return View(r), e
}
