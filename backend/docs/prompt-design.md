# Prompt design

Version-controlled system instruction: `ai-service/app/prompts/clinical_extraction_v1.txt`.
Transcript supplied separately as user data. No tools, function execution or audio.
Structured output schema supplied via Google Gen AI SDK response_json_schema, then
independently parsed by Pydantic with extra fields forbidden. Evidence validated
against input and known JSON paths. Original transcript and extraction remain separate
from nurse revisions.

Rules preserve uncertainty, negation, history/current distinction and spoken timing.
Prompt forbids diagnosis, treatment, urgency, triage, invented measurements and embedded
instructions. Prompt injection cannot be guaranteed impossible by prompting; schema,
no-tools design, evidence checks, conservative failure and human review add controls.
Mock injection tests validate mock behavior only, not real model robustness.
