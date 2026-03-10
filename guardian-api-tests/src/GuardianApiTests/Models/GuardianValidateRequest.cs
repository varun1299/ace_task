using System.Text.Json.Serialization;

namespace GuardianApiTests.Models;

/// <summary>
/// Request body for POST /guardian/validate (ACE Guardian API).
/// </summary>
public class GuardianValidateRequest
{
    [JsonPropertyName("zone_id")]
    public string ZoneId { get; set; } = string.Empty;

    [JsonPropertyName("timestamp")]
    public string Timestamp { get; set; } = string.Empty;

    [JsonPropertyName("current_state")]
    public CurrentState CurrentState { get; set; } = new();

    [JsonPropertyName("recommended_setpoints")]
    public RecommendedSetpoints? RecommendedSetpoints { get; set; } = new();

    [JsonPropertyName("constraints")]
    public Constraints Constraints { get; set; } = new();

    [JsonPropertyName("digital_twin_prediction")]
    public DigitalTwinPrediction DigitalTwinPrediction { get; set; } = new();
}

public class CurrentState
{
    [JsonPropertyName("supply_air_temp")]
    public double SupplyAirTemp { get; set; }

    [JsonPropertyName("return_air_temp")]
    public double ReturnAirTemp { get; set; }

    [JsonPropertyName("max_rack_inlet_temp")]
    public double MaxRackInletTemp { get; set; }

    [JsonPropertyName("pue")]
    public double Pue { get; set; }
}

public class RecommendedSetpoints
{
    [JsonPropertyName("supply_air_temp")]
    public double SupplyAirTemp { get; set; }
}

public class Constraints
{
    [JsonPropertyName("max_supply_air_temp")]
    public double MaxSupplyAirTemp { get; set; }

    [JsonPropertyName("max_rack_inlet_temp")]
    public double MaxRackInletTemp { get; set; }

    [JsonPropertyName("min_supply_air_temp")]
    public double MinSupplyAirTemp { get; set; }
}

public class DigitalTwinPrediction
{
    [JsonPropertyName("predicted_max_rack_inlet_temp")]
    public double PredictedMaxRackInletTemp { get; set; }

    [JsonPropertyName("predicted_pue")]
    public double PredictedPue { get; set; }
}
