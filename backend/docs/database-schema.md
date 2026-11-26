# Database schema

Migration `00002_clinical.sql` adds seven clinical tables and nullable audit links.
Phase 1 migration remains unchanged. SQLC source: `db/queries/clinical.sql`.

```mermaid
erDiagram
 facilities ||--o{ patients : owns
 facilities ||--o{ encounters : owns
 facilities ||--o{ users : employs
 roles ||--o{ users : assigns
 users ||--o{ patients : creates
 users ||--o{ encounters : assigned_nurse
 patients ||--o{ encounters : attends
 encounters ||--o{ transcriptions : contains
 transcriptions ||--o{ ai_extractions : source
 encounters ||--o{ ai_extractions : owns
 encounters ||--o{ clinical_assessments : revisions
 ai_extractions o|--o{ clinical_assessments : source
 clinical_assessments ||--o{ vital_signs : records
 encounters ||--o{ assessment_status_histories : history
 clinical_assessments o|--o{ assessment_status_histories : history
 users ||--o{ assessment_status_histories : actor
 patients o|--o{ audit_logs : target
 encounters o|--o{ audit_logs : target
 clinical_assessments o|--o{ audit_logs : target
 users ||--o{ audit_logs : actor
 users ||--o{ refresh_tokens : owns
```

Composite foreign keys enforce patient/encounter facility agreement and nested
transcription/extraction/assessment encounter agreement. Encounters reference their
current assessment through `(current_assessment_id,id)`. Extraction base revision
also references an assessment in the same encounter. User foreign keys track creator
and verifier. Local MRNs are unique per facility. Temporary identity does not create
fake NIK or IHS values. Birth date is nullable and age is derived, not persisted.

Mutations lock encounter rows, compare versions, append revisions, write history and
audit within one transaction. Verified revisions retain their status and payload;
currentness is determined by encounter pointer, not by overwriting old status.
