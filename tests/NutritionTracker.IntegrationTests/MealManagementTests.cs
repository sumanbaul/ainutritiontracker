using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Xunit;

namespace NutritionTracker.IntegrationTests;

public sealed class MealManagementTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    [Fact]
    public async Task DraftEditsConfirmationHistoryAndDeletionRecalculateTheDailySummary()
    {
        if (!Enabled()) return;

        var user = $"meal-management-{Guid.NewGuid():N}";
        using var client = Client(user);
        var draft = await CreateDraft(client);
        var itemId = draft.GetProperty("items")[0].GetProperty("id").GetGuid();
        var mealId = draft.GetProperty("mealId").GetGuid();

        using var edit = await client.PutAsJsonAsync($"/api/meals/{mealId}/items/{itemId}", new { grams = 200m, preparationMethod = "Boiled" });
        edit.StatusCode.Should().Be(HttpStatusCode.OK);
        using var edited = JsonDocument.Parse(await edit.Content.ReadAsStringAsync());
        edited.RootElement.GetProperty("items").EnumerateArray().Single(x => x.GetProperty("id").GetGuid() == itemId).GetProperty("estimatedGrams").GetDecimal().Should().Be(200m);

        using var corrections = await client.GetAsync($"/api/meals/{mealId}/corrections");
        corrections.StatusCode.Should().Be(HttpStatusCode.OK);
        using var correctionsJson = JsonDocument.Parse(await corrections.Content.ReadAsStringAsync());
        correctionsJson.RootElement.EnumerateArray().Should().Contain(x => x.GetProperty("correctionType").GetString() == "Edited");

        (await client.PostAsync($"/api/meals/{mealId}/confirm", null)).StatusCode.Should().Be(HttpStatusCode.OK);
        using var dashboard = await client.GetAsync($"/api/dashboard/today?date={DateOnly.FromDateTime(DateTime.UtcNow):yyyy-MM-dd}");
        dashboard.StatusCode.Should().Be(HttpStatusCode.OK);
        using var summary = JsonDocument.Parse(await dashboard.Content.ReadAsStringAsync());
        summary.RootElement.GetProperty("mealCount").GetInt32().Should().Be(1);
        summary.RootElement.GetProperty("totalCalories").GetDecimal().Should().BeGreaterThan(0);

        using var history = await client.GetAsync("/api/meals");
        using var historyJson = JsonDocument.Parse(await history.Content.ReadAsStringAsync());
        historyJson.RootElement.EnumerateArray().Should().Contain(x => x.GetProperty("id").GetGuid() == mealId);

        (await client.DeleteAsync($"/api/meals/{mealId}")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        using var afterDelete = await client.GetAsync($"/api/dashboard/today?date={DateOnly.FromDateTime(DateTime.UtcNow):yyyy-MM-dd}");
        using var afterDeleteJson = JsonDocument.Parse(await afterDelete.Content.ReadAsStringAsync());
        afterDeleteJson.RootElement.GetProperty("mealCount").GetInt32().Should().Be(0);
    }

    [Fact]
    public async Task DraftManagementIsIsolatedByUserAndRequiresIdentity()
    {
        if (!Enabled()) return;

        var owner = $"meal-owner-{Guid.NewGuid():N}";
        using var ownerClient = Client(owner);
        var draft = await CreateDraft(ownerClient);
        var mealId = draft.GetProperty("mealId").GetGuid();
        var itemId = draft.GetProperty("items")[0].GetProperty("id").GetGuid();
        using var otherClient = Client($"meal-other-{Guid.NewGuid():N}");

        (await otherClient.PutAsJsonAsync($"/api/meals/{mealId}/items/{itemId}", new { grams = 100m, preparationMethod = "Boiled" })).StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await otherClient.PostAsync($"/api/meals/{mealId}/confirm", null)).StatusCode.Should().Be(HttpStatusCode.NotFound);
        using var anonymous = factory.CreateClient();
        (await anonymous.PostAsync($"/api/meals/{mealId}/confirm", null)).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private static async Task<JsonElement> CreateDraft(HttpClient client)
    {
        using var response = await client.PostAsync("/api/meals/analyse", Form());
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return document.RootElement.Clone();
    }

    private HttpClient Client(string user)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Development-User-Id", user);
        return client;
    }

    private static MultipartFormDataContent Form()
    {
        var form = new MultipartFormDataContent();
        var image = new ByteArrayContent([0xFF, 0xD8, 0xFF]);
        image.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        form.Add(image, "image", "meal.jpg");
        form.Add(new StringContent("en-IN"), "locale");
        form.Add(new StringContent("Bengali"), "cuisineHints");
        form.Add(new StringContent("BengaliLunch"), "mockScenario");
        return form;
    }

    private static bool Enabled() => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION"));
}
