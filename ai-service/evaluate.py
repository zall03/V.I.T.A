"""Evaluate mock only; never interpret these scores as Gemini or clinical accuracy."""
import asyncio
import json
from pathlib import Path
import time
from app.providers.mock import MockProvider


async def main():
    dataset = json.loads((Path(__file__).parent / "tests/fixtures/evaluation.json").read_text())
    provider = MockProvider()
    matches = numeric_matches = total = numeric_total = null_matches = null_total = 0
    failures = 0
    start = time.monotonic()
    for case in dataset:
        try:
            result = (await provider.extract(case["transcript"], "id-ID")).model_dump(mode="json")
        except Exception:
            failures += 1
            continue
        for path, expected in case["expected"].items():
            actual = result
            found = True
            try:
                for part in path.split("."):
                    actual = actual[int(part)] if isinstance(actual, list) else actual[part]
            except (KeyError, IndexError, TypeError):
                found = False
            equal = found and actual == expected
            total += 1
            matches += equal
            if isinstance(expected, (int, float)):
                numeric_total += 1
                numeric_matches += equal
            if expected is None:
                null_total += 1
                null_matches += equal
    print(json.dumps(dict(provider="mock", cases=len(dataset), checked_fields=total,
        matched_fields=matches, numeric_fields=numeric_total, matched_numeric_fields=numeric_matches,
        expected_null_fields=null_total, preserved_null_fields=null_matches,
        failures=failures, elapsed_ms=round((time.monotonic()-start)*1000, 3),
        limitations="Fixture baseline, not Gemini evaluation; no calibrated clinical accuracy; unsupported generation not fully annotated"), indent=2))


if __name__ == "__main__":
    asyncio.run(main())
