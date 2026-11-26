from app.core.exceptions import ProviderFailure


def validate_evidence(result, transcript):
    document = result.model_dump(mode="json")
    paths = set()
    for evidence in result.evidence:
        if evidence.text not in transcript:
            raise ProviderFailure("unsupported_evidence")
        node = document
        try:
            for part in evidence.path.split("."):
                node = node[int(part)] if isinstance(node, list) else node[part]
        except (KeyError, IndexError, ValueError, TypeError):
            raise ProviderFailure("invalid_evidence_path") from None
        if node is None:
            raise ProviderFailure("invalid_evidence_path")
        paths.add(evidence.path)
    required = []
    for field in ("chief_complaint", "history_of_present_illness"):
        if getattr(result.data, field) is not None:
            required.append(f"data.{field}")
    for field in ("symptoms", "medical_history", "medications"):
        required.extend(f"data.{field}.{i}.text" for i, _ in enumerate(getattr(result.data, field)))
    required.extend(f"data.allergies.items.{i}.text" for i, _ in enumerate(result.data.allergies.items))
    if result.data.allergies.status != "unknown":
        required.append("data.allergies.status")
    for field in type(result.data.vital_signs).model_fields:
        measurement = getattr(result.data.vital_signs, field)
        if measurement and measurement.value is not None:
            required.append(f"data.vital_signs.{field}.value")
    if any(path not in paths for path in required):
        raise ProviderFailure("missing_evidence")
    return result
