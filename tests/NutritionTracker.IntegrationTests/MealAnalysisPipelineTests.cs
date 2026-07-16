using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using FluentAssertions;
using Xunit;
namespace NutritionTracker.IntegrationTests;

public sealed class MealAnalysisPipelineTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    [Fact]
    public async Task AnalysePersistsMatchedDraftAndIsolatesReview()
    {
        if (!Enabled()) return; var userA = $"meal-a-{Guid.NewGuid():N}"; var userB = $"meal-b-{Guid.NewGuid():N}"; using var a = Client(userA); using var response = await a.PostAsync("/api/meals/analyse", Form("BengaliLunch", "image/jpeg")); response.StatusCode.Should().Be(HttpStatusCode.Created); using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync()); var root = json.RootElement; root.GetProperty("status").GetString().Should().Be("AwaitingReview"); root.GetProperty("hasImage").GetBoolean().Should().BeTrue(); root.GetProperty("items").GetArrayLength().Should().Be(3); root.GetProperty("totalCalories").GetDecimal().Should().BeGreaterThan(0); var mealId = root.GetProperty("mealId").GetGuid(); (await a.GetAsync($"/api/meals/{mealId}/review")).StatusCode.Should().Be(HttpStatusCode.OK); using var image = await a.GetAsync($"/api/meals/{mealId}/image"); image.StatusCode.Should().Be(HttpStatusCode.OK); image.Content.Headers.ContentType!.MediaType.Should().Be("image/jpeg"); (await image.Content.ReadAsByteArrayAsync()).Should().Equal(0xFF, 0xD8, 0xFF); image.Headers.ETag.Should().NotBeNull(); using var conditional = new HttpRequestMessage(HttpMethod.Get, $"/api/meals/{mealId}/image"); conditional.Headers.IfNoneMatch.Add(image.Headers.ETag!); (await a.SendAsync(conditional)).StatusCode.Should().Be(HttpStatusCode.NotModified); using var b = Client(userB); (await b.GetAsync($"/api/meals/{mealId}/review")).StatusCode.Should().Be(HttpStatusCode.NotFound); (await b.GetAsync($"/api/meals/{mealId}/image")).StatusCode.Should().Be(HttpStatusCode.NotFound);
    }
    [Theory][InlineData("MalformedResponse", "image/jpeg", 502)][InlineData("BengaliLunch", "image/gif", 415)] public async Task InvalidAnalysisMapsToProblemDetails(string scenario, string mime, int expected) { if (!Enabled()) return; using var client = Client($"failure-{Guid.NewGuid():N}"); (await client.PostAsync("/api/meals/analyse", Form(scenario, mime))).StatusCode.Should().Be((HttpStatusCode)expected); }
    [Fact] public async Task MissingIdentityIsRejected() { using var client = factory.CreateClient(); (await client.PostAsync("/api/meals/analyse", Form("BengaliLunch", "image/jpeg"))).StatusCode.Should().Be(HttpStatusCode.Unauthorized); }
    [Fact] public async Task PreflightRejectionReturns422BeforeDraftCreation() { if (!Enabled()) return; using var client = Client($"preflight-{Guid.NewGuid():N}"); using var response = await client.PostAsync("/api/meals/analyse", Form("BengaliLunch", "image/jpeg", [0xFF, 0xD8, 0xFF, 0xEE])); response.StatusCode.Should().Be(HttpStatusCode.UnprocessableEntity); var body = await response.Content.ReadAsStringAsync(); body.Should().Contain("ImagePreflightRejected"); }
    private HttpClient Client(string user) { var client = factory.CreateClient(); client.DefaultRequestHeaders.Add("X-Development-User-Id", user); return client; }
    private static MultipartFormDataContent Form(string scenario, string mime, byte[]? bytes = null) { var form = new MultipartFormDataContent(); var image = new ByteArrayContent(bytes ?? [0xFF, 0xD8, 0xFF]); image.Headers.ContentType = MediaTypeHeaderValue.Parse(mime); form.Add(image, "image", "meal.jpg"); form.Add(new StringContent("en-IN"), "locale"); form.Add(new StringContent("Bengali"), "cuisineHints"); form.Add(new StringContent(scenario), "mockScenario"); return form; }
    private static bool Enabled() => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION"));
}
