using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

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
                new KeyValuePair<string, string?>("MealAnalysis:LocalStorageRoot", Path.Combine(Path.GetTempPath(), "nutrition-tracker-integration-images"))
            ]);
        });
    }
}
