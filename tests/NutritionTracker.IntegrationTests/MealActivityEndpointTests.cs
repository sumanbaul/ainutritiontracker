using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Xunit;

namespace NutritionTracker.IntegrationTests;

public sealed class MealActivityEndpointTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    [Fact]
    public async Task ActivityRequiresIdentityAndRejectsUnsafeRanges()
    {
        using var anonymous = factory.CreateClient();
        (await anonymous.GetAsync("/api/meals/activity?fromDate=2026-01-01&toDate=2026-01-02")).StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        using var client = Client($"activity-range-{Guid.NewGuid():N}");
        (await client.GetAsync("/api/meals/activity?fromDate=2025-01-01&toDate=2026-07-13")).StatusCode.Should().Be(HttpStatusCode.BadRequest);
        (await client.GetAsync("/api/meals/activity?fromDate=2026-07-14&toDate=2026-07-13")).StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task ActivityUsesProfileTimezoneAndIncludesOnlyOwnedConfirmedMeals()
    {
        if (!Enabled()) return;
        var user = $"activity-owner-{Guid.NewGuid():N}";
        using var owner = Client(user);
        var profileRequest = new
        {
            name = "Activity Owner",
            dateOfBirth = "1990-09-26",
            biologicalSex = "Male",
            heightCm = 170.18m,
            currentWeightKg = 75m,
            targetWeightKg = 70m,
            activityLevel = "ModeratelyActive",
            goalType = "LoseWeightSlowly",
            dietPreference = "NonVegetarian",
            preferredMeasurementSystem = "Metric",
            timezone = "Asia/Kolkata"
        };
        using var profile = await owner.PostAsJsonAsync("/api/profile", profileRequest);
        profile.StatusCode.Should().Be(HttpStatusCode.Created);

        var confirmedId = await CreateDraft(owner, "2026-07-12T20:30:00Z");
        (await owner.PostAsync($"/api/meals/{confirmedId}/confirm", null)).StatusCode.Should().Be(HttpStatusCode.OK);
        _ = await CreateDraft(owner, "2026-07-13T02:00:00Z");
        var deletedId = await CreateDraft(owner, "2026-07-13T03:00:00Z");
        (await owner.PostAsync($"/api/meals/{deletedId}/confirm", null)).StatusCode.Should().Be(HttpStatusCode.OK);
        (await owner.DeleteAsync($"/api/meals/{deletedId}")).StatusCode.Should().Be(HttpStatusCode.NoContent);

        using var updatedProfile = await owner.PutAsJsonAsync("/api/profile", new
        {
            profileRequest.name,
            profileRequest.dateOfBirth,
            profileRequest.biologicalSex,
            profileRequest.heightCm,
            profileRequest.currentWeightKg,
            profileRequest.targetWeightKg,
            activityLevel = "Sedentary",
            profileRequest.goalType,
            profileRequest.dietPreference,
            profileRequest.preferredMeasurementSystem,
            profileRequest.timezone
        });
        updatedProfile.StatusCode.Should().Be(HttpStatusCode.OK);
        using var updatedJson = JsonDocument.Parse(await updatedProfile.Content.ReadAsStringAsync());
        var latestTarget = updatedJson.RootElement.GetProperty("currentNutritionTarget").GetProperty("targetCalories").GetDecimal();

        using var response = await owner.GetAsync("/api/meals/activity?fromDate=2026-07-13&toDate=2026-07-13");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        json.RootElement.GetProperty("timezone").GetString().Should().Be("Asia/Kolkata");
        var day = json.RootElement.GetProperty("days")[0];
        day.GetProperty("mealCount").GetInt32().Should().Be(1);
        day.GetProperty("calories").GetDecimal().Should().BeGreaterThan(0);
        day.GetProperty("targetCalories").GetDecimal().Should().Be(latestTarget);
        day.GetProperty("adherencePercent").GetDecimal().Should().BeGreaterThan(0);

        using var other = Client($"activity-other-{Guid.NewGuid():N}");
        using var isolated = JsonDocument.Parse(await (await other.GetAsync("/api/meals/activity?fromDate=2026-07-13&toDate=2026-07-13")).Content.ReadAsStringAsync());
        isolated.RootElement.GetProperty("days")[0].GetProperty("mealCount").GetInt32().Should().Be(0);
    }

    private static async Task<Guid> CreateDraft(HttpClient client, string consumedAtUtc)
    {
        using var response = await client.PostAsync("/api/meals/analyse", Form(consumedAtUtc));
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return json.RootElement.GetProperty("mealId").GetGuid();
    }

    private HttpClient Client(string user)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Development-User-Id", user);
        return client;
    }

    private static MultipartFormDataContent Form(string consumedAtUtc)
    {
        var form = new MultipartFormDataContent();
        var image = new ByteArrayContent([0xFF, 0xD8, 0xFF]);
        image.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        form.Add(image, "image", "activity.jpg");
        form.Add(new StringContent("en-IN"), "locale");
        form.Add(new StringContent("BengaliLunch"), "mockScenario");
        form.Add(new StringContent(consumedAtUtc), "consumedAtUtc");
        return form;
    }

    private static bool Enabled() => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION"));
}
