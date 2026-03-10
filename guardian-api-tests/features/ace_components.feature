# language: en
@ace @components @optimiser @digital_twin @guardian @advisor
Feature: ACE key components and their interactions
  As the ACE system
  I coordinate Optimiser, Digital Twin, Guardian, and Advisor
  So that cooling recommendations are safe, understandable, and energy-efficient

  # ---------------------------------------------------------------------------
  # OPTIMISER
  # ---------------------------------------------------------------------------
  @optimiser @api
  Scenario: Optimiser produces a recommendation within constraints
    Given the AI Optimiser has current operational state for zone "DC-01"
    And the Optimiser is configured to reduce energy while respecting limits
    When the Optimiser generates a cooling recommendation
    Then the recommendation includes recommended_setpoints (e.g. supply_air_temp)
    And the recommendation is suitable for Guardian validation

  @optimiser @constraints
  Scenario: Optimiser respects configured temperature bounds
    Given constraint min_supply_air_temp is 18.0 and max_supply_air_temp is 24.0
    When the Optimiser generates a recommendation for zone "DC-01"
    Then the recommended supply_air_temp is between 18.0 and 24.0
    Or the recommendation is explicitly marked for Guardian review

  # ---------------------------------------------------------------------------
  # DIGITAL TWIN
  # ---------------------------------------------------------------------------
  @digital_twin @api
  Scenario: Digital twin predicts impact of set point change
    Given a proposed set point change (e.g. supply_air_temp 23.0) for zone "DC-01"
    And current state and facility model are available
    When the Digital Twin runs a prediction
    Then the prediction includes predicted_max_rack_inlet_temp
    And the prediction includes predicted_pue or energy impact
    And the prediction is used as input to Guardian validation

  @digital_twin @guardian_integration
  Scenario: Guardian uses digital twin prediction to reject unsafe recommendation
    Given recommended_setpoints supply_air_temp is 23.0
    And digital_twin_prediction predicted_max_rack_inlet_temp is 27.5
    And constraint max_rack_inlet_temp is 27.0
    When the Guardian validates the recommendation
    Then the validation result is "rejected"
    And a breach of max_rack_inlet_temp is reported

  # ---------------------------------------------------------------------------
  # GUARDIAN (see guardian_validate.feature for rules; ace_api.feature for API contract)
  # ---------------------------------------------------------------------------
  @guardian @api
  Scenario: Guardian API accepts valid payload and returns validation result
    Given a valid request body with current_state, recommended_setpoints, constraints, digital_twin_prediction
    When the client sends POST /guardian/validate
    Then the API returns status 200
    And the response includes "valid" (boolean)
    And the response may include "breaches" (array or null)

  @guardian @safety
  Scenario: No recommendation is actioned without Guardian approval
    Given the Guardian has rejected a recommendation due to constraint breach
    When the system considers applying the recommendation
    Then the recommendation is not written to BMS/DCIM
    And the user interface shows the recommendation as rejected or blocked

  # ---------------------------------------------------------------------------
  # ADVISOR
  # ---------------------------------------------------------------------------
  @advisor @ui
  Scenario: Advisor provides natural language explanation on login
    Given the Facility Manager has logged into the ACE user interface
    When the Home screen is displayed
    Then the Advisor provides an update on the state of the site
    And the explanation is in natural language (LLM-based)

  @advisor @cooling_management
  Scenario: Advisor explains recommendations on Cooling Management screen
    Given the Facility Manager is on the Cooling Management screen
    And there are one or more recommendations (validated by Guardian)
    When the user views a recommendation
    Then Advisor explanations are available for the recommendation
    And the explanation helps the user understand the basis of the recommendation

  # ---------------------------------------------------------------------------
  # END-TO-END FLOW
  # ---------------------------------------------------------------------------
  @e2e @optimiser_guardian_ui
  Scenario: Recommendation flows from Optimiser through Guardian to UI
    Given the Optimiser has generated a recommendation for zone "DC-01"
    And the Digital Twin has produced a prediction for that recommendation
    When the Guardian validates the recommendation
    And the validation result is "approved"
    Then the recommendation is visible on the Cooling Management screen
    And the user can use One-Click Approval to apply it
    And the Action/Impact projection reflects the Digital Twin prediction

  @e2e @rejected_recommendation
  Scenario: Rejected recommendation is not applied and is clearly indicated
    Given the Guardian has rejected a recommendation (e.g. breach of max_rack_inlet_temp)
    When the Facility Manager views the Cooling Management screen
    Then the recommendation is shown as rejected or not approved
    And One-Click Approval is not available for that recommendation
    And the breach or reason is indicated (e.g. via breaches from Guardian API)
