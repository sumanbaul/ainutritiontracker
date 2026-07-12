using System.Net;
using System.Text;
using FluentAssertions;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Infrastructure.MealVision;
using Xunit;

namespace NutritionTracker.UnitTests;

public sealed class OpenAiMealVisionProviderTests
{
    [Fact]
    public async Task SendsImageAsDataUrlAndParsesStructuredResponse()
    {
        var handler = new RecordingHandler(HttpStatusCode.OK, """
        {"id":"resp_test","model":"gpt-5.4-mini","output_text":"{\"containsFood\":true,\"mealName\":\"Lunch\",\"mealTypeSuggestion\":\"Lunch\",\"imageQuality\":{\"acceptable\":true,\"score\":0.9,\"issues\":[]},\"items\":[{\"detectedName\":\"rice\",\"regionalName\":null,\"categoryHint\":null,\"preparationMethod\":\"Boiled\",\"estimatedQuantity\":1,\"estimatedUnit\":\"Cup\",\"estimatedGrams\":150,\"recognitionConfidence\":0.9,\"portionConfidence\":0.8,\"alternatives\":[],\"visibleIngredients\":[],\"possibleHiddenIngredients\":[]}],\"clarificationQuestions\":[]}"}
        """);
        var provider = Provider(handler);

        var result = await provider.AnalyseAsync(Request(), CancellationToken.None);

        result.ContainsFood.Should().BeTrue();
        result.Items.Should().ContainSingle().Which.DetectedName.Should().Be("rice");
        handler.Body.Should().Contain("data:image/jpeg;base64,/9j/");
        handler.Authorization.Should().Be("Bearer test-key");
    }

    [Theory]
    [InlineData(HttpStatusCode.Unauthorized, ProviderFailureType.Authentication)]
    [InlineData((HttpStatusCode)429, ProviderFailureType.RateLimited)]
    public async Task MapsProviderHttpFailures(HttpStatusCode status, ProviderFailureType expected)
    {
        var action = () => Provider(new RecordingHandler(status, "{}"))
            .AnalyseAsync(Request(), CancellationToken.None);
        var error = await action.Should().ThrowAsync<MealVisionProviderException>();
        error.Which.FailureType.Should().Be(expected);
    }

    private static OpenAiMealVisionProvider Provider(HttpMessageHandler handler) => new(new HttpClient(handler) { BaseAddress = new Uri("https://api.openai.com/v1/") }, Options.Create(new MealVisionOptions
    {
        OpenAi = new OpenAiMealVisionOptions { ApiKey = "test-key", Model = "gpt-5.4-mini" }
    }));

    private static MealVisionProviderRequest Request() => new([0xFF, 0xD8, 0xFF], "image/jpeg", new("System", "Find food", "v1", "1.0"), "en-IN", [], null, 20, null);

    private sealed class RecordingHandler(HttpStatusCode status, string response) : HttpMessageHandler
    {
        public string? Body { get; private set; }
        public string? Authorization { get; private set; }
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            Authorization = request.Headers.Authorization?.ToString();
            Body = request.Content is null ? null : await request.Content.ReadAsStringAsync(cancellationToken);
            return new HttpResponseMessage(status) { Content = new StringContent(response, Encoding.UTF8, "application/json") };
        }
    }
}
