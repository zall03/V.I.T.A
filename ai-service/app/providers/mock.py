"""Conservative fixture provider, NOT a general clinical extraction model."""
from app.schemas.clinical import Evidence, Measurement, empty_extraction

SYNTHETIC = (
    "Pasien mengeluh sesak napas sejak tadi pagi. "
    "Tekanan darah seratus tiga puluh per sembilan puluh. "
    "Saturasi delapan puluh sembilan persen. "
    "Frekuensi napas tiga puluh kali per menit."
)


class MockProvider:
    name = "mock"
    model = "synthetic-fixture-v1"

    async def extract(self, transcript, language):
        result = empty_extraction()
        if transcript.strip() != SYNTHETIC:
            result.warnings = ["mock_unrecognized_input_manual_review_required"]
            return result
        result.data.chief_complaint = "Sesak napas"
        result.data.history_of_present_illness = "Sejak tadi pagi"
        result.evidence = [Evidence(path="data.chief_complaint", text="sesak napas", status="present"),
                           Evidence(path="data.history_of_present_illness", text="sejak tadi pagi", status="present")]
        values = {
            "systolic_bp": (130, "mmHg", "seratus tiga puluh"),
            "diastolic_bp": (90, "mmHg", "sembilan puluh"),
            "spo2": (89, "%", "delapan puluh sembilan"),
            "respiratory_rate": (30, "breaths/min", "tiga puluh kali per menit"),
        }
        for field, (value, unit, text) in values.items():
            setattr(result.data.vital_signs, field, Measurement(value=value, unit=unit,
                    availability="measured", observed_at=None, timing=None, source="observation"))
            result.evidence.append(Evidence(path=f"data.vital_signs.{field}.value", text=text, status="present"))
        result.missing_fields = ["data.vital_signs.heart_rate", "data.vital_signs.temperature"]
        result.warnings = ["synthetic_fixture_only"]
        return result

    async def close(self):
        pass
