-- name: CreatePatient :one
INSERT INTO patients(facility_id,medical_record_number,full_name,birth_date,sex,identity_status,patient_ihs_number,created_by)
VALUES($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *;
-- name: GetPatient :one
SELECT * FROM patients WHERE id=$1 AND facility_id=$2;
-- name: ListPatients :many
SELECT * FROM patients WHERE facility_id=$1 AND
(sqlc.arg(search)::text='' OR medical_record_number=sqlc.arg(search) OR full_name ILIKE '%'||sqlc.arg(search)||'%')
ORDER BY created_at DESC,id LIMIT $2 OFFSET $3;
-- name: UpdatePatient :one
UPDATE patients SET full_name=$3,birth_date=$4,sex=$5,identity_status=$6,patient_ihs_number=$7,
version=version+1,updated_at=now() WHERE id=$1 AND facility_id=$2 AND version=$8 RETURNING *;
-- name: CreateEncounter :one
INSERT INTO encounters(facility_id,patient_id,nurse_id,encounter_number) VALUES($1,$2,$3,$4) RETURNING *;
-- name: GetEncounter :one
SELECT * FROM encounters WHERE id=$1 AND facility_id=$2 AND nurse_id=$3;
-- name: LockEncounter :one
SELECT * FROM encounters WHERE id=$1 AND facility_id=$2 AND nurse_id=$3 FOR UPDATE;
-- name: ListEncounters :many
SELECT * FROM encounters WHERE facility_id=$1 AND nurse_id=$2
AND (sqlc.narg(patient_id)::uuid IS NULL OR patient_id=sqlc.narg(patient_id))
ORDER BY created_at DESC,id LIMIT $3 OFFSET $4;
-- name: TransitionEncounter :one
UPDATE encounters SET status=$2,cancellation_reason=$3,version=version+1,updated_at=now(),
started_at=CASE WHEN $2='in_progress' THEN COALESCE(started_at,now()) ELSE started_at END
WHERE id=$1 AND version=$4 RETURNING *;
-- name: InsertHistory :exec
INSERT INTO assessment_status_histories(encounter_id,assessment_id,from_status,to_status,actor_id,event_type,reason)
VALUES($1,$2,$3,$4,$5,$6,$7);
-- name: ListHistory :many
SELECT * FROM assessment_status_histories WHERE encounter_id=$1 ORDER BY created_at,id;
-- name: ClinicalAudit :exec
INSERT INTO audit_logs(facility_id,actor_id,action,patient_id,encounter_id,assessment_id) VALUES($1,$2,$3,$4,$5,$6);
-- name: CreateTranscription :one
INSERT INTO transcriptions(encounter_id,transcript,language,source,client_reference_id,created_by)
VALUES($1,$2,$3,$4,$5,$6) RETURNING *;
-- name: GetTranscriptionByReference :one
SELECT * FROM transcriptions WHERE encounter_id=$1 AND client_reference_id=$2;
-- name: GetTranscription :one
SELECT * FROM transcriptions WHERE id=$1 AND encounter_id=$2;
-- name: ListTranscriptions :many
SELECT * FROM transcriptions WHERE encounter_id=$1 ORDER BY created_at,id LIMIT $2 OFFSET $3;
-- name: CreateExtraction :one
INSERT INTO ai_extractions(encounter_id,transcription_id,request_id,created_by,base_assessment_id)
VALUES($1,$2,$3,$4,$5) RETURNING *;
-- name: GetExtractionByRequest :one
SELECT * FROM ai_extractions WHERE encounter_id=$1 AND request_id=$2;
-- name: GetExtraction :one
SELECT * FROM ai_extractions WHERE id=$1 AND encounter_id=$2;
-- name: ListExtractions :many
SELECT * FROM ai_extractions WHERE encounter_id=$1 ORDER BY created_at DESC,id LIMIT $2 OFFSET $3;
-- name: ClaimExtraction :one
UPDATE ai_extractions SET status='processing',attempts=attempts+1,claim_id=sqlc.arg(claim_id),lease_until=now()+interval '120 seconds'
WHERE id=(SELECT id FROM ai_extractions WHERE attempts<3 AND
((status='pending' AND available_at<=now()) OR (status='processing' AND lease_until<now()))
ORDER BY created_at FOR UPDATE SKIP LOCKED LIMIT 1) RETURNING *;
-- name: ExhaustJobs :exec
UPDATE ai_extractions SET status='failed',error_code='worker_interrupted',completed_at=now()
WHERE status='processing' AND lease_until<now() AND attempts>=3;
-- name: LockClaim :one
SELECT * FROM ai_extractions WHERE id=$1 AND claim_id=$2 AND status='processing' AND lease_until>now() FOR UPDATE;
-- name: FinishExtraction :execrows
UPDATE ai_extractions SET status='succeeded',extracted_data=$3,warnings=$4,provider=$5,model_name=$6,
processing_duration_ms=$7,completed_at=now(),lease_until=NULL WHERE id=$1 AND claim_id=$2 AND status='processing';
-- name: FailExtraction :execrows
UPDATE ai_extractions SET status=$3,error_code=$4,available_at=now()+interval '10 seconds',lease_until=NULL,
completed_at=CASE WHEN $3='failed' THEN now() ELSE NULL END WHERE id=$1 AND claim_id=$2 AND status='processing';
-- name: CreateAssessment :one
INSERT INTO clinical_assessments(encounter_id,source_extraction_id,revision_number,chief_complaint,history_of_present_illness,
relevant_medical_history,allergies,medications,assessment_status,clinical_data,created_by)
VALUES($1,$2,(SELECT COALESCE(max(a.revision_number),0)+1 FROM clinical_assessments a WHERE a.encounter_id=$1),$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *;
-- name: SetCurrentAssessment :exec
UPDATE encounters SET current_assessment_id=$2,version=version+1,status='in_progress',updated_at=now() WHERE id=$1;
-- name: GetAssessment :one
SELECT * FROM clinical_assessments WHERE id=$1 AND encounter_id=$2;
-- name: ListAssessments :many
SELECT * FROM clinical_assessments WHERE encounter_id=$1 ORDER BY revision_number DESC LIMIT $2 OFFSET $3;
-- name: VerifyAssessment :one
UPDATE clinical_assessments SET assessment_status='verified',verified_by=$3,verified_at=now(),updated_at=now()
WHERE id=$1 AND encounter_id=$2 AND assessment_status IN ('draft','pending_review') RETURNING *;
-- name: InsertVital :exec
INSERT INTO vital_signs(assessment_id,measurement_code,numeric_value,measurement_unit,availability,measurement_time,timing_text,source)
VALUES($1,$2,$3,$4,$5,$6,$7,$8);
