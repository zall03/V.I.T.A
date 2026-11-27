# Frontend alignment increment

New frontend files include nurse profile, history archive detail, vital history,
transcript accordion and audio memo player. Provider stores data in memory; audio
memo currently advances a timer rather than decoding audio. Profile shift/zone/mic
updates are local; backend has no corresponding persisted assignment fields.

Added frontend/lib/core/api/vita_api.dart with injected HTTP client, backend envelopes,
email/password login, in-memory session, serialized explicit refresh rotation, logout,
facility/identity, patient/encounter, transcript, extraction, assessment/history and
verification operations. No automatic mutation retry. Dependency http pinned 1.6.0.

Actual checks: flutter analyze passed (5.2s); flutter test passed 3 tests, including
existing UI flow and two new transport tests. SDK now Flutter 3.50.1 / Dart 3.14.0.

PARTIALLY COMPLETED: adapter is not yet wired to existing demo screens. Do not call
this end-to-end integration. Next: separate demo/live mode, bind login/profile, map
nullable clinical DTOs and IDs, then bind intake/revision workflow. Secure persistent
token storage, native STT/audio playback, offline sync, queue/FHIR remain pending.
Do not map age-only demo records into invented birth dates or generate normal vitals.
