using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using GuardianApiTests.Models;

namespace GuardianApiTests;

/// <summary>
/// Client for ACE Guardian POST /guardian/validate API.
/// </summary>
public class GuardianApiClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
        // No PropertyNamingPolicy - [JsonPropertyName] on models gives snake_case
    };

    public GuardianApiClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public GuardianApiClient(string baseAddress)
    {
        _httpClient = new HttpClient { BaseAddress = new Uri(baseAddress.TrimEnd('/') + "/") };
    }

    public async Task<HttpResponseMessage> ValidateAsync(GuardianValidateRequest request, CancellationToken cancellationToken = default)
    {
        var json = JsonSerializer.Serialize(request, JsonOptions);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        return await _httpClient.PostAsync("guardian/validate", content, cancellationToken);
    }

    public async Task<GuardianValidateResponse?> ValidateAndGetResponseAsync(GuardianValidateRequest request, CancellationToken cancellationToken = default)
    {
        var response = await ValidateAsync(request, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(body))
            return null;
        return JsonSerializer.Deserialize<GuardianValidateResponse>(body, JsonOptions);
    }
}
