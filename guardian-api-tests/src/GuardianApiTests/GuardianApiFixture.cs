using System.Net.Http.Headers;

namespace GuardianApiTests;

/// <summary>
/// Provides a shared GuardianApiClient for tests. Base URL from env GUARDIAN_API_BASE_URL or default.
/// </summary>
public class GuardianApiFixture
{
    public GuardianApiClient Client { get; }

    public GuardianApiFixture()
    {
        var baseUrl = Environment.GetEnvironmentVariable("GUARDIAN_API_BASE_URL")
                      ?? "http://localhost:5000";
        var httpClient = new HttpClient
        {
            BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/"),
            DefaultRequestHeaders = { Accept = { new MediaTypeWithQualityHeaderValue("application/json") } }
        };
        Client = new GuardianApiClient(httpClient);
    }
}
