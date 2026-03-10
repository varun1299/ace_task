# ACE Guardian API Test Suite

Test suite for the **ACE Guardian** component: rules-based validation of cooling set point recommendations (POST `/guardian/validate`). Aligned with BDD/specification-by-example and the OctaiPipe tech stack.

## Contents

| Item | Description |
|------|-------------|
| `features/guardian_validate.feature` | Gherkin feature and scenarios for Guardian API (*automated* via Python/C# tests) |
| `features/ace_api.feature` | BDD scenarios for ACE API (Guardian contract, errors, health, config, auth, performance) |
| `features/ace_components.feature` | BDD scenarios for Optimiser, Digital Twin, Guardian, Advisor and E2E flows |
| `features/ace_ui.feature` | BDD scenarios for ACE UI (login, Home, Cooling Management, One-Click Approval) |
| `features/ace_non_functional.feature` | BDD scenarios for performance, security, reliability, deployment |
| `features/README.md` | Index of feature files and tags |
| `src/GuardianApiTests/` | C# .NET 8 xUnit API tests (FluentAssertions) |
| `tests/test_guardian_validate.py` | Python pytest API tests |

## Project structure: use of each file

| File | Purpose |
|------|--------|
| **Root / config** | |
| `README.md` | Project overview, setup, commands, and API contract. |
| `.env.example` | Template for env vars (e.g. `GUARDIAN_API_BASE_URL`). Copy to `.env` and edit. |
| `.env` | Local overrides (gitignored). Python tests load it via `conftest.py`; C# uses it if you source it before `dotnet test`. |
| `.gitignore` | Ignores `.env`, Python cache/venv, .NET bin/obj, IDE files. |
| `requirements-dev.txt` | Python deps for pip/venv users; notes/commands for .NET 8 SDK. |
| `Pipfile` | Pipenv: dev deps and scripts (`pipenv run fmt`, `pipenv run checkfmt`). |
| **BDD / specification** | |
| `features/guardian_validate.feature` | Gherkin feature and scenarios for Guardian behaviour (valid/invalid, constraints, boundaries, invalid request, outline). Single source of truth for “what” to test. |
| **Python tests** | |
| `tests/conftest.py` | Pytest hook: loads `.env` from project root so `GUARDIAN_API_BASE_URL` is set for all tests. |
| `tests/test_guardian_validate.py` | Pytest API tests for `POST /guardian/validate`: status, `valid`, `breaches`; mirrors the feature scenarios. |
| **Stub API** | |
| `scripts/stub_guardian_api.py` | Minimal HTTP stub for `/guardian/validate` so you can run tests without the real API. Logs request/response to stderr. |
| **C# tests** | |
| `src/GuardianApiTests.sln` | Visual Studio solution for the C# test project. |
| `src/GuardianApiTests/GuardianApiTests.csproj` | .NET 8 test project; references xUnit, FluentAssertions, Microsoft.NET.Test.Sdk. |
| `src/GuardianApiTests/GuardianApiClient.cs` | HTTP client: serializes request (snake_case JSON), calls `POST guardian/validate`, returns response. |
| `src/GuardianApiTests/GuardianApiFixture.cs` | xUnit fixture: creates a shared `GuardianApiClient` with base URL from `GUARDIAN_API_BASE_URL` or default. |
| `src/GuardianApiTests/GuardianValidateRequestBuilder.cs` | Fluent builder for `GuardianValidateRequest` (e.g. `WithExampleBaseline()`, `WithRecommendedSupplyAirTemp(23)`). |
| `src/GuardianApiTests/GuardianValidateTests.cs` | xUnit tests calling the client and asserting status, `valid`, and `breaches`; maps to feature scenarios. |
| `src/GuardianApiTests/Models/GuardianValidateRequest.cs` | DTOs for request body: `GuardianValidateRequest`, `CurrentState`, `RecommendedSetpoints`, `Constraints`, `DigitalTwinPrediction` with `[JsonPropertyName]` for snake_case. |
| `src/GuardianApiTests/Models/GuardianValidateResponse.cs` | DTOs for response: `GuardianValidateResponse` (`valid`, `breaches`, etc.) for deserialization. |
| **CI / docs** | |
| `.github/workflows/guardian-api-tests.yml` | GitHub Actions: runs C# and Python tests on push/PR; uses `GUARDIAN_API_BASE_URL` from vars. |
| `docs/STUB_VALIDATION.md` | Validation that stub responses match test expectations (from terminal log). |

## Prerequisites

- **C# tests**: .NET 8 SDK  
- **Python tests**: Python 3.10+, either `pip install -r requirements-dev.txt` (venv) or `pipenv install --dev` (Pipenv)  
- **Guardian API**: Running instance (e.g. Docker or local); base URL configurable.

## Configuration

Set the Guardian API base URL (default `http://localhost:5000`):

- **`.env` file (recommended)**: Copy `.env.example` to `.env` and set `GUARDIAN_API_BASE_URL`. Python tests load it automatically; for C# run from a shell that sources `.env` (e.g. `set -a && source .env && set +a` then `dotnet test`).
- **Environment**: `GUARDIAN_API_BASE_URL=http://localhost:8080`  
- **Python**: `pytest --base-url=http://localhost:8080 ...`

## Commands (copy-paste)

**One-time setup (from repo root):**
```bash
cd guardian-api-tests
cp .env.example .env
# Either venv + pip:
pip install -r requirements-dev.txt
# Or Pipenv:
pipenv install --dev
```

**Format / check format (Pipenv):**
```bash
pipenv run fmt       # format code
pipenv run checkfmt  # check only (CI)
```

**Option A – Use the stub API (no real Guardian API needed):**

Terminal 1 – start stub:
```bash
cd guardian-api-tests
python scripts/stub_guardian_api.py
# Or with Pipenv: pipenv run python scripts/stub_guardian_api.py
```

Terminal 2 – run tests:
```bash
cd guardian-api-tests
pytest tests/test_guardian_validate.py -v
# Or with Pipenv: pipenv run pytest tests/test_guardian_validate.py -v
```
```bash
cd guardian-api-tests/src/GuardianApiTests
dotnet test
```

**Option B – Use your real Guardian API:**

1. Start your Guardian/ACE API (e.g. Docker or your app) and note its URL.
2. Set it in `.env`: `GUARDIAN_API_BASE_URL=http://localhost:YOUR_PORT`
3. Run the same test commands as above (from `guardian-api-tests` and `guardian-api-tests/src/GuardianApiTests`).

---

## Running the tests

### C# (.NET)

```bash
cd guardian-api-tests/src/GuardianApiTests
dotnet test
```

With custom base URL:
```bash
GUARDIAN_API_BASE_URL=http://localhost:8080 dotnet test
```

Or source `.env` then run:
```bash
cd guardian-api-tests
set -a && source .env && set +a
cd src/GuardianApiTests && dotnet test
```

Filter by category:
```bash
dotnet test --filter "Category=Guardian"
```

### Python (pytest)

```bash
cd guardian-api-tests
pip install -r requirements-dev.txt
pytest tests/test_guardian_validate.py -v
```

With custom base URL:
```bash
pytest tests/test_guardian_validate.py -v --base-url=http://localhost:8080
```

## BDD scenarios (feature file)

The behaviour is specified in `features/guardian_validate.feature`:

- **Valid recommendation** within all constraints → accepted  
- **Max supply air temp** exceeded → rejected, breach reported  
- **Min supply air temp** exceeded (recommendation too low) → rejected  
- **Predicted rack inlet temp** above constraint → rejected  
- **Boundary**: recommendation exactly at max/min supply air temp → accepted  
- **Boundary**: predicted rack inlet exactly at constraint → accepted  
- **Invalid request** (e.g. missing `recommended_setpoints`) → 400/422  
- **Scenario outline**: multiple zones and set point combinations  

The C# and Python tests implement these scenarios as executable API tests.

## API contract (example)

**Request** – POST `/guardian/validate`:

```json
{
  "zone_id": "DC-01",
  "timestamp": "2026-02-20T10:15:00Z",
  "current_state": {
    "supply_air_temp": 21.5,
    "return_air_temp": 29.8,
    "max_rack_inlet_temp": 26.0,
    "pue": 1.48
  },
  "recommended_setpoints": { "supply_air_temp": 23.0 },
  "constraints": {
    "max_supply_air_temp": 24.0,
    "max_rack_inlet_temp": 27.0,
    "min_supply_air_temp": 18.0
  },
  "digital_twin_prediction": {
    "predicted_max_rack_inlet_temp": 26.8,
    "predicted_pue": 1.42
  }
}
```

**Response** (expected shape; adapt to actual API):

- `valid` (boolean): overall validation result  
- `approved` / `validation_result` (optional): alternative or additional result indicators  
- `breaches` (array, optional): list of constraint breaches (e.g. `constraint`, `description`)  

If the real API uses different status codes or field names, update the request/response models and assertions in the C# and Python projects to match.

## CI (e.g. GitHub Actions)

Example step to run C# tests:

```yaml
- name: Run Guardian API tests (C#)
  env:
    GUARDIAN_API_BASE_URL: ${{ env.GUARDIAN_API_URL }}
  run: dotnet test guardian-api-tests/src/GuardianApiTests/GuardianApiTests.csproj --no-build -v normal
```

For Python:

```yaml
- name: Run Guardian API tests (Python)
  env:
    GUARDIAN_API_BASE_URL: ${{ env.GUARDIAN_API_URL }}
  run: pytest guardian-api-tests/tests/test_guardian_validate.py -v
```

Ensure the Guardian API (e.g. in Docker) is started and `GUARDIAN_API_URL` is set before these steps.

## Docker

If the ACE API (including Guardian) runs in Docker, start the stack first, then point tests at the API URL (e.g. `http://localhost:5000` or the mapped port). No change to the test code is required beyond base URL configuration.
