# Phase 2 API contract

All routes below require active `nurse` role. Patient access is facility-scoped;
encounter access additionally requires assigned nurse. Admin and queue_operator
cannot access clinical endpoints. Existing Phase 1 routes remain unchanged.
Success and error envelopes follow Phase 1. No raw provider errors are exposed.

| Method | Path | Body / behavior |
|---|---|---|
| POST | /api/v1/patients | demographics + optional local MRN |
| GET | /api/v1/patients | search, limit, offset |
| GET | /api/v1/patients/{id} | safe demographic detail |
| PATCH | /api/v1/patients/{id} | full demographic fields + version |
| GET | /api/v1/patients/{id}/encounters | assigned nurse history |
| POST | /api/v1/encounters | patient_id |
| GET | /api/v1/encounters | limit, offset |
| GET | /api/v1/encounters/{id} | includes current version |
| GET | /api/v1/encounters/{id}/history | status events |
| POST | /api/v1/encounters/{id}/start | version |
| POST | /api/v1/encounters/{id}/cancel | version, reason |
| POST/GET | /api/v1/encounters/{id}/transcriptions | immutable originals |
| POST/GET | /api/v1/encounters/{id}/extractions | enqueue/list |
| GET | /api/v1/encounters/{id}/extractions/{extraction_id} | persisted status/result |
| POST | /api/v1/encounters/{id}/assessments | initial manual revision |
| GET | /api/v1/encounters/{id}/assessment | current revision + encounter_version |
| PATCH | /api/v1/encounters/{id}/assessment | new correction revision |
| POST | /api/v1/encounters/{id}/assessment/verify | assessment_id, version |
| GET | /api/v1/encounters/{id}/assessment/history | immutable revisions |

Create temporary patient:
```json
{"identity_status":"temporary","full_name":null,"birth_date":null,"sex":"unknown"}
```
Create identified patient:
```json
{"medical_record_number":"SYN-001","identity_status":"identified","full_name":"Synthetic Patient","birth_date":"2000-01-01","sex":"unknown"}
```
Transcription:
```json
{"client_reference_id":"00000000-0000-4000-8000-000000000001","transcript":"Pasien mengeluh sesak napas.","language":"id-ID","source":"on_device_stt"}
```
Extraction:
```json
{"request_id":"00000000-0000-4000-8000-000000000002","transcription_id":"00000000-0000-4000-8000-000000000003"}
```
Manual assessment body uses `{"version":2,"data":<Clinical schema>}`. Corrections use
the same full data shape; PATCH appends a revision rather than merging arbitrary JSON.
Optional `source_extraction_id` must identify a succeeded extraction in this encounter.

200 reads/transitions; 201 creation/revisions; 202 enqueue; 400 invalid DTO/schema;
401 missing/invalid auth; 403 role denied; 404 absent/out-of-scope; 409 stale version,
invalid transition or idempotency conflict; 413 body too large; 429 rate limit; 500
safe internal error. AI transport failures become persisted failed jobs, not synchronous
502 responses to enqueue. List endpoints default 20, max 100, offset max 1,000,000.
