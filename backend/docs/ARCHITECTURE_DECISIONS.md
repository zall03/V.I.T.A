# Architecture decisions

- Preserve module layout and existing envelopes/endpoint compatibility.
- Canonical PRD stays in owner-provided `prd disini`; root instructions point to it.
- Existing ai_extractions combines immutable result and persisted job metadata;
  physical extraction_jobs duplication unnecessary unless behavior requires it.
- Clinical rule activation must require exact source and independent approval.
- Existing vital_signs rows are derived projections of assessment JSON, written
  transactionally; they must not become separately editable authorities.
- Existing nurse ownership is stricter than facility-wide clinical access. Retain
  until an explicit care-team access policy is implemented and tested.
