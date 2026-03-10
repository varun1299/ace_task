#!/usr/bin/env python3
"""
Minimal stub for POST /guardian/validate so you can run tests without the real API.
Usage: python scripts/stub_guardian_api.py
Serves http://127.0.0.1:5000/guardian/validate
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import sys

PORT = 5000


def _log(label, data):
    """Print request/response to terminal so you can see API traffic."""
    text = json.dumps(data, indent=2) if isinstance(data, dict) else str(data)
    print(f"\n--- {label} ---\n{text}\n", file=sys.stderr, flush=True)


class GuardianValidateHandler(BaseHTTPRequestHandler):
    def _send_404(self):
        self._send(
            404,
            {"error": "Not Found", "message": f"Path not found: {self.path}"},
        )

    def do_POST(self):
        if self.path != "/guardian/validate":
            self._send_404()
            return
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            data = json.loads(body) if body else {}
        except (ValueError, json.JSONDecodeError):
            _log("REQUEST (raw)", body.decode(errors="replace") if body else "")
            self._send(400, {"valid": False, "message": "Invalid JSON"})
            return
        _log("REQUEST", data)
        # Accept both snake_case (Python/API) and PascalCase (C# HttpClient)
        req = (
            data.get("recommended_setpoints") or data.get("RecommendedSetpoints") or {}
        )
        constraints = data.get("constraints") or data.get("Constraints") or {}
        prediction = (
            data.get("digital_twin_prediction")
            or data.get("DigitalTwinPrediction")
            or {}
        )
        supply = (
            req.get("supply_air_temp")
            if req.get("supply_air_temp") is not None
            else req.get("SupplyAirTemp")
        )
        if supply is None:
            self._send(
                422, {"valid": False, "message": "Missing recommended_setpoints"}
            )
            return
        if not isinstance(supply, (int, float)):
            self._send(
                422,
                {"valid": False, "message": "Invalid type for supply_air_temp"},
            )
            return
        min_s = constraints.get("min_supply_air_temp") or constraints.get(
            "MinSupplyAirTemp"
        )
        max_s = constraints.get("max_supply_air_temp") or constraints.get(
            "MaxSupplyAirTemp"
        )
        max_rack = constraints.get("max_rack_inlet_temp") or constraints.get(
            "MaxRackInletTemp"
        )
        pred_rack = (
            prediction.get("predicted_max_rack_inlet_temp")
            if prediction.get("predicted_max_rack_inlet_temp") is not None
            else prediction.get("PredictedMaxRackInletTemp")
        )
        breaches = []
        if min_s is not None and supply < min_s:
            breaches.append(
                {"constraint": "min_supply_air_temp", "description": "Below min"}
            )
        if max_s is not None and supply > max_s:
            breaches.append(
                {"constraint": "max_supply_air_temp", "description": "Above max"}
            )
        if max_rack is not None and pred_rack is not None and pred_rack > max_rack:
            breaches.append(
                {"constraint": "max_rack_inlet_temp", "description": "Predicted exceed"}
            )
        valid = len(breaches) == 0
        self._send(200, {"valid": valid, "breaches": breaches if breaches else None})

    def do_GET(self):
        """POST only; GET returns 405."""
        if self.path == "/guardian/validate" or self.path.startswith("/guardian/"):
            self._send(
                405,
                {"error": "Method Not Allowed", "message": "Use POST"},
            )
        else:
            self._send_404()

    def _send(self, status, body):
        _log(f"RESPONSE {status}", body)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(body).encode())

    def log_message(self, format, *args):
        print(f"[stub] {args[0]}", file=sys.stderr)


def main():
    server = HTTPServer(("127.0.0.1", PORT), GuardianValidateHandler)
    print(
        f"Stub Guardian API at http://127.0.0.1:{PORT}/guardian/validate (Ctrl+C to stop)",
        file=sys.stderr,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
