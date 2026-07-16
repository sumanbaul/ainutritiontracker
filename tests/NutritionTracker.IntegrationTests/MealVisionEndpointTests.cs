using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Xunit;
namespace NutritionTracker.IntegrationTests;

public sealed class MealVisionEndpointTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    private static readonly string[] PreferredLanguages = ["bn", "en"];
    private static readonly string[] CuisineHints = ["Bengali"];
    [Fact] public async Task BengaliLunchReturnsStructuredNonNutritionalResult() { using var client = Client(); var response = await client.PostAsJsonAsync("/api/development/meal-vision/analyse", Request("BengaliLunch")); response.StatusCode.Should().Be(HttpStatusCode.OK); using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync()); var root = json.RootElement; root.GetProperty("containsFood").GetBoolean().Should().BeTrue(); root.GetProperty("mealName").GetString().Should().Be("Bengali lunch"); root.GetProperty("promptVersion").GetString().Should().Be("v1"); root.GetProperty("schemaVersion").GetString().Should().Be("1.0"); root.GetRawText().Should().NotContain("calories").And.NotContain("proteinGrams"); }
    [Theory][InlineData("NoFood", 200)][InlineData("MalformedResponse", 502)][InlineData("ProviderTimeout", 504)][InlineData("ProviderFailure", 502)] public async Task MockScenariosMapDeterministically(string scenario, int status) { using var client = Client(); (await client.PostAsJsonAsync("/api/development/meal-vision/analyse", Request(scenario))).StatusCode.Should().Be((HttpStatusCode)status); }
    [Fact] public async Task DevelopmentEndpointMapsPreflightRejectionTo422() { using var client = Client(); var request = Request("BengaliLunch") with { ImageBase64 = Convert.ToBase64String([0xFF, 0xD8, 0xFF, 0xEE]) }; (await client.PostAsJsonAsync("/api/development/meal-vision/analyse", request)).StatusCode.Should().Be(HttpStatusCode.UnprocessableEntity); }
    [Fact] public async Task MissingIdentityIsRejected() { using var client = factory.CreateClient(); (await client.PostAsJsonAsync("/api/development/meal-vision/analyse", Request("NoFood"))).StatusCode.Should().Be(HttpStatusCode.Unauthorized); }
    [Fact] public async Task UnsupportedMimeIsRejected() { using var client = Client(); var request = Request("NoFood") with { MimeType = "image/gif" }; (await client.PostAsJsonAsync("/api/development/meal-vision/analyse", request)).StatusCode.Should().Be(HttpStatusCode.UnsupportedMediaType); }
    private HttpClient Client() { var client = factory.CreateClient(); client.DefaultRequestHeaders.Add("X-Development-User-Id", "vision-test-user"); return client; }
    private static RequestModel Request(string scenario) => new(Convert.ToBase64String([0xFF, 0xD8, 0xFF]), "image/jpeg", "meal.jpg", "en-IN", PreferredLanguages, CuisineHints, scenario);
    private sealed record RequestModel(string ImageBase64, string MimeType, string FileName, string Locale, string[] PreferredLanguages, string[] CuisineHints, string MockScenario);
}
