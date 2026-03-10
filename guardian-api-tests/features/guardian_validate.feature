# language: en
@guardian @api @cooling
Feature: Guardian validation of cooling set point recommendations
  As the ACE Guardian component
  I ensure that no recommendations that could cause a breach of operational and safety constraints are actioned
  So that cooling changes remain within temperature limits and SLA requirements

  Background:
    Given the Guardian API is available at "<base_url>"
    And the default constraints are:
      | max_supply_air_temp | 24.0 |
      | max_rack_inlet_temp | 27.0 |
      | min_supply_air_temp | 18.0 |

  @happy_path @valid
  Scenario: Valid recommendation within all constraints is accepted
    Given a zone "DC-01" with current state:
      | supply_air_temp   | 21.5 |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is 23.0
    And digital twin predicts max_rack_inlet_temp 26.8 and pue 1.42
    When the Guardian validates the recommendation
    Then the validation result is "approved" or "valid"
    And no constraint breaches are reported

  @constraint_breach @supply_air_temp_max
  Scenario: Recommendation exceeding max supply air temp is rejected
    Given a zone "DC-01" with current state:
      | supply_air_temp   | 21.5 |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is 25.0
    And constraint max_supply_air_temp is 24.0
    And digital twin predicts max_rack_inlet_temp 26.5 and pue 1.40
    When the Guardian validates the recommendation
    Then the validation result is "rejected" or "invalid"
    And a breach of "max_supply_air_temp" or "supply_air_temp" is reported

  @constraint_breach @supply_air_temp_min
  Scenario: Recommendation below min supply air temp is rejected
    Given a zone "DC-01" with current state:
      | supply_air_temp   | 21.5 |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is 17.0
    And constraint min_supply_air_temp is 18.0
    And digital twin predicts max_rack_inlet_temp 25.0 and pue 1.45
    When the Guardian validates the recommendation
    Then the validation result is "rejected" or "invalid"
    And a breach of "min_supply_air_temp" or "supply_air_temp" is reported

  @constraint_breach @rack_inlet_temp
  Scenario: Predicted rack inlet temp exceeding constraint is rejected
    Given a zone "DC-01" with current state:
      | supply_air_temp   | 21.5 |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is 23.0
    And constraint max_rack_inlet_temp is 27.0
    And digital twin predicts max_rack_inlet_temp 27.5 and pue 1.41
    When the Guardian validates the recommendation
    Then the validation result is "rejected" or "invalid"
    And a breach of "max_rack_inlet_temp" or "rack_inlet_temp" is reported

  @boundary @supply_air_temp_at_limits
  Scenario: Recommendation exactly at supply air temp limits is accepted
    Given a zone "DC-01" with current state:
      | supply_air_temp   | 21.5 |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is 24.0
    And constraint max_supply_air_temp is 24.0 and min_supply_air_temp is 18.0
    And digital twin predicts max_rack_inlet_temp 26.9 and pue 1.42
    When the Guardian validates the recommendation
    Then the validation result is "approved" or "valid"

  @boundary @rack_inlet_at_limit
  Scenario: Predicted rack inlet temp exactly at constraint limit is accepted
    Given a zone "DC-01" with current state:
      | supply_air_temp   | 21.5 |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is 23.0
    And constraint max_rack_inlet_temp is 27.0
    And digital twin predicts max_rack_inlet_temp 27.0 and pue 1.42
    When the Guardian validates the recommendation
    Then the validation result is "approved" or "valid"

  @validation @invalid_request
  Scenario: Malformed or invalid request returns error
    Given a zone "DC-01"
    And the request body is missing required field "recommended_setpoints"
    When the Guardian validate endpoint is called
    Then the API returns status 400 or 422
    And an error message indicates invalid or missing data

  @validation @missing_constraints
  Scenario: Request with missing constraints is handled
    Given a zone "DC-01" with current state:
      | supply_air_temp   | 21.5 |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is 23.0
    And constraints are omitted or incomplete
    When the Guardian validates the recommendation
    Then the API returns status 400 or 422 or uses server defaults and validates

  @example
  Scenario Outline: Multiple zones and set point combinations
    Given a zone "<zone_id>" with current state:
      | supply_air_temp   | <current_supply> |
      | return_air_temp   | 29.8 |
      | max_rack_inlet_temp | 26.0 |
      | pue               | 1.48 |
    And recommended set point supply_air_temp is <recommended_supply>
    And constraints are max_supply_air_temp 24.0, min_supply_air_temp 18.0, max_rack_inlet_temp 27.0
    And digital twin predicts max_rack_inlet_temp <predicted_rack_inlet> and pue 1.42
    When the Guardian validates the recommendation
    Then the validation result is "<expected_result>"

    Examples:
      | zone_id | current_supply | recommended_supply | predicted_rack_inlet | expected_result |
      | DC-01   | 21.5           | 22.0              | 26.5                 | approved        |
      | DC-02   | 20.0           | 23.0              | 26.8                 | approved        |
      | DC-01   | 21.5           | 24.5              | 26.0                 | rejected        |
      | DC-01   | 21.5           | 23.0              | 27.8                 | rejected        |
