using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Configuration;
using NutritionTracker.Application.MealVision;

namespace NutritionTracker.IntegrationTests;

public sealed class FoundationApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureAppConfiguration((_, configurationBuilder) =>
        {
            var integrationConnection = Environment.GetEnvironmentVariable("NUTRITION_TRACKER_INTEGRATION_CONNECTION");
            configurationBuilder.AddInMemoryCollection(
            [
                new KeyValuePair<string, string?>("ConnectionStrings:DefaultConnection", integrationConnection ?? "Host=localhost;Port=5432;Database=nutrition_tracker_tests;Username=test;Password=test"),
                new KeyValuePair<string, string?>("HealthChecks:EnableDatabaseReadinessCheck", "false"),
                new KeyValuePair<string, string?>("FoodSeed:Enabled", integrationConnection is null ? "false" : "true"),
                new KeyValuePair<string, string?>("MealVision:Preflight:Enabled", "true"),
                new KeyValuePair<string, string?>("MealVision:Preflight:FailClosed", "false"),
                new KeyValuePair<string, string?>("MealVision:Preflight:AllowUncertainInDevelopment", "true"),
                new KeyValuePair<string, string?>("MealAnalysis:LocalStorageRoot", Path.Combine(Path.GetTempPath(), "nutrition-tracker-integration-images"))
            ]);
        });
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<IImagePreflightDetector>();
            services.AddSingleton<IImagePreflightDetector, TestImagePreflightDetector>();
        });
    }
}

internal sealed class TestImagePreflightDetector : IImagePreflightDetector
{
    public Task<ImagePreflightResult> DetectAsync(byte[] imageBytes, string mimeType, CancellationToken cancellationToken)
    {
        var decision = imageBytes.Length > 3 && imageBytes[3] == 0xEE ? ImagePreflightDecision.Rejected : imageBytes.Length > 3 && imageBytes[3] == 0xED ? ImagePreflightDecision.Uncertain : ImagePreflightDecision.Accepted;
        var issues = decision == ImagePreflightDecision.Rejected ? new[] { "NonFoodImage" } : Array.Empty<string>();
        return Task.FromResult(new ImagePreflightResult(decision, decision == ImagePreflightDecision.Rejected ? .05m : .95m, decision == ImagePreflightDecision.Rejected ? .10m : .95m, decision != ImagePreflightDecision.Rejected, issues, "test-preflight", 1));
    }
}
