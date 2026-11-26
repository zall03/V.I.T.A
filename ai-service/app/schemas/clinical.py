from datetime import datetime
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, model_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)


class Finding(StrictModel):
    text: str = Field(min_length=1, max_length=2000)
    status: Literal["present", "absent", "uncertain", "conflicting"]
    timing: str | None
    source: Literal["patient_report", "observation", "history", "unknown"]


class Allergy(StrictModel):
    status: Literal["unknown", "present", "absent", "uncertain"]
    items: list[Finding] = Field(max_length=100)


class Measurement(StrictModel):
    value: float | None
    unit: Literal["mmHg", "beats/min", "breaths/min", "Cel", "%"]
    availability: Literal["measured", "missing", "unmeasured", "not_applicable", "ambiguous"]
    observed_at: datetime | None
    timing: str | None
    source: Literal["patient_report", "observation", "history", "unknown"]

    @model_validator(mode="after")
    def availability_matches(self):
        if (self.availability == "measured") != (self.value is not None):
            raise ValueError("measurement availability mismatch")
        if self.observed_at and self.observed_at.tzinfo is None:
            raise ValueError("observation timestamp requires timezone")
        return self


class Vitals(StrictModel):
    systolic_bp: Measurement | None
    diastolic_bp: Measurement | None
    heart_rate: Measurement | None
    respiratory_rate: Measurement | None
    temperature: Measurement | None
    spo2: Measurement | None

    @model_validator(mode="after")
    def units_match(self):
        units = dict(systolic_bp="mmHg", diastolic_bp="mmHg", heart_rate="beats/min",
                     respiratory_rate="breaths/min", temperature="Cel", spo2="%")
        for name, unit in units.items():
            measurement = getattr(self, name)
            if measurement is not None and measurement.unit != unit:
                raise ValueError("measurement unit mismatch")
        return self


class Clinical(StrictModel):
    chief_complaint: str | None = Field(max_length=2000)
    history_of_present_illness: str | None = Field(max_length=4000)
    symptoms: list[Finding] = Field(max_length=100)
    medical_history: list[Finding] = Field(max_length=100)
    allergies: Allergy
    medications: list[Finding] = Field(max_length=100)
    vital_signs: Vitals


class Evidence(StrictModel):
    path: str = Field(min_length=1, max_length=200)
    text: str = Field(min_length=1, max_length=2000)
    status: Literal["present", "absent", "uncertain", "conflicting"]


class Extraction(StrictModel):
    data: Clinical
    evidence: list[Evidence] = Field(max_length=200)
    missing_fields: list[str] = Field(max_length=100)
    warnings: list[str] = Field(max_length=100)
    requires_verification: Literal[True]


def empty_extraction() -> Extraction:
    return Extraction(
        data=Clinical(chief_complaint=None, history_of_present_illness=None,
                      symptoms=[], medical_history=[], allergies=Allergy(status="unknown", items=[]),
                      medications=[], vital_signs=Vitals(**{k: None for k in Vitals.model_fields})),
        evidence=[], missing_fields=["chief_complaint", "vital_signs"], warnings=[],
        requires_verification=True,
    )
