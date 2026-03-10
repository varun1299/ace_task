# language: en
@ace @ui @user_interface @facility_manager
Feature: ACE user interface flows
  As a Facility Manager
  I use the ACE browser-based user interface
  So that I can review recommendations, understand facility state, and report on savings

  Background:
    Given the ACE user interface is available
    And the user is a Facility Manager with access to the site

  # ---------------------------------------------------------------------------
  # LOGIN AND HOME
  # ---------------------------------------------------------------------------
  @ui @login
  Scenario: Facility Manager can log on and see the Home screen
    Given the user is on the Log on screen
    When the user enters valid credentials and submits
    Then the user is directed to the Home Screen
    And the Home screen displays a choice of sites with basic KPIs
    And the Advisor provides an update on the state of things

  @ui @home @kpis
  Scenario: Home screen shows historical trends and projections
    Given the Facility Manager has logged in
    When the Home screen is displayed
    Then historical trends for key performance metrics are shown
    And recent performance and projection for key performance and ESG metrics are shown
    And the user can navigate to system configuration or Cooling Management

  @ui @home @reporting
  Scenario: User can access reporting from Home screen
    Given the user is on the Home Screen
    Then the user can access "Performance KPIs"
    And the user can access "SLA Compliance Status"
    And the user can access "ESG Reporting"
    And the user can access "Energy & Financial Saving"

  # ---------------------------------------------------------------------------
  # COOLING MANAGEMENT
  # ---------------------------------------------------------------------------
  @ui @cooling_management
  Scenario: Cooling Management screen supports action approval
    Given the user has navigated to the Cooling Management screen
    When the screen is loaded
    Then the screen is designed for "action approval and what if screens"
    And recommendations (validated by Guardian) are presented for review
    And the user can approve or reject recommendations

  @ui @cooling_management @one_click
  Scenario: One-Click Approval applies only to validated recommendations
    Given the user is on the Cooling Management screen
    And a recommendation has been validated by the Guardian as "approved"
    When the user selects One-Click Approval for that recommendation
    Then the recommendation is applied (e.g. written to BMS/DCIM via Data Writer)
    And the user is informed of success or failure

  @ui @cooling_management @rejected
  Scenario: Rejected recommendations cannot be approved via One-Click
    Given the Guardian has rejected a recommendation
    When the user views the Cooling Management screen
    Then that recommendation is not eligible for One-Click Approval
    Or the recommendation is clearly marked as unsafe / rejected
    And the breach or reason is visible to the user

  @ui @cooling_management @ai_control
  Scenario: User can control AI mode for the site
    Given the user is on the Cooling Management screen
    Then the user can turn AI "On", "Off", or "Pause" for the site
    And the selected mode affects whether recommendations are applied automatically or held for approval

  @ui @cooling_management @projections
  Scenario: Action and impact projections are visible
    Given the user is on the Cooling Management screen
    And there are recommendations with Digital Twin predictions
    When the user views a recommendation
    Then "Action/Impact projection" is available (from Digital Twin)
    And "SLA Compliance projection" is available where applicable
    And the projections help the user understand impact before approving

  @ui @advisor_explanations
  Scenario: Advisor explanations are available on Cooling Management
    Given the user is on the Cooling Management screen
    When the user views recommendations or system state
    Then "Advisor Explanations" are available
    And the explanations are in natural language (LLM-based)

  # ---------------------------------------------------------------------------
  # CONFIGURATION AND STATE
  # ---------------------------------------------------------------------------
  @ui @configuration
  Scenario: User can navigate to system configuration
    Given the user is on the Home Screen
    When the user chooses to open system configuration
    Then the user can access configuration (e.g. constraints, limits, thresholds)
    And changes may affect Guardian rules and Optimiser behaviour

  @ui @state
  Scenario: Current facility state is visible
    Given the user is logged in and viewing a site
    Then the current facility state (e.g. temperatures, PUE) is visible
    And the state reflects data from the Data Loader / on-site systems
    And the user can relate recommendations to current state
