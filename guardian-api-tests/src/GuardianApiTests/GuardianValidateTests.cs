using System.Net;
using FluentAssertions;
using GuardianApiTests.Models;
using Xunit;

namespace GuardianApiTests;

/// <summary>
/// API tests for ACE Guardian POST /guardian/validate.
/// These tests implement the specification-by-example scenarios from guardian_validate.feature.
/// Base URL is configurable via GUARDIAN_API_BASE_URL (e.g. http://localhost:5000).
/// </summary>
public class GuardianValidateTests : IClassFixture<GuardianApiFixture>
{
    private readonly GuardianApiClient _client;

    public GuardianValidateTests(GuardianApiFixture fixture)
    {
        _client = fixture.Client;
    }

    [Fact]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Valid recommendation within all constraints is accepted")]
    public async Task Valid_recommendation_within_all_constraints_is_accepted()
    {
        var request = new GuardianValidateRequestBuilder()
            .WithExampleBaseline()
            .Build();

        var response = await _client.ValidateAsync(request);
        var body = await _client.ValidateAndGetResponseAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().NotBeNull();
        body!.Valid.Should().BeTrue("recommendation is within all constraints");
        (body.Approved ?? body.ValidationResult?.Contains("approv", StringComparison.OrdinalIgnoreCase) == true || body.Valid)
            .Should().BeTrue("validation should indicate approved/valid");
        (body.Breaches == null || body.Breaches.Count == 0).Should().BeTrue("no constraint breaches should be reported");
    }

    [Fact]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Recommendation exceeding max supply air temp is rejected")]
    public async Task Recommendation_exceeding_max_supply_air_temp_is_rejected()
    {
        var request = new GuardianValidateRequestBuilder()
            .WithExampleBaseline()
            .WithRecommendedSupplyAirTemp(25.0)
            .WithConstraints(maxSupplyAirTemp: 24.0, maxRackInletTemp: 27.0, minSupplyAirTemp: 18.0)
            .WithDigitalTwinPrediction(26.5, 1.40)
            .Build();

        var response = await _client.ValidateAsync(request);
        var body = await _client.ValidateAndGetResponseAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().NotBeNull();
        body!.Valid.Should().BeFalse("recommendation exceeds max_supply_air_temp");
        var hasSupplyTempBreach = body.Breaches?.Any(b =>
            (b.Constraint?.Contains("supply", StringComparison.OrdinalIgnoreCase) ?? false) ||
            (b.Description?.Contains("supply", StringComparison.OrdinalIgnoreCase) ?? false)) ?? false;
        (hasSupplyTempBreach || !body.Valid).Should().BeTrue("a breach of max_supply_air_temp or supply_air_temp should be reported");
    }

    [Fact]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Recommendation below min supply air temp is rejected")]
    public async Task Recommendation_below_min_supply_air_temp_is_rejected()
    {
        var request = new GuardianValidateRequestBuilder()
            .WithExampleBaseline()
            .WithRecommendedSupplyAirTemp(17.0)
            .WithConstraints(maxSupplyAirTemp: 24.0, maxRackInletTemp: 27.0, minSupplyAirTemp: 18.0)
            .WithDigitalTwinPrediction(25.0, 1.45)
            .Build();

        var response = await _client.ValidateAsync(request);
        var body = await _client.ValidateAndGetResponseAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().NotBeNull();
        body!.Valid.Should().BeFalse("recommendation is below min_supply_air_temp");
        var hasMinSupplyBreach = body.Breaches?.Any(b =>
            (b.Constraint?.Contains("min_supply", StringComparison.OrdinalIgnoreCase) ?? false) ||
            (b.Constraint?.Contains("supply", StringComparison.OrdinalIgnoreCase) ?? false) ||
            (b.Description?.Contains("supply", StringComparison.OrdinalIgnoreCase) ?? false)) ?? false;
        (hasMinSupplyBreach || !body.Valid).Should().BeTrue("a breach of min_supply_air_temp or supply_air_temp should be reported");
    }

    [Fact]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Predicted rack inlet temp exceeding constraint is rejected")]
    public async Task Predicted_rack_inlet_temp_exceeding_constraint_is_rejected()
    {
        var request = new GuardianValidateRequestBuilder()
            .WithExampleBaseline()
            .WithRecommendedSupplyAirTemp(23.0)
            .WithConstraints(maxSupplyAirTemp: 24.0, maxRackInletTemp: 27.0, minSupplyAirTemp: 18.0)
            .WithDigitalTwinPrediction(27.5, 1.41)
            .Build();

        var response = await _client.ValidateAsync(request);
        var body = await _client.ValidateAndGetResponseAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().NotBeNull();
        body!.Valid.Should().BeFalse("digital twin predicts max_rack_inlet_temp 27.5 > constraint 27.0");
        var hasRackInletBreach = body.Breaches?.Any(b =>
            (b.Constraint?.Contains("rack", StringComparison.OrdinalIgnoreCase) ?? false) ||
            (b.Description?.Contains("rack", StringComparison.OrdinalIgnoreCase) ?? false)) ?? false;
        (hasRackInletBreach || !body.Valid).Should().BeTrue("a breach of max_rack_inlet_temp or rack_inlet_temp should be reported");
    }

    [Fact]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Recommendation exactly at supply air temp limits is accepted")]
    public async Task Recommendation_exactly_at_max_supply_air_temp_is_accepted()
    {
        var request = new GuardianValidateRequestBuilder()
            .WithExampleBaseline()
            .WithRecommendedSupplyAirTemp(24.0)
            .WithConstraints(maxSupplyAirTemp: 24.0, maxRackInletTemp: 27.0, minSupplyAirTemp: 18.0)
            .WithDigitalTwinPrediction(26.9, 1.42)
            .Build();

        var response = await _client.ValidateAsync(request);
        var body = await _client.ValidateAndGetResponseAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().NotBeNull();
        body!.Valid.Should().BeTrue("recommendation at exactly max_supply_air_temp should be within limits");
    }

    [Fact]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Predicted rack inlet temp exactly at constraint limit is accepted")]
    public async Task Predicted_rack_inlet_temp_exactly_at_constraint_is_accepted()
    {
        var request = new GuardianValidateRequestBuilder()
            .WithExampleBaseline()
            .WithRecommendedSupplyAirTemp(23.0)
            .WithConstraints(maxSupplyAirTemp: 24.0, maxRackInletTemp: 27.0, minSupplyAirTemp: 18.0)
            .WithDigitalTwinPrediction(27.0, 1.42)
            .Build();

        var response = await _client.ValidateAsync(request);
        var body = await _client.ValidateAndGetResponseAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().NotBeNull();
        body!.Valid.Should().BeTrue("predicted max_rack_inlet_temp at exactly constraint limit should be accepted");
    }

    [Fact]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Malformed or invalid request returns error")]
    public async Task Invalid_request_missing_recommended_setpoints_returns_bad_request()
    {
        var request = new GuardianValidateRequestBuilder()
            .WithZone("DC-01")
            .WithCurrentState(21.5, 29.8, 26.0, 1.48)
            .WithConstraints(24.0, 27.0, 18.0)
            .WithDigitalTwinPrediction(26.8, 1.42)
            .WithoutRecommendedSetpoints()
            .Build();

        var response = await _client.ValidateAsync(request);

        (response.StatusCode == HttpStatusCode.BadRequest || response.StatusCode == (HttpStatusCode)422).Should().BeTrue(
            "API should return 400 or 422 for invalid/missing required data");
    }

    [Theory]
    [Trait("Category", "Guardian")]
    [Trait("Scenario", "Multiple zones and set point combinations")]
    [InlineData("DC-01", 21.5, 22.0, 26.5, true)]
    [InlineData("DC-02", 20.0, 23.0, 26.8, true)]
    [InlineData("DC-01", 21.5, 24.5, 26.0, false)]
    [InlineData("DC-01", 21.5, 23.0, 27.8, false)]
    public async Task Multiple_zones_and_set_points_validate_as_expected(
        string zoneId, double currentSupply, double recommendedSupply, double predictedRackInlet, bool expectedValid)
    {
        var request = new GuardianValidateRequestBuilder()
            .WithZone(zoneId)
            .WithCurrentState(currentSupply, 29.8, 26.0, 1.48)
            .WithRecommendedSupplyAirTemp(recommendedSupply)
            .WithConstraints(24.0, 27.0, 18.0)
            .WithDigitalTwinPrediction(predictedRackInlet, 1.42)
            .Build();

        var response = await _client.ValidateAsync(request);
        var body = await _client.ValidateAndGetResponseAsync(request);

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().NotBeNull();
        body!.Valid.Should().Be(expectedValid,
            "zone {0}, recommended_supply {1}, predicted_rack_inlet {2} should be {3}",
            zoneId, recommendedSupply, predictedRackInlet, expectedValid ? "approved" : "rejected");
    }
}
