using System.Net;
using FluentAssertions;
using Xunit;

namespace NutritionTracker.IntegrationTests;

public sealed class HealthEndpointTests(FoundationApiFactory factory) : IClassFixture<FoundationApiFactory>
{
    [Fact]
    public async Task HealthEndpointWhenApplicationStartsReturnsHealthy()
    {
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/health");

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        (await response.Content.ReadAsStringAsync()).Should().Be("Healthy");
    }
}
