# language: en
@ace @non_functional @performance @security @reliability
Feature: ACE non-functional requirements
  As the ACE system
  I meet non-functional requirements for performance, security, and reliability
  So that the solution is fit for production use in data centre environments

  # ---------------------------------------------------------------------------
  # PERFORMANCE – ACE API
  # ---------------------------------------------------------------------------
  @performance @api @guardian
  Scenario: Guardian validate API responds within acceptable time
    Given the Guardian API is available
    And a valid request body is prepared
    When the client sends POST /guardian/validate
    Then the API responds with status 200 within "<timeout>" seconds
    And the response body is valid JSON

  @performance @api @latency
  Scenario: API latency is acceptable for operator workflows
    Given the ACE API (e.g. Guardian, Optimiser endpoints) is under normal load
    When a Facility Manager triggers validation or fetches recommendations
    Then the response is returned within an acceptable latency (e.g. < 5 seconds)
    So that the user experience remains responsive

  # ---------------------------------------------------------------------------
  # SECURITY
  # ---------------------------------------------------------------------------
  @security @communication
  Scenario: Communication between client site and cloud is secured
    Given the Edge Manager communicates with the OctaiPipe Platform (cloud)
    When any data or commands are exchanged
    Then the communication uses TLS (encrypted)
    And the communication is authenticated (e.g. JWT tokens)
    And the communication is restricted to a single REST API port

  @security @data_privacy
  Scenario: Only non-sensitive data is sent to the cloud
    Given ACE is deployed on the client site
    When the Edge Manager sends data to the cloud
    Then only non-sensitive data is sent (e.g. logs, aggregated stats, model parameters, config/software updates)
    And raw operational data is not extracted from the site
    And federated learning is used to avoid transmitting sensitive operational data

  @security @api @authentication
  Scenario: ACE API accepts only authenticated requests when required
    Given the ACE API is configured to require authentication
    When an unauthenticated request is sent to POST /guardian/validate
    Then the API returns 401 Unauthorized or 403 Forbidden
    And no validation result is returned

  # ---------------------------------------------------------------------------
  # AVAILABILITY AND ERROR HANDLING
  # ---------------------------------------------------------------------------
  @reliability @api @availability
  Scenario: API returns a proper response under normal conditions
    Given the Guardian API is running and healthy
    When the client sends a valid POST /guardian/validate request
    Then the API returns HTTP 200 with a validation result
    And the response is not a server error (5xx) under normal conditions

  @reliability @api @error_handling
  Scenario: API returns appropriate errors for invalid input
    Given the Guardian API is available
    When the client sends an invalid request (e.g. invalid JSON, missing required fields)
    Then the API returns 400 or 422 (not 500)
    And the response body indicates the error (e.g. invalid JSON, missing recommended_setpoints)
    So that clients can distinguish client errors from server failures

  @reliability @api @method
  Scenario: API rejects unsupported HTTP methods
    Given the Guardian validate endpoint expects POST
    When the client sends GET (or PUT, DELETE) to /guardian/validate
    Then the API returns 405 Method Not Allowed or equivalent
    And the response indicates that POST is required

  # ---------------------------------------------------------------------------
  # DEPLOYMENT AND CONTAINERS
  # ---------------------------------------------------------------------------
  @deployment @docker
  Scenario: ACE runs as Docker containers on-site
    Given the client has installed Docker and the Edge Manager
    When ACE is deployed on the client site
    Then the main components (including ACE API, UI, Optimiser, Data Loader) run as containers
    And the ACE API (Guardian) is containerised and can be started/stopped with the stack

  # ---------------------------------------------------------------------------
  # UI NON-FUNCTIONAL
  # ---------------------------------------------------------------------------
  @ui @performance @load
  Scenario: UI remains usable under normal load
    Given the ACE UI is deployed and the backend APIs are available
    When the Facility Manager navigates between Home, Cooling Management, and reports
    Then pages load within an acceptable time (e.g. < 3 seconds for key screens)
    And charts and data (e.g. SVG/HTML) render correctly

  @ui @usability
  Scenario: UI presents recommendations and Guardian results clearly
    Given the user is on the Cooling Management screen
    When recommendations and Guardian validation results are displayed
    Then approved and rejected recommendations are visually distinguishable
    And breach reasons (when present) are visible to the user
    So that the user can make informed approval decisions
