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
    public async Task UnresolvedDraftItemCanBeResolvedWithCatalogFoodAndConfirmed()
    {
        if (!Enabled()) return;

        using var client = Client($"unresolved-{Guid.NewGuid():N}");
        using var response = await client.PostAsync("/api/meals/analyse", Form("AmbiguousFishCurry"));
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        using var draft = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = draft.RootElement;
        var mealId = root.GetProperty("mealId").GetGuid();
        var itemId = root.GetProperty("items")[0].GetProperty("id").GetGuid();
        root.GetProperty("items")[0].GetProperty("nutritionMatchState").GetString().Should().Be("Unresolved");

        using var search = await client.GetAsync("/api/foods/search?q=rohu%20fish%20curry");
        search.StatusCode.Should().Be(HttpStatusCode.OK);
        using var searchJson = JsonDocument.Parse(await search.Content.ReadAsStringAsync());
        var foodId = searchJson.RootElement[0].GetProperty("id").GetGuid();

        using var edit = await client.PutAsJsonAsync($"/api/meals/{mealId}/items/{itemId}", new
        {
            foodId,
            grams = 180m,
            preparationMethod = "Curried"
        });
        edit.StatusCode.Should().Be(HttpStatusCode.OK);
        using var edited = JsonDocument.Parse(await edit.Content.ReadAsStringAsync());
        var editedItem = edited.RootElement.GetProperty("items")[0];
        editedItem.GetProperty("foodId").GetGuid().Should().Be(foodId);
        editedItem.GetProperty("nutritionMatchState").GetString().Should().NotBe("Unresolved");
        editedItem.GetProperty("calories").GetDecimal().Should().BeGreaterThan(0);
        (await client.PostAsync($"/api/meals/{mealId}/confirm", null)).StatusCode.Should().Be(HttpStatusCode.OK);
    }

    [Fact]
    public async Task FoodResolutionReturnsOnlyOwnedCatalogSuggestions()
    {
        if (!Enabled()) return;

        using var client = Client($"resolver-{Guid.NewGuid():N}");
        using var response = await client.PostAsync("/api/meals/analyse", Form("AmbiguousFishCurry"));
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        using var draft = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var mealId = draft.RootElement.GetProperty("mealId").GetGuid();
        var itemId = draft.RootElement.GetProperty("items")[0].GetProperty("id").GetGuid();

        using var suggestions = await client.PostAsJsonAsync($"/api/meals/{mealId}/items/{itemId}/resolve", new { });
        suggestions.StatusCode.Should().Be(HttpStatusCode.OK);
        using var suggestionsJson = JsonDocument.Parse(await suggestions.Content.ReadAsStringAsync());
        suggestionsJson.RootElement.GetProperty("suggestions").EnumerateArray()
            .Should().OnlyContain(x => x.GetProperty("foodId").GetGuid() != Guid.Empty);
    }

    [Fact]
    public async Task UnrelatedCatalogFoodIsRejectedAndReviewedEstimateIsPrivate()
    {
        if (!Enabled()) return;
        var owner = $"estimate-owner-{Guid.NewGuid():N}";
        using var client = Client(owner);
        using var response = await client.PostAsync("/api/meals/analyse", Form("AmbiguousFishCurry"));
        using var draft = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var mealId = draft.RootElement.GetProperty("mealId").GetGuid();
        var itemId = draft.RootElement.GetProperty("items")[0].GetProperty("id").GetGuid();

        using var catalog = await client.PostAsJsonAsync($"/api/meals/{mealId}/items/{itemId}/resolve", new { query = "Pickle", mode = "CatalogMatch", providerId = "Mock" });
        catalog.StatusCode.Should().Be(HttpStatusCode.OK);
        using var catalogJson = JsonDocument.Parse(await catalog.Content.ReadAsStringAsync());
        catalogJson.RootElement.GetProperty("suggestions").GetArrayLength().Should().Be(0);
        catalogJson.RootElement.GetProperty("noMatchReason").GetString().Should().Contain("No catalog food");

        using var estimate = await client.PostAsJsonAsync($"/api/meals/{mealId}/items/{itemId}/resolve", new { query = "Pickle", mode = "NutritionEstimate", providerId = "Mock" });
        estimate.StatusCode.Should().Be(HttpStatusCode.OK);
        using var estimateJson = JsonDocument.Parse(await estimate.Content.ReadAsStringAsync());
        var token = estimateJson.RootElement.GetProperty("estimate").GetProperty("estimateToken").GetString();
        token.Should().NotBeNullOrWhiteSpace();

        using var confirmed = await client.PostAsJsonAsync($"/api/meals/{mealId}/items/{itemId}/resolve/estimate/confirm", new
        {
            estimateToken = token,
            name = "Pickle",
            description = "Reviewed AI estimate",
            category = "Condiment",
            cuisine = "General",
            preparationMethod = "Mixed",
            foodState = "Prepared",
            nutritionPer100Grams = new { calories = 150m, protein = 1m, carbohydrates = 10m, fat = 12m, fibre = 2m, sugar = 5m, sodiumMilligrams = 1200m },
            grams = 15m
        });
        confirmed.StatusCode.Should().Be(HttpStatusCode.OK);
        using var confirmedJson = JsonDocument.Parse(await confirmed.Content.ReadAsStringAsync());
        confirmedJson.RootElement.GetProperty("items")[0].GetProperty("nutritionMatchState").GetString().Should().NotBe("Unresolved");

        using var ownerSearch = await client.GetAsync("/api/foods/search?q=Pickle");
        using var ownerSearchJson = JsonDocument.Parse(await ownerSearch.Content.ReadAsStringAsync());
        ownerSearchJson.RootElement.EnumerateArray().Should().Contain(x => x.GetProperty("isEstimate").GetBoolean());
        using var other = Client($"estimate-other-{Guid.NewGuid():N}");
        using var otherSearch = await other.GetAsync("/api/foods/search?q=Pickle");
        using var otherSearchJson = JsonDocument.Parse(await otherSearch.Content.ReadAsStringAsync());
        otherSearchJson.RootElement.GetArrayLength().Should().Be(0);
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
        using var response = await client.PostAsync("/api/meals/analyse", Form("BengaliLunch"));
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

    private static MultipartFormDataContent Form(string scenario)
    {
        var form = new MultipartFormDataContent();
        var image = new ByteArrayContent([0xFF, 0xD8, 0xFF]);
        image.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        form.Add(image, "image", "meal.jpg");
        form.Add(new StringContent("en-IN"), "locale");
        form.Add(new StringContent("Bengali"), "cuisineHints");
        form.Add(new StringContent(scenario), "mockScenario");
        return form;
    }

    private static bool Enabled() => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION"));
}
