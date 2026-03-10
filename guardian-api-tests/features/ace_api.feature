# language: en
@ace @api @ace_api
Feature: ACE API
  As a client of the ACE API (on-site REST layer)
  I can call documented endpoints and receive consistent, well-formed responses
  So that the UI, Optimiser, and other components integrate reliably with Guardian and other API behaviour

  Background:
    Given the ACE API base URL is available (e.g. from GUARDIAN_API_BASE_URL or deployment config)
    And the API serves the Guardian and any other on-site endpoints

  # ---------------------------------------------------------------------------
  # GUARDIAN VALIDATE (see guardian_validate.feature for full rule scenarios)
  # ---------------------------------------------------------------------------
  @guardian @validate @contract
  Scenario: Guardian validate accepts valid request and returns validation result
    Given a valid request body with zone_id, current_state, recommended_setpoints, constraints, digital_twin_prediction
    When the client sends POST to "<base>/guardian/validate" with Content-Type application/json
    Then the API returns HTTP status 200
    And the response body is valid JSON
    And the response contains a "valid" field (boolean)
    And the response may contain "breaches" (null or array of constraint breach objects)
    And when valid is true, no unsafe recommendation is indicated for application

  @guardian @validate @errors
  Scenario: Guardian validate returns 400 for invalid JSON
    When the client sends POST to "<base>/guardian/validate" with body that is not valid JSON
    Then the API returns HTTP status 400
    And the response indicates invalid or malformed request

  @guardian @validate @errors
  Scenario: Guardian validate returns 422 when required field is missing
    Given a request body that omits "recommended_setpoints"
    When the client sends POST to "<base>/guardian/validate"
    Then the API returns HTTP status 400 or 422
    And the response indicates missing or invalid data (e.g. recommended_setpoints)

  @guardian @validate @errors
  Scenario: Guardian validate returns 422 when supply_air_temp has wrong type
    Given a request body where recommended_setpoints.supply_air_temp is a string instead of number
    When the client sends POST to "<base>/guardian/validate"
    Then the API returns HTTP status 400 or 422
    And the response indicates invalid type or validation error

  @guardian @validate @http
  Scenario: Guardian validate rejects GET with 405
    When the client sends GET to "<base>/guardian/validate"
    Then the API returns HTTP status 405 or 501
    And the response indicates that POST is required or method not allowed

  @guardian @validate @http
  Scenario: Unknown path returns 404
    When the client sends POST to "<base>/guardian/validatex" (or any path not implemented)
    Then the API returns HTTP status 404
    And the response may include an error message or body

  @guardian @validate @contract
  Scenario: Guardian validate response shape is consistent
    Given the client sends a valid POST to "<base>/guardian/validate"
    When the API returns status 200
    Then the response has a "valid" key of type boolean
    And if "breaches" is present it is null or a list
    And each breach object has constraint and/or description when present

  # ---------------------------------------------------------------------------
  # HEALTH / READINESS (optional – implement if ACE API exposes these)
  # ---------------------------------------------------------------------------
  @health @readiness
  Scenario: Health or readiness endpoint returns 200 when API is up
    Given the ACE API is running and healthy
    When the client sends GET to "<base>/health" or "<base>/ready" or "<base>/api/health"
    Then the API returns HTTP status 200
    And the response indicates healthy or ready (e.g. status field or empty body)
    # Note: Adjust path to match actual ACE API; skip scenario if endpoint does not exist

  # ---------------------------------------------------------------------------
  # CONFIGURATION / CONSTRAINTS (optional – if exposed by ACE API)
  # ---------------------------------------------------------------------------
  @config @constraints
  Scenario: Constraints or config endpoint returns current limits when implemented
    Given the ACE API exposes a constraints or config endpoint for the site or zone
    When the client sends GET to the constraints/config endpoint with valid auth (if required)
    Then the API returns HTTP status 200
    And the response includes constraint values (e.g. max_supply_air_temp, max_rack_inlet_temp, min_supply_air_temp)
    # Note: Implement when ACE API documents such an endpoint; skip otherwise

  # ---------------------------------------------------------------------------
  # AUTHENTICATION (when API is secured)
  # ---------------------------------------------------------------------------
  @security @auth
  Scenario: Unauthenticated request to protected endpoint returns 401 or 403 when auth is required
    Given the ACE API is configured to require authentication
    When the client sends POST to "<base>/guardian/validate" without a valid token or credentials
    Then the API returns HTTP status 401 or 403
    And no validation result or sensitive data is returned in the body
    # Note: Skip or adjust when API runs without auth (e.g. local stub)

  # ---------------------------------------------------------------------------
  # PERFORMANCE (API-level)
  # ---------------------------------------------------------------------------
  @performance @latency
  Scenario: Guardian validate responds within configured timeout
    Given a valid request body for POST "<base>/guardian/validate"
    When the client sends the request
    Then the API responds with status 200 or 4xx within "<timeout>" seconds (e.g. from env TIMEOUT)
    So that the UI and callers do not hang

  # ---------------------------------------------------------------------------
  # OPTIMISER / DIGITAL TWIN ENDPOINTS (when exposed by ACE API)
  # ---------------------------------------------------------------------------
  @optimiser @api
  Scenario: Optimiser recommendation endpoint returns recommendation when implemented
    Given the ACE API exposes an endpoint to get or generate Optimiser recommendations for a zone
    When the client calls that endpoint with valid parameters (zone, current state, etc.)
    Then the API returns HTTP status 200
    And the response includes recommended_setpoints or equivalent structure for Guardian input
    # Note: Add when Optimiser is exposed via ACE API; skip otherwise

  @digital_twin @api
  Scenario: Digital twin prediction endpoint returns prediction when implemented
    Given the ACE API exposes an endpoint to run Digital Twin prediction (set points → impact)
    When the client calls that endpoint with proposed set points and zone/state
    Then the API returns HTTP status 200
    And the response includes predicted_max_rack_inlet_temp and/or predicted_pue (or equivalent)
    # Note: Add when Digital Twin is exposed via ACE API; skip otherwise
