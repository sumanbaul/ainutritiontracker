using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using ModelContextProtocol.Client;
using ModelContextProtocol.Protocol;
using NutritionTracker.ImageGate.Mcp;
using Xunit;

namespace NutritionTracker.IntegrationTests;

public sealed class ImageGateMcpTests(ImageGateFactory factory) : IClassFixture<ImageGateFactory>
{
    [Fact]
    public async Task HealthEndpointIsAvailable()
    {
        using var http = factory.CreateClient();
        (await http.GetAsync("/health")).StatusCode.Should().Be(System.Net.HttpStatusCode.OK);
    }

    [Fact]
    public async Task PreflightToolReturnsValidatedJsonWithoutPersistingImage()
    {
        using var http = factory.CreateClient();
        var transport = new HttpClientTransport(new HttpClientTransportOptions
        {
            Endpoint = new Uri(http.BaseAddress!, "/mcp"),
            TransportMode = HttpTransportMode.StreamableHttp
        }, http, ownsHttpClient: false);
        await using var client = await McpClient.CreateAsync(transport);
        var result = await client.CallToolAsync("preflight_image", new Dictionary<string, object?>
        {
            ["mimeType"] = "image/jpeg",
            ["imageBase64"] = Convert.ToBase64String([0xFF, 0xD8, 0xFF])
        });
        result.IsError.Should().NotBe(true);
        var text = result.Content.OfType<TextContentBlock>().Single().Text;
        using var json = JsonDocument.Parse(text);
        json.RootElement.GetProperty("decision").GetString().Should().Be("Accepted");
        json.RootElement.GetProperty("detectorVersion").GetString().Should().Be("ollama-image-gate-v1");
    }
}

public sealed class ImageGateFactory : WebApplicationFactory<NutritionTracker.ImageGate.Mcp.Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<IImageGateModel>();
            services.AddSingleton<IImageGateModel, TestImageGateModel>();
        });
    }
}

internal sealed class TestImageGateModel : IImageGateModel
{
    public Task<ImageGateClassification> ClassifyAsync(string imageBase64, string mimeType, CancellationToken cancellationToken) => Task.FromResult(new ImageGateClassification(true, .98m, .96m, true, []));
}
