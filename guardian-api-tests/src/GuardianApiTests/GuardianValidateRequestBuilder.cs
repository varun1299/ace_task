using GuardianApiTests.Models;

namespace GuardianApiTests;

/// <summary>
/// Fluent builder for GuardianValidateRequest to keep test code readable (specification-by-example style).
/// </summary>
public class GuardianValidateRequestBuilder
{
    private readonly GuardianValidateRequest _request = new();

    public GuardianValidateRequestBuilder()
    {
        _request.Timestamp = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");
    }

    public GuardianValidateRequestBuilder WithZone(string zoneId)
    {
        _request.ZoneId = zoneId;
        return this;
    }

    public GuardianValidateRequestBuilder WithCurrentState(double supplyAirTemp, double returnAirTemp, double maxRackInletTemp, double pue)
    {
        _request.CurrentState = new CurrentState
        {
            SupplyAirTemp = supplyAirTemp,
            ReturnAirTemp = returnAirTemp,
            MaxRackInletTemp = maxRackInletTemp,
            Pue = pue
        };
        return this;
    }

    public GuardianValidateRequestBuilder WithRecommendedSupplyAirTemp(double value)
    {
        _request.RecommendedSetpoints = new RecommendedSetpoints { SupplyAirTemp = value };
        return this;
    }

    public GuardianValidateRequestBuilder WithoutRecommendedSetpoints()
    {
        _request.RecommendedSetpoints = null;
        return this;
    }

    public GuardianValidateRequestBuilder WithConstraints(double maxSupplyAirTemp, double maxRackInletTemp, double minSupplyAirTemp)
    {
        _request.Constraints = new Constraints
        {
            MaxSupplyAirTemp = maxSupplyAirTemp,
            MaxRackInletTemp = maxRackInletTemp,
            MinSupplyAirTemp = minSupplyAirTemp
        };
        return this;
    }

    public GuardianValidateRequestBuilder WithDigitalTwinPrediction(double predictedMaxRackInletTemp, double predictedPue)
    {
        _request.DigitalTwinPrediction = new DigitalTwinPrediction
        {
            PredictedMaxRackInletTemp = predictedMaxRackInletTemp,
            PredictedPue = predictedPue
        };
        return this;
    }

    /// <summary>
    /// Uses the example request from the API spec as default baseline.
    /// </summary>
    public GuardianValidateRequestBuilder WithExampleBaseline()
    {
        _request.ZoneId = "DC-01";
        _request.Timestamp = "2026-02-20T10:15:00Z";
        _request.CurrentState = new CurrentState
        {
            SupplyAirTemp = 21.5,
            ReturnAirTemp = 29.8,
            MaxRackInletTemp = 26.0,
            Pue = 1.48
        };
        _request.RecommendedSetpoints = new RecommendedSetpoints { SupplyAirTemp = 23.0 };
        _request.Constraints = new Constraints
        {
            MaxSupplyAirTemp = 24.0,
            MaxRackInletTemp = 27.0,
            MinSupplyAirTemp = 18.0
        };
        _request.DigitalTwinPrediction = new DigitalTwinPrediction
        {
            PredictedMaxRackInletTemp = 26.8,
            PredictedPue = 1.42
        };
        return this;
    }

    public GuardianValidateRequest Build() => _request;
}
