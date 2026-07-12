using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace NutritionTracker.IntegrationTests;

public sealed class ProfilePersistenceTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    [Fact]
    public async Task ProfileAndWeightArePersistedAndIsolatedByDevelopmentIdentity()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION")))
        {
            return;
        }

        var userA = $"postgres-test-a-{Guid.NewGuid():N}";
        var userB = $"postgres-test-b-{Guid.NewGuid():N}";
        using var a = factory.CreateClient();
        using var b = factory.CreateClient();
        a.DefaultRequestHeaders.Add("X-Development-User-Id", userA);
        b.DefaultRequestHeaders.Add("X-Development-User-Id", userB);
        var profile = new { name = "Integration Test", dateOfBirth = "1990-09-26", biologicalSex = "Male", heightCm = 170m, currentWeightKg = 75m, targetWeightKg = 70m, activityLevel = "ModeratelyActive", goalType = "LoseWeightSlowly", dietPreference = "NonVegetarian", preferredMeasurementSystem = "Metric", timezone = "Asia/Kolkata" };
        (await a.PostAsJsonAsync("/api/profile", profile)).StatusCode.Should().Be(HttpStatusCode.Created);
        (await a.PostAsJsonAsync("/api/weight", new { weightKg = 74m, recordedAtUtc = DateTime.UtcNow, notes = "PostgreSQL integration test" })).StatusCode.Should().Be(HttpStatusCode.Created);
        (await a.GetAsync("/api/profile")).StatusCode.Should().Be(HttpStatusCode.OK);
        var weights = await a.GetStringAsync("/api/weight"); weights.Should().Contain("74");
        (await b.GetAsync("/api/profile")).StatusCode.Should().Be(HttpStatusCode.NotFound);
        (await b.GetAsync("/api/weight")).StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
