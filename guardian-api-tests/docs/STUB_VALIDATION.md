# Stub API response validation

Validation of stub script responses (from terminal 4 request/response log) against pytest test expectations.

## Run pytest locally

From `guardian-api-tests` with your venv activated and the stub running in another terminal:

```bash
python -m pytest tests/test_guardian_validate.py -v
```

---

## Stub response validation (vs test expectations)

| Test scenario | Request (key values) | Expected | Stub response in log | Result |
|---------------|---------------------|----------|----------------------|--------|
| **Valid recommendation** | supply_air_temp 23, max 24, min 18, predicted_rack 26.8 ≤ 27 | 200, `valid: true`, no breaches | 200, `valid: true`, `breaches: null` | Pass |
| **Max supply exceeded** | recommended_supply 25, max_supply_air_temp 24 | 200, `valid: false`, breach max_supply_air_temp | 200, `valid: false`, breach "max_supply_air_temp" / "Above max" | Pass |
| **Min supply exceeded** | recommended_supply 17, min_supply_air_temp 18 | 200, `valid: false`, breach min | 200, `valid: false`, breach "min_supply_air_temp" / "Below min" | Pass |
| **Predicted rack inlet exceed** | predicted_max_rack_inlet_temp 27.5 or 27.8, max_rack_inlet 27 | 200, `valid: false`, breach max_rack_inlet_temp | 200, `valid: false`, breach "max_rack_inlet_temp" / "Predicted exceed" | Pass |
| **Boundary: supply at max** | supply_air_temp 24, max 24, predicted 26.9 | 200, `valid: true` | 200, `valid: true`, `breaches: null` | Pass |
| **Boundary: rack at limit** | supply 23, predicted 27.0, max_rack 27 | 200, `valid: true` | 200, `valid: true`, `breaches: null` | Pass |
| **Invalid: missing recommended_setpoints** | Body without `recommended_setpoints` | 400 or 422 | 422, `message: "Missing recommended_setpoints"` | Pass |
| **Parametrized (DC-01, 22, 26.5)** | recommended 22, predicted 26.5 | valid true | 200, `valid: true` | Pass |
| **Parametrized (DC-02, 23, 26.8)** | recommended 23, predicted 26.8 | valid true | 200, `valid: true` | Pass |
| **Parametrized (DC-01, 24.5, 26)** | recommended 24.5 > max 24 | valid false | 200, `valid: false`, max_supply_air_temp breach | Pass |
| **Parametrized (DC-01, 23, 27.8)** | predicted 27.8 > max 27 | valid false | 200, `valid: false`, max_rack_inlet_temp breach | Pass |

---

## Summary

- **Status codes**: Valid requests get **200**; malformed (missing `recommended_setpoints`) get **422**. Matches test expectations.
- **Body shape**: Responses include `valid` (boolean) and `breaches` (array or null). Matches tests.
- **Constraint logic**: Stub correctly rejects when:
  - `supply_air_temp` &lt; `min_supply_air_temp` or &gt; `max_supply_air_temp`
  - `predicted_max_rack_inlet_temp` &gt; `max_rack_inlet_temp`
- **Boundaries**: Exactly at limits (supply = max, predicted_rack = max) are accepted.

**Conclusion:** Stub responses in terminal 4 are as expected for all test scenarios. Running `pytest tests/test_guardian_validate.py -v` with the stub on port 5000 should yield 11 passed tests.
