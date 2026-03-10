using System.Text.Json.Serialization;

namespace GuardianApiTests.Models;

/// <summary>
/// Expected response from POST /guardian/validate.
/// Adapt property names to match actual API (e.g. snake_case vs PascalCase).
/// </summary>
public class GuardianValidateResponse
{
    [JsonPropertyName("valid")]
    public bool Valid { get; set; }

    [JsonPropertyName("approved")]
    public bool? Approved { get; set; }

    [JsonPropertyName("validation_result")]
    public string? ValidationResult { get; set; }

    [JsonPropertyName("breaches")]
    public IReadOnlyList<ConstraintBreach>? Breaches { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }
}

public class ConstraintBreach
{
    [JsonPropertyName("constraint")]
    public string? Constraint { get; set; }

    [JsonPropertyName("description")]
    public string? Description { get; set; }
}
