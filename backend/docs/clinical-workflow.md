# Clinical workflow

```mermaid
stateDiagram-v2
 [*] --> draft
 draft --> in_progress: assigned nurse starts
 draft --> cancelled: reason
 in_progress --> cancelled: reason
 in_progress --> ready_for_triage: current revision verified
 ready_for_triage --> in_progress: new correction revision
 ready_for_triage --> cancelled: reason
```

Verification is not encounter completion. No clinical urgency or triage category is
calculated. Missing values can remain missing after explicit nurse verification.

```mermaid
sequenceDiagram
 participant Nurse
 participant Go
 participant DB
 participant Worker
 participant AI
 Nurse->>Go: Submit original transcript + client reference
 Go->>DB: Immutable transcription
 Nurse->>Go: Enqueue extraction + request UUID
 Go->>DB: Pending job
 Go-->>Nurse: 202 + job ID
 Worker->>DB: Claim lease and fencing UUID
 Worker->>AI: Minimized text + internal credential
 AI-->>Worker: Strict schema + evidence, unverified
 Worker->>DB: Immutable extraction and optional review draft
 Nurse->>Go: Review/correct using encounter version
 Go->>DB: Append assessment revision
 Nurse->>Go: Verify current assessment ID + encounter version
 Go->>DB: Verification, status and audit transaction
```

```mermaid
stateDiagram-v2
 [*] --> pending
 pending --> processing: claim
 processing --> succeeded: valid result
 processing --> pending: transient failure, attempts below 3
 processing --> processing: expired lease reclaimed
 processing --> failed: permanent failure or attempts exhausted
```

Retry explicitly with a new request UUID; original job is preserved. Reusing a UUID
with different transcription returns 409. Worker uses 120-second lease, 75-second
HTTP deadline and maximum three claims. One job per worker process bounds concurrency.
Human work takes precedence: AI completion never replaces an existing assessment.
Manual entry has no dependency on AI availability. Corrections append a new draft;
stale version or stale verification ID returns 409.
