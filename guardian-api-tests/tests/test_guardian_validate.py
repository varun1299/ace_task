"""
ACE Guardian API tests - POST /guardian/validate.

Specification-by-example style tests matching guardian_validate.feature.
Run: pytest tests/test_guardian_validate.py -v
Base URL: GUARDIAN_API_BASE_URL or --base-url (default http://localhost:5000).
"""

import json
import os
import pytest
import requests

# Loaded from env (conftest loads .env); default 10 seconds
TIMEOUT = int(os.environ.get("TIMEOUT", "10"))


def _base_url(request):
    opt = request.config.getoption("--base-url", default=None)
    return opt or os.environ.get("GUARDIAN_API_BASE_URL", "http://localhost:5000")


def _payload(
    zone_id="DC-01",
    supply_air_temp=21.5,
    return_air_temp=29.8,
    current_max_rack_inlet_temp=26.0,
    pue=1.48,
    recommended_supply_air_temp=23.0,
    max_supply_air_temp=24.0,
    constraint_max_rack_inlet_temp=27.0,
    min_supply_air_temp=18.0,
    predicted_max_rack_inlet_temp=26.8,
    predicted_pue=1.42,
):
    return {
        "zone_id": zone_id,
        "timestamp": "2026-02-20T10:15:00Z",
        "current_state": {
            "supply_air_temp": supply_air_temp,
            "return_air_temp": return_air_temp,
            "max_rack_inlet_temp": current_max_rack_inlet_temp,
            "pue": pue,
        },
        "recommended_setpoints": {"supply_air_temp": recommended_supply_air_temp},
        "constraints": {
            "max_supply_air_temp": max_supply_air_temp,
            "max_rack_inlet_temp": constraint_max_rack_inlet_temp,
            "min_supply_air_temp": min_supply_air_temp,
        },
        "digital_twin_prediction": {
            "predicted_max_rack_inlet_temp": predicted_max_rack_inlet_temp,
            "predicted_pue": predicted_pue,
        },
    }


class TestGuardianValidate:
    """Guardian validation API tests."""

    def test_valid_recommendation_within_all_constraints_is_accepted(self, request):
        """Valid recommendation within all constraints is accepted."""
        base = _base_url(request).rstrip("/")
        resp = requests.post(f"{base}/guardian/validate", json=_payload(), timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is True
        assert not (data.get("breaches") or [])

    def test_recommendation_exceeding_max_supply_air_temp_is_rejected(self, request):
        """Recommendation exceeding max supply air temp is rejected."""
        base = _base_url(request).rstrip("/")
        payload = _payload(recommended_supply_air_temp=25.0, max_supply_air_temp=24.0)
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is False
        breaches = data.get("breaches") or []
        supply_breach = any(
            "supply" in (b.get("constraint") or "").lower()
            or "supply" in (b.get("description") or "").lower()
            for b in breaches
        )
        assert supply_breach or not data.get("valid")

    def test_recommendation_below_min_supply_air_temp_is_rejected(self, request):
        """Recommendation below min supply air temp is rejected."""
        base = _base_url(request).rstrip("/")
        payload = _payload(recommended_supply_air_temp=17.0, min_supply_air_temp=18.0)
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is False

    def test_predicted_rack_inlet_temp_exceeding_constraint_is_rejected(self, request):
        """Predicted rack inlet temp exceeding constraint is rejected."""
        base = _base_url(request).rstrip("/")
        payload = _payload(
            recommended_supply_air_temp=23.0,
            constraint_max_rack_inlet_temp=27.0,
            predicted_max_rack_inlet_temp=27.5,
        )
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is False
        breaches = data.get("breaches") or []
        rack_breach = any(
            "rack" in (b.get("constraint") or "").lower()
            or "rack" in (b.get("description") or "").lower()
            for b in breaches
        )
        assert rack_breach or not data.get("valid")

    def test_recommendation_exactly_at_max_supply_air_temp_is_accepted(self, request):
        """Recommendation exactly at supply air temp limits is accepted."""
        base = _base_url(request).rstrip("/")
        payload = _payload(
            recommended_supply_air_temp=24.0,
            max_supply_air_temp=24.0,
            min_supply_air_temp=18.0,
            predicted_max_rack_inlet_temp=26.9,
        )
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is True

    def test_predicted_rack_inlet_exactly_at_constraint_is_accepted(self, request):
        """Predicted rack inlet temp exactly at constraint limit is accepted."""
        base = _base_url(request).rstrip("/")
        payload = _payload(
            recommended_supply_air_temp=23.0,
            constraint_max_rack_inlet_temp=27.0,
            predicted_max_rack_inlet_temp=27.0,
        )
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is True

    def test_recommendation_exactly_at_min_supply_air_temp_is_accepted(self, request):
        """Recommendation exactly at min supply air temp is accepted (inclusive bound)."""
        base = _base_url(request).rstrip("/")
        payload = _payload(
            recommended_supply_air_temp=18.0,
            min_supply_air_temp=18.0,
            max_supply_air_temp=24.0,
            predicted_max_rack_inlet_temp=25.0,
        )
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is True

    def test_multiple_breaches_rejected_with_both_reported(self, request):
        """Supply above max and predicted rack above limit → valid false, both breaches."""
        base = _base_url(request).rstrip("/")
        payload = _payload(
            recommended_supply_air_temp=25.0,
            max_supply_air_temp=24.0,
            constraint_max_rack_inlet_temp=27.0,
            predicted_max_rack_inlet_temp=28.0,
        )
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is False
        breaches = data.get("breaches") or []
        constraints_in_breaches = [b.get("constraint", "") for b in breaches]
        assert any("supply" in c.lower() for c in constraints_in_breaches)
        assert any("rack" in c.lower() for c in constraints_in_breaches)

    def test_invalid_request_missing_recommended_setpoints_returns_4xx(self, request):
        """Malformed or invalid request returns error."""
        base = _base_url(request).rstrip("/")
        payload = _payload()
        del payload["recommended_setpoints"]
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code in (400, 422), resp.text

    def test_invalid_json_returns_400(self, request):
        """Invalid JSON body → 400."""
        base = _base_url(request).rstrip("/")
        resp = requests.post(
            f"{base}/guardian/validate",
            data="not json",
            headers={"Content-Type": "application/json"},
            timeout=TIMEOUT,
        )
        assert resp.status_code == 400, resp.text

    def test_empty_body_returns_4xx(self, request):
        """Empty body {} → 400 or 422."""
        base = _base_url(request).rstrip("/")
        resp = requests.post(
            f"{base}/guardian/validate",
            json={},
            timeout=TIMEOUT,
        )
        assert resp.status_code in (400, 422), resp.text

    def test_wrong_type_supply_air_temp_returns_4xx(self, request):
        """Wrong type for supply_air_temp (e.g. string) → 400 or 422."""
        base = _base_url(request).rstrip("/")
        payload = _payload()
        payload["recommended_setpoints"]["supply_air_temp"] = "23"
        resp = requests.post(
            f"{base}/guardian/validate",
            json=payload,
            timeout=TIMEOUT,
        )
        assert resp.status_code in (400, 422), resp.text

    def test_wrong_path_returns_404(self, request):
        """Wrong path (e.g. /guardian/validatex) → 404."""
        base = _base_url(request).rstrip("/")
        resp = requests.post(
            f"{base}/guardian/validatex",
            json=_payload(),
            timeout=TIMEOUT,
        )
        assert resp.status_code == 404, resp.text

    def test_wrong_method_get_returns_405_or_501(self, request):
        """GET instead of POST → 405 (or 501 if API does not send 405)."""
        base = _base_url(request).rstrip("/")
        resp = requests.get(f"{base}/guardian/validate", timeout=TIMEOUT)
        assert resp.status_code in (405, 501), resp.text

    def test_response_shape_has_valid_and_optional_breaches(self, request):
        """Response includes 'valid'; 'breaches' optional (list or null); breach shape."""
        base = _base_url(request).rstrip("/")
        resp = requests.post(
            f"{base}/guardian/validate",
            json=_payload(),
            timeout=TIMEOUT,
        )
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert "valid" in data, "Response must include 'valid'"
        assert isinstance(data["valid"], bool), "'valid' must be boolean"
        if "breaches" in data:
            assert data["breaches"] is None or isinstance(
                data["breaches"], list
            ), "'breaches' must be null or list"
        # Trigger a response with breaches to assert breach object shape
        resp2 = requests.post(
            f"{base}/guardian/validate",
            json=_payload(recommended_supply_air_temp=25.0, max_supply_air_temp=24.0),
            timeout=TIMEOUT,
        )
        assert resp2.status_code == 200, resp2.text
        data2 = resp2.json()
        breaches = data2.get("breaches") or []
        for b in breaches:
            assert isinstance(b, dict), "Each breach must be an object"
            if "constraint" in b:
                assert isinstance(b["constraint"], str), "constraint must be string"
            if "description" in b:
                assert isinstance(b["description"], str), "description must be string"

    def test_optional_fields_zone_id_timestamp_accepted(self, request):
        """Missing zone_id/timestamp (optional) → 200 when rest of payload valid."""
        base = _base_url(request).rstrip("/")
        payload = _payload()
        payload.pop("zone_id", None)
        payload.pop("timestamp", None)
        resp = requests.post(
            f"{base}/guardian/validate",
            json=payload,
            timeout=TIMEOUT,
        )
        # API may treat as optional (200) or required (400/422)
        assert resp.status_code in (200, 400, 422), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data

    def test_missing_constraints_returns_200_or_4xx(self, request):
        """Constraints omitted or empty → 200 (server defaults) or 400/422."""
        base = _base_url(request).rstrip("/")
        payload = _payload()
        payload["constraints"] = {}
        resp = requests.post(
            f"{base}/guardian/validate",
            json=payload,
            timeout=TIMEOUT,
        )
        assert resp.status_code in (200, 400, 422), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data

    def test_constraints_omitted_entirely_returns_200_or_4xx(self, request):
        """Request with constraints key omitted → 200 or 400/422."""
        base = _base_url(request).rstrip("/")
        payload = _payload()
        del payload["constraints"]
        resp = requests.post(
            f"{base}/guardian/validate",
            json=payload,
            timeout=TIMEOUT,
        )
        assert resp.status_code in (200, 400, 422), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data

    def test_numeric_edge_negative_supply_air_temp(self, request):
        """Negative recommended supply_air_temp → 200 with valid false or 400/422."""
        base = _base_url(request).rstrip("/")
        payload = _payload(recommended_supply_air_temp=-1.0)
        resp = requests.post(
            f"{base}/guardian/validate",
            json=payload,
            timeout=TIMEOUT,
        )
        assert resp.status_code in (200, 400, 422), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data
            # Typically invalid (below min)
            assert data.get("valid") is False or data.get("breaches")

    def test_numeric_edge_very_large_supply_air_temp(self, request):
        """Very large recommended supply_air_temp → 200 with valid false or 400/422."""
        base = _base_url(request).rstrip("/")
        payload = _payload(recommended_supply_air_temp=1e6)
        resp = requests.post(
            f"{base}/guardian/validate",
            json=payload,
            timeout=TIMEOUT,
        )
        assert resp.status_code in (200, 400, 422), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data
            assert data.get("valid") is False or data.get("breaches")

    def test_extra_unknown_fields_in_payload_accepted_or_400(self, request):
        """Unknown fields in JSON → 200 (ignored) or 400."""
        base = _base_url(request).rstrip("/")
        payload = _payload()
        payload["unknown_key"] = "value"
        payload["recommended_setpoints"]["another_unknown"] = 99
        resp = requests.post(
            f"{base}/guardian/validate",
            json=payload,
            timeout=TIMEOUT,
        )
        assert resp.status_code in (200, 400), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data

    def test_content_type_wrong_returns_200_or_400(self, request):
        """Valid JSON sent with wrong Content-Type → 200 (accepted) or 400."""
        base = _base_url(request).rstrip("/")
        body = json.dumps(_payload())
        resp = requests.post(
            f"{base}/guardian/validate",
            data=body,
            headers={"Content-Type": "text/plain"},
            timeout=TIMEOUT,
        )
        assert resp.status_code in (200, 400), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data

    def test_content_type_missing_returns_200_or_400(self, request):
        """Valid JSON sent without Content-Type → 200 (accepted) or 400."""
        base = _base_url(request).rstrip("/")
        body = json.dumps(_payload())
        resp = requests.post(
            f"{base}/guardian/validate",
            data=body,
            headers={},
            timeout=TIMEOUT,
        )
        assert resp.status_code in (200, 400), resp.text
        if resp.status_code == 200:
            data = resp.json()
            assert "valid" in data

    @pytest.mark.parametrize(
        "zone_id,current_supply,recommended_supply,predicted_rack_inlet,expected_valid",
        [
            ("DC-01", 21.5, 22.0, 26.5, True),
            ("DC-02", 20.0, 23.0, 26.8, True),
            ("DC-01", 21.5, 24.5, 26.0, False),
            ("DC-01", 21.5, 23.0, 27.8, False),
        ],
    )
    def test_multiple_zones_and_set_points(
        self,
        request,
        zone_id,
        current_supply,
        recommended_supply,
        predicted_rack_inlet,
        expected_valid,
    ):
        """Multiple zones and set point combinations (specification outline)."""
        base = _base_url(request).rstrip("/")
        payload = _payload(
            zone_id=zone_id,
            supply_air_temp=current_supply,
            recommended_supply_air_temp=recommended_supply,
            predicted_max_rack_inlet_temp=predicted_rack_inlet,
        )
        resp = requests.post(f"{base}/guardian/validate", json=payload, timeout=TIMEOUT)
        assert resp.status_code == 200, resp.text
        data = resp.json()
        assert data.get("valid") is expected_valid, (
            f"zone={zone_id}, recommended_supply={recommended_supply}, "
            f"predicted_rack_inlet={predicted_rack_inlet} "
            f"expected valid={expected_valid}"
        )


def pytest_addoption(parser):
    parser.addoption(
        "--base-url", action="store", default=None, help="Guardian API base URL"
    )
