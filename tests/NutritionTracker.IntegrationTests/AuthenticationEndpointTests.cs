using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace NutritionTracker.IntegrationTests;

public sealed class AuthenticationEndpointTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    [Fact]
    public async Task RegisterRefreshLogoutRotatesAndRevokesRefreshTokens()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION"))) return;
        var client = factory.CreateClient();
        var email = $"phase14-{Guid.NewGuid():N}@example.test";
        var registered = await client.PostAsJsonAsync("/api/auth/register", new { email, password = "A-long-test-password!42" });
        registered.StatusCode.Should().Be(HttpStatusCode.OK);
        var first = await registered.Content.ReadFromJsonAsync<TokenResponse>();
        first.Should().NotBeNull(); first!.AccessToken.Should().NotBeNullOrWhiteSpace();
        var refreshed = await client.PostAsJsonAsync("/api/auth/refresh", new { first.RefreshToken });
        refreshed.StatusCode.Should().Be(HttpStatusCode.OK);
        var second = await refreshed.Content.ReadFromJsonAsync<TokenResponse>();
        second!.RefreshToken.Should().NotBe(first.RefreshToken);
        (await client.PostAsJsonAsync("/api/auth/refresh", new { first.RefreshToken })).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        (await client.PostAsJsonAsync("/api/auth/logout", new { second.RefreshToken })).StatusCode.Should().Be(HttpStatusCode.NoContent);
        (await client.PostAsJsonAsync("/api/auth/refresh", new { second.RefreshToken })).StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    private sealed record TokenResponse(string AccessToken, string RefreshToken, DateTime AccessTokenExpiresAtUtc);
}
