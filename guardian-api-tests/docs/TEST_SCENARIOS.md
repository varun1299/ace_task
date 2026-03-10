# Guardian API test scenarios

## Tests now covered (Python – `tests/test_guardian_validate.py`)

### Validation rules and boundaries
| # | Test method | What it checks |
|---|-------------|----------------|
| 1 | `test_valid_recommendation_within_all_constraints_is_accepted` | Request within all limits → 200, `valid: true`, no breaches |
| 2 | `test_recommendation_exceeding_max_supply_air_temp_is_rejected` | Recommended supply > max_supply_air_temp → 200, `valid: false`, breach reported |
| 3 | `test_recommendation_below_min_supply_air_temp_is_rejected` | Recommended supply < min_supply_air_temp → 200, `valid: false` |
| 4 | `test_predicted_rack_inlet_temp_exceeding_constraint_is_rejected` | predicted_max_rack_inlet_temp > max → 200, `valid: false`, rack breach |
| 5 | `test_recommendation_exactly_at_max_supply_air_temp_is_accepted` | supply_air_temp = max → 200, `valid: true` |
| 6 | `test_predicted_rack_inlet_exactly_at_constraint_is_accepted` | predicted_rack = max_rack_inlet_temp → 200, `valid: true` |
| 7 | `test_recommendation_exactly_at_min_supply_air_temp_is_accepted` | supply_air_temp = min → 200, `valid: true` |
| 8 | `test_multiple_breaches_rejected_with_both_reported` | Supply over max and rack over limit → both breaches in response |
| 9 | `test_multiple_zones_and_set_points` (parametrized ×4) | DC-01/DC-02, various set points → correct valid true/false |

### Missing / invalid payload
| # | Test method | What it checks |
|---|-------------|----------------|
| 10 | `test_invalid_request_missing_recommended_setpoints_returns_4xx` | Body without recommended_setpoints → 400 or 422 |
| 11 | `test_invalid_json_returns_400` | Invalid JSON body → 400 |
| 12 | `test_empty_body_returns_4xx` | Empty `{}` → 400 or 422 |
| 13 | `test_wrong_type_supply_air_temp_returns_4xx` | supply_air_temp as string → 400 or 422 |

### Missing / incomplete constraints
| # | Test method | What it checks |
|---|-------------|----------------|
| 14 | `test_missing_constraints_returns_200_or_4xx` | `constraints` empty `{}` → 200 (server defaults) or 400/422 |
| 15 | `test_constraints_omitted_entirely_returns_200_or_4xx` | `constraints` key omitted → 200 or 400/422 |

### Numeric edge cases
| # | Test method | What it checks |
|---|-------------|----------------|
| 16 | `test_numeric_edge_negative_supply_air_temp` | Negative recommended supply_air_temp → 200 (valid false) or 400/422 |
| 17 | `test_numeric_edge_very_large_supply_air_temp` | Very large supply_air_temp (1e6) → 200 (valid false) or 400/422 |

### Extra fields and Content-Type
| # | Test method | What it checks |
|---|-------------|----------------|
| 18 | `test_extra_unknown_fields_in_payload_accepted_or_400` | Unknown keys in JSON → 200 (ignored) or 400 |
| 19 | `test_content_type_wrong_returns_200_or_400` | Valid JSON with Content-Type: text/plain → 200 or 400 |
| 20 | `test_content_type_missing_returns_200_or_400` | Valid JSON without Content-Type header → 200 or 400 |

### HTTP and path
| # | Test method | What it checks |
|---|-------------|----------------|
| 21 | `test_wrong_path_returns_404` | POST /guardian/validatex → 404 |
| 22 | `test_wrong_method_get_returns_405_or_501` | GET instead of POST → 405 or 501 |

### Response schema and optional fields
| # | Test method | What it checks |
|---|-------------|----------------|
| 23 | `test_response_shape_has_valid_and_optional_breaches` | `valid` (bool), `breaches` (null/list); each breach object has constraint/description (string) when present |
| 24 | `test_optional_fields_zone_id_timestamp_accepted` | Missing zone_id/timestamp → 200 or 400/422 |

---

## Summary

- **Total:** 24 test cases (including 4 parametrized rows = 27 test runs).
- **Covered:** Validation rules, boundaries, missing/invalid payload, missing/incomplete constraints, numeric edge cases, extra fields, Content-Type, wrong path/method, response schema (incl. breach shape), optional fields.
- **Not covered:** NaN/Inf in JSON (non-standard); full request/response JSON schema or Pydantic validation (optional enhancement).
