using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Xunit;

namespace NutritionTracker.IntegrationTests;

public sealed class HabitEndpointTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    [Fact]
    public async Task HydrationAndFastingAppearOnlyInTheCurrentUsersSummary()
    {
        if (!Enabled()) return;

        using var owner = Client($"habit-owner-{Guid.NewGuid():N}");
        using var other = Client($"habit-other-{Guid.NewGuid():N}");
        var now = DateTime.UtcNow;

        (await owner.PostAsJsonAsync("/api/habits/hydration", new
        {
            millilitres = 500m,
            recordedAtUtc = now,
            clientOperationId = Guid.NewGuid().ToString()
        })).StatusCode.Should().Be(HttpStatusCode.Created);
        (await owner.PostAsJsonAsync("/api/habits/fasting", new
        {
            startedAtUtc = now.AddHours(-16),
            endedAtUtc = now,
            clientOperationId = Guid.NewGuid().ToString()
        })).StatusCode.Should().Be(HttpStatusCode.Created);

        using var ownerResponse = await owner.GetAsync("/api/habits/summary?period=daily");
        ownerResponse.StatusCode.Should().Be(HttpStatusCode.OK);
        using var ownerJson = JsonDocument.Parse(await ownerResponse.Content.ReadAsStringAsync());
        ownerJson.RootElement.GetProperty("hydrationMillilitres").GetDecimal().Should().Be(500m);
        ownerJson.RootElement.GetProperty("fastingMinutes").GetInt32().Should().Be(960);

        using var otherResponse = await other.GetAsync("/api/habits/summary?period=daily");
        using var otherJson = JsonDocument.Parse(await otherResponse.Content.ReadAsStringAsync());
        otherJson.RootElement.GetProperty("hydrationMillilitres").GetDecimal().Should().Be(0m);
    }

    [Fact]
    public async Task SummaryRejectsUnknownPeriods()
    {
        if (!Enabled()) return;
        using var client = Client($"habit-period-{Guid.NewGuid():N}");
        (await client.GetAsync("/api/habits/summary?period=yearly")).StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task ActiveFastIsUserScopedAndEndingIsIdempotent()
    {
        if (!Enabled()) return;
        using var owner = Client($"fast-owner-{Guid.NewGuid():N}");
        using var other = Client($"fast-other-{Guid.NewGuid():N}");
        var startKey = Guid.NewGuid().ToString();
        using var started = await owner.PostAsJsonAsync("/api/fasting/start", new { targetDurationMinutes = 720, clientIdempotencyKey = startKey });
        started.StatusCode.Should().Be(HttpStatusCode.Created);
        using var document = JsonDocument.Parse(await started.Content.ReadAsStringAsync());
        var id = document.RootElement.GetProperty("id").GetGuid();
        (await other.GetAsync("/api/fasting/active")).StatusCode.Should().Be(HttpStatusCode.NoContent);
        var endKey = Guid.NewGuid().ToString();
        (await owner.PostAsJsonAsync($"/api/fasting/{id}/end", new { endedAtUtc = DateTime.UtcNow, clientIdempotencyKey = endKey })).StatusCode.Should().Be(HttpStatusCode.OK);
        (await owner.PostAsJsonAsync($"/api/fasting/{id}/end", new { endedAtUtc = DateTime.UtcNow, clientIdempotencyKey = endKey })).StatusCode.Should().Be(HttpStatusCode.OK);
        using var summary = await owner.GetAsync("/api/habits/summary?period=daily");
        using var summaryJson = JsonDocument.Parse(await summary.Content.ReadAsStringAsync());
        summaryJson.RootElement.GetProperty("fastingMinutes").GetInt32().Should().BeGreaterThanOrEqualTo(0);
    }

    [Fact]
    public async Task FastingHistoryIsUserScoped()
    {
        if (!Enabled()) return;
        using var owner = Client($"fast-history-owner-{Guid.NewGuid():N}");
        using var other = Client($"fast-history-other-{Guid.NewGuid():N}");
        (await owner.PostAsJsonAsync("/api/habits/fasting", new { startedAtUtc = DateTime.UtcNow.AddHours(-2), endedAtUtc = DateTime.UtcNow, clientOperationId = Guid.NewGuid().ToString() })).StatusCode.Should().Be(HttpStatusCode.Created);
        using var ownerResponse = await owner.GetAsync("/api/fasting/history");
        using var ownerJson = JsonDocument.Parse(await ownerResponse.Content.ReadAsStringAsync());
        ownerJson.RootElement.GetArrayLength().Should().BeGreaterThan(0);
        using var otherResponse = await other.GetAsync("/api/fasting/history");
        using var otherJson = JsonDocument.Parse(await otherResponse.Content.ReadAsStringAsync());
        otherJson.RootElement.GetArrayLength().Should().Be(0);
    }

    private HttpClient Client(string user)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Development-User-Id", user);
        return client;
    }

    private static bool Enabled() => !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION"));
}
