package ai

import (
	"bytes"
	"encoding/json"
	"errors"
	"github.com/google/uuid"
	"io"
	"math"
	"time"
)

type Finding struct {
	Text   string  `json:"text"`
	Status string  `json:"status"`
	Timing *string `json:"timing"`
	Source string  `json:"source"`
}
type Allergy struct {
	Status string    `json:"status"`
	Items  []Finding `json:"items"`
}
type Measurement struct {
	Value        *float64   `json:"value"`
	Unit         string     `json:"unit"`
	Availability string     `json:"availability"`
	ObservedAt   *time.Time `json:"observed_at"`
	Timing       *string    `json:"timing"`
	Source       string     `json:"source"`
}
type Vitals struct {
	SystolicBP      *Measurement `json:"systolic_bp"`
	DiastolicBP     *Measurement `json:"diastolic_bp"`
	HeartRate       *Measurement `json:"heart_rate"`
	RespiratoryRate *Measurement `json:"respiratory_rate"`
	Temperature     *Measurement `json:"temperature"`
	SPO2            *Measurement `json:"spo2"`
}

func (v Vitals) All() map[string]*Measurement {
	return map[string]*Measurement{"systolic_bp": v.SystolicBP, "diastolic_bp": v.DiastolicBP, "heart_rate": v.HeartRate, "respiratory_rate": v.RespiratoryRate, "temperature": v.Temperature, "spo2": v.SPO2}
}

type Clinical struct {
	ChiefComplaint *string   `json:"chief_complaint"`
	History        *string   `json:"history_of_present_illness"`
	Symptoms       []Finding `json:"symptoms"`
	MedicalHistory []Finding `json:"medical_history"`
	Allergies      Allergy   `json:"allergies"`
	Medications    []Finding `json:"medications"`
	Vitals         Vitals    `json:"vital_signs"`
}
type Evidence struct {
	Path   string `json:"path"`
	Text   string `json:"text"`
	Status string `json:"status"`
}
type Result struct {
	RequestID            uuid.UUID  `json:"request_id"`
	Status               string     `json:"status"`
	SchemaVersion        string     `json:"schema_version"`
	PromptVersion        string     `json:"prompt_version"`
	Provider             string     `json:"provider"`
	Model                string     `json:"model_name"`
	Data                 Clinical   `json:"data"`
	Evidence             []Evidence `json:"evidence"`
	MissingFields        []string   `json:"missing_fields"`
	Warnings             []string   `json:"warnings"`
	RequiresVerification bool       `json:"requires_verification"`
}
type Request struct {
	RequestID     uuid.UUID `json:"request_id"`
	EncounterID   uuid.UUID `json:"encounter_id"`
	Language      string    `json:"language"`
	SchemaVersion string    `json:"schema_version"`
	Transcript    string    `json:"transcript"`
}

func Decode(raw []byte, v any) error {
	d := json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if e := d.Decode(v); e != nil {
		return e
	}
	if d.Decode(new(any)) != io.EOF {
		return errors.New("trailing_json")
	}
	return nil
}
func (c Clinical) Validate() error {
	fail := errors.New("invalid_clinical_schema")
	if c.Allergies.Status != "unknown" && c.Allergies.Status != "present" && c.Allergies.Status != "absent" && c.Allergies.Status != "uncertain" {
		return fail
	}
	if c.Symptoms == nil || c.MedicalHistory == nil || c.Medications == nil || c.Allergies.Items == nil {
		return fail
	}
	for _, items := range [][]Finding{c.Symptoms, c.MedicalHistory, c.Medications, c.Allergies.Items} {
		if len(items) > 100 {
			return fail
		}
		for _, f := range items {
			if f.Text == "" || len(f.Text) > 2000 {
				return fail
			}
			switch f.Status {
			case "present", "absent", "uncertain", "conflicting":
			default:
				return fail
			}
			switch f.Source {
			case "patient_report", "observation", "history", "unknown":
			default:
				return fail
			}
		}
	}
	units := map[string]string{"systolic_bp": "mmHg", "diastolic_bp": "mmHg", "heart_rate": "beats/min", "respiratory_rate": "breaths/min", "temperature": "Cel", "spo2": "%"}
	for code, m := range c.Vitals.All() {
		if m == nil {
			continue
		}
		if m.Unit != units[code] {
			return fail
		}
		switch m.Availability {
		case "measured":
			if m.Value == nil {
				return fail
			}
		case "missing", "unmeasured", "not_applicable", "ambiguous":
			if m.Value != nil {
				return fail
			}
		default:
			return fail
		}
		if m.Value != nil && (math.IsNaN(*m.Value) || math.IsInf(*m.Value, 0)) {
			return fail
		}
		switch m.Source {
		case "patient_report", "observation", "history", "unknown":
		default:
			return fail
		}
	}
	return nil
}
