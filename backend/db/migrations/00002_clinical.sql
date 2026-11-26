-- +goose Up
ALTER TABLE users ADD CONSTRAINT users_id_facility_unique UNIQUE(id,facility_id);
CREATE TABLE patients (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), facility_id uuid NOT NULL REFERENCES facilities(id),
 medical_record_number text NOT NULL, full_name text, birth_date date,
 sex text NOT NULL DEFAULT 'unknown' CHECK(sex IN ('male','female','other','unknown')),
 identity_status text NOT NULL CHECK(identity_status IN ('identified','temporary')),
 patient_ihs_number text, created_by uuid NOT NULL REFERENCES users(id), version bigint NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(facility_id,medical_record_number), UNIQUE(id,facility_id),
 CHECK(identity_status='temporary' OR full_name IS NOT NULL)
);
CREATE INDEX patients_facility_name_idx ON patients(facility_id,lower(full_name));
CREATE TABLE encounters (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), facility_id uuid NOT NULL REFERENCES facilities(id),
 patient_id uuid NOT NULL, nurse_id uuid NOT NULL,
 encounter_number text NOT NULL, status text NOT NULL DEFAULT 'draft'
 CHECK(status IN ('draft','in_progress','ready_for_triage','cancelled')),
 cancellation_reason text, started_at timestamptz, completed_at timestamptz,
 version bigint NOT NULL DEFAULT 1, current_assessment_id uuid,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(patient_id,facility_id) REFERENCES patients(id,facility_id),
 FOREIGN KEY(nurse_id,facility_id) REFERENCES users(id,facility_id),
 UNIQUE(facility_id,encounter_number), UNIQUE(id,facility_id)
);
CREATE INDEX encounters_patient_idx ON encounters(patient_id,created_at);
CREATE INDEX encounters_nurse_idx ON encounters(facility_id,nurse_id,status,created_at);
CREATE TABLE transcriptions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), encounter_id uuid NOT NULL REFERENCES encounters(id),
 transcript text NOT NULL CHECK(length(transcript) BETWEEN 1 AND 8000),
 language text NOT NULL CHECK(language IN ('id-ID','en-US')),
 source text NOT NULL CHECK(source IN ('on_device_stt','manual_text')),
 client_reference_id uuid NOT NULL, created_by uuid NOT NULL REFERENCES users(id),
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(encounter_id,client_reference_id),UNIQUE(id,encounter_id)
);
CREATE TABLE ai_extractions (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), encounter_id uuid NOT NULL REFERENCES encounters(id),
 transcription_id uuid NOT NULL, request_id uuid NOT NULL,
 created_by uuid NOT NULL REFERENCES users(id), provider text, model_name text,
 prompt_version text NOT NULL DEFAULT 'clinical_extraction_v1', schema_version text NOT NULL DEFAULT '1.0',
 status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','processing','succeeded','failed')),
 extracted_data jsonb, warnings jsonb NOT NULL DEFAULT '[]', error_code text,
 processing_duration_ms bigint, attempts integer NOT NULL DEFAULT 0,
 available_at timestamptz NOT NULL DEFAULT now(), lease_until timestamptz, claim_id uuid,
 base_assessment_id uuid, created_at timestamptz NOT NULL DEFAULT now(), completed_at timestamptz,
 FOREIGN KEY(transcription_id,encounter_id) REFERENCES transcriptions(id,encounter_id),
 UNIQUE(encounter_id,request_id), UNIQUE(id,encounter_id)
);
CREATE INDEX extraction_jobs_idx ON ai_extractions(status,available_at,lease_until);
CREATE TABLE clinical_assessments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), encounter_id uuid NOT NULL REFERENCES encounters(id),
 source_extraction_id uuid, revision_number integer NOT NULL CHECK(revision_number>0),
 chief_complaint text, history_of_present_illness text, relevant_medical_history jsonb,
 allergies jsonb, medications jsonb,
 assessment_status text NOT NULL CHECK(assessment_status IN ('draft','pending_review','verified','superseded')),
 clinical_data jsonb NOT NULL, created_by uuid NOT NULL REFERENCES users(id),
 verified_by uuid REFERENCES users(id), verified_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(encounter_id,revision_number), UNIQUE(id,encounter_id),
 FOREIGN KEY(source_extraction_id,encounter_id) REFERENCES ai_extractions(id,encounter_id),
 CHECK((assessment_status='verified')=(verified_by IS NOT NULL AND verified_at IS NOT NULL))
);
ALTER TABLE encounters ADD CONSTRAINT encounter_current_assessment_fk
 FOREIGN KEY(current_assessment_id,id) REFERENCES clinical_assessments(id,encounter_id);
ALTER TABLE ai_extractions ADD CONSTRAINT extraction_base_assessment_fk
 FOREIGN KEY(base_assessment_id,encounter_id) REFERENCES clinical_assessments(id,encounter_id);
CREATE TABLE vital_signs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), assessment_id uuid NOT NULL REFERENCES clinical_assessments(id),
 measurement_code text NOT NULL CHECK(measurement_code IN ('systolic_bp','diastolic_bp','heart_rate','respiratory_rate','temperature','spo2')),
 numeric_value numeric, measurement_unit text NOT NULL,
 availability text NOT NULL CHECK(availability IN ('measured','missing','unmeasured','not_applicable','ambiguous')),
 measurement_time timestamptz, timing_text text, source text NOT NULL,
 CHECK((availability='measured')=(numeric_value IS NOT NULL)), UNIQUE(assessment_id,measurement_code)
);
CREATE TABLE assessment_status_histories (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), encounter_id uuid NOT NULL REFERENCES encounters(id),
 assessment_id uuid, from_status text, to_status text NOT NULL,
 actor_id uuid NOT NULL REFERENCES users(id), event_type text NOT NULL CHECK(event_type IN ('encounter','assessment')),
 reason text, created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(assessment_id,encounter_id) REFERENCES clinical_assessments(id,encounter_id)
);
CREATE INDEX status_history_encounter_idx ON assessment_status_histories(encounter_id,created_at);
ALTER TABLE audit_logs ADD COLUMN patient_id uuid REFERENCES patients(id);
ALTER TABLE audit_logs ADD COLUMN encounter_id uuid REFERENCES encounters(id);
ALTER TABLE audit_logs ADD COLUMN assessment_id uuid REFERENCES clinical_assessments(id);
CREATE INDEX audit_patient_idx ON audit_logs(patient_id);
CREATE INDEX audit_encounter_idx ON audit_logs(encounter_id);
-- +goose Down
ALTER TABLE audit_logs DROP COLUMN assessment_id, DROP COLUMN encounter_id, DROP COLUMN patient_id;
ALTER TABLE encounters DROP CONSTRAINT encounter_current_assessment_fk;
ALTER TABLE ai_extractions DROP CONSTRAINT extraction_base_assessment_fk;
DROP TABLE assessment_status_histories,vital_signs,clinical_assessments,ai_extractions,transcriptions,encounters,patients;
ALTER TABLE users DROP CONSTRAINT users_id_facility_unique;
