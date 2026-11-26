# Clinical extraction schema 1.0

Canonical executable schema: `ai-service/app/schemas/clinical.py`. Go counterpart:
`internal/integration/ai/schema.go`. Unknown fields rejected. Version unsupported:
422 internally. No diagnosis, triage or treatment fields.

Clinical fields: chief_complaint and history_of_present_illness nullable strings;
symptoms, medical_history, medications arrays; allergies object; vital_signs object.
Findings contain text, status (present/absent/uncertain/conflicting), timing nullable,
and source (patient_report/observation/history/unknown).

Allergies status: unknown/present/absent/uncertain. Empty items do not imply absence.
Vital keys: systolic_bp, diastolic_bp, heart_rate, respiratory_rate, temperature, spo2.
Each is null or measurement with value, unit, availability, observed_at, timing, source.
Units respectively mmHg, mmHg, beats/min, breaths/min, Cel, %. Zero is a value.
Availability measured requires numeric value; missing/unmeasured/not_applicable/
ambiguous require null. Absolute times require timezone. Relative times stay text.
No clinical thresholds or normal ranges are imposed.

Evidence includes JSON path, exact supporting transcript text, and finding status.
Python validates evidence paths and requires support for populated findings/values.
This does not prove semantic correctness. Every result requires nurse verification.

Minimal manual data:
```json
{"chief_complaint":null,"history_of_present_illness":null,"symptoms":[],"medical_history":[],"allergies":{"status":"unknown","items":[]},"medications":[],"vital_signs":{"systolic_bp":null,"diastolic_bp":null,"heart_rate":null,"respiratory_rate":null,"temperature":null,"spo2":null}}
```
