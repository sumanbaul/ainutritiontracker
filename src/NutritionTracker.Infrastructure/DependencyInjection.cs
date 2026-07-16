using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using NutritionTracker.Infrastructure.Configuration;
using NutritionTracker.Infrastructure.Persistence;
using NutritionTracker.Infrastructure.Profiles;
using NutritionTracker.Application.Nutrition;
using NutritionTracker.Application.Profiles;
using NutritionTracker.Application.Foods;
using NutritionTracker.Infrastructure.Foods;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Infrastructure.MealVision;
using NutritionTracker.Application.Meals;
using NutritionTracker.Infrastructure.Meals;

namespace NutritionTracker.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<NutritionCalculationOptions>().Bind(configuration.GetSection(NutritionCalculationOptions.SectionName)).Validate(x => x.MinimumSupportedAge > 0 && x.MaximumSupportedAge > x.MinimumSupportedAge && x.FatPercentage > 0 && x.MinimumFatGramsPerKg > 0 && x.ActivityMultipliers.Count == 5 && x.GoalCalorieAdjustments.Count >= 5 && x.ProteinMultipliers.Count >= 5, "NutritionCalculation is incomplete or invalid.").ValidateOnStart();
        services.AddSingleton(serviceProvider => serviceProvider.GetRequiredService<IOptions<NutritionCalculationOptions>>().Value);
        services
            .AddOptions<DatabaseOptions>()
            .Bind(configuration.GetSection(DatabaseOptions.SectionName))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services.AddDbContext<NutritionTrackerDbContext>((serviceProvider, options) =>
        {
            var databaseOptions = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;
            options.UseNpgsql(databaseOptions.DefaultConnection);
        });
        services.AddScoped<IProfileService, ProfileService>();
        services.AddScoped<IFoodService, FoodService>();
        services.AddOptions<MealVisionOptions>().Bind(configuration.GetSection(MealVisionOptions.SectionName)).Validate(x => x.RequestTimeoutSeconds is >= 1 and <= 300 && x.MaximumImageBytes is >= 1024 and <= 20_000_000 && x.MaximumItems is >= 1 and <= 50 && x.MinimumRecognitionConfidence is >= 0 and <= 1 && x.MinimumPortionConfidence is >= 0 and <= 1 && !string.IsNullOrWhiteSpace(x.PromptVersion) && !string.IsNullOrWhiteSpace(x.SchemaVersion) && (x.Provider != MealVisionProviderKind.OpenAi || (!string.IsNullOrWhiteSpace(x.OpenAi.ApiKey) && Uri.TryCreate(x.OpenAi.Endpoint, UriKind.Absolute, out _) && !string.IsNullOrWhiteSpace(x.OpenAi.Model) && x.OpenAi.MaxOutputTokens is >= 256 and <= 8_000)), "MealVision configuration is invalid. Configure credentials only in user secrets or environment variables.").ValidateOnStart();
        services.AddSingleton<IMealVisionProvider, MockMealVisionProvider>();
        services.AddHttpClient<OpenAiMealVisionProvider>((serviceProvider, client) =>
        {
            var options = serviceProvider.GetRequiredService<IOptions<MealVisionOptions>>().Value.OpenAi;
            client.BaseAddress = new Uri(options.Endpoint, UriKind.Absolute);
            client.Timeout = Timeout.InfiniteTimeSpan;
        });
        services.AddSingleton<IMealVisionProvider>(serviceProvider => serviceProvider.GetRequiredService<OpenAiMealVisionProvider>());
        services.AddHttpClient<OllamaMealVisionProvider>((serviceProvider, client) =>
        {
            client.BaseAddress = new Uri(serviceProvider.GetRequiredService<IOptions<MealVisionOptions>>().Value.Ollama.Endpoint, UriKind.Absolute);
            client.Timeout = Timeout.InfiniteTimeSpan;
        });
        services.AddSingleton<IMealVisionProvider>(serviceProvider => serviceProvider.GetRequiredService<OllamaMealVisionProvider>());
        services.AddHttpClient<GeminiMealVisionProvider>((sp, client) => { client.BaseAddress = new Uri(sp.GetRequiredService<IOptions<MealVisionOptions>>().Value.Gemini.Endpoint); client.Timeout = Timeout.InfiniteTimeSpan; });
        services.AddSingleton<IMealVisionProvider>(sp => sp.GetRequiredService<GeminiMealVisionProvider>());
        services.AddHttpClient<AnthropicMealVisionProvider>((sp, client) => { client.BaseAddress = new Uri(sp.GetRequiredService<IOptions<MealVisionOptions>>().Value.Anthropic.Endpoint); client.Timeout = Timeout.InfiniteTimeSpan; });
        services.AddSingleton<IMealVisionProvider>(sp => sp.GetRequiredService<AnthropicMealVisionProvider>());
        services.AddHttpClient<OpenAiCompatibleMealVisionProvider>((sp, client) => { var endpoint = sp.GetRequiredService<IOptions<MealVisionOptions>>().Value.OpenAiCompatible.Endpoint; if (Uri.TryCreate(endpoint, UriKind.Absolute, out var uri)) client.BaseAddress = uri; client.Timeout = Timeout.InfiniteTimeSpan; });
        services.AddSingleton<IMealVisionProvider>(sp => sp.GetRequiredService<OpenAiCompatibleMealVisionProvider>());
        services.AddSingleton<IMealVisionProviderCatalog, MealVisionProviderCatalog>();
        services.AddSingleton<IMealVisionProviderResolver, MealVisionProviderResolver>();
        services.AddSingleton<IMealVisionResponseValidator, MealVisionResponseValidator>();
        services.AddSingleton<IMealVisionPromptBuilder>(sp => { var x = sp.GetRequiredService<IOptions<MealVisionOptions>>().Value; return new MealVisionPromptBuilder(x.PromptVersion, x.SchemaVersion); });
        services.AddScoped<IMealVisionAnalysisService, MealVisionAnalysisService>();
        services.AddOptions<MealAnalysisOptions>().Bind(configuration.GetSection(MealAnalysisOptions.SectionName)).Validate(x => !string.IsNullOrWhiteSpace(x.Provider) && x.RetentionDays is >= 0 and <= 3650 && x.MaximumImageBytes is >= 1024 and <= 20_000_000 && x.AllowedMimeTypes.Length > 0 && x.MaximumFileNameLength is >= 32 and <= 260 && (!x.Provider.Equals("S3", StringComparison.OrdinalIgnoreCase) || (Uri.TryCreate(x.S3.Endpoint, UriKind.Absolute, out _) && !string.IsNullOrWhiteSpace(x.S3.Bucket) && !string.IsNullOrWhiteSpace(x.S3.AccessKey) && !string.IsNullOrWhiteSpace(x.S3.SecretKey))), "MealAnalysis configuration is invalid.").ValidateOnStart();
        services.AddHttpClient("MealImageS3");
        services.AddSingleton<LocalMealImageStorage>(); services.AddSingleton<S3MealImageStorage>();
        services.AddSingleton<IMealImageStorage>(sp => sp.GetRequiredService<IOptions<MealAnalysisOptions>>().Value.Provider.Equals("S3", StringComparison.OrdinalIgnoreCase) ? sp.GetRequiredService<S3MealImageStorage>() : sp.GetRequiredService<LocalMealImageStorage>());
        services.AddScoped<IFoodMatcher, FoodMatcher>();
        services.AddHttpClient<IFoodResolutionModel, FoodResolutionModel>((sp, client) => { var endpoint = sp.GetRequiredService<IOptions<MealVisionOptions>>().Value.OpenAi.Endpoint; client.BaseAddress = new Uri(endpoint); client.Timeout = Timeout.InfiniteTimeSpan; });
        services.AddScoped<IFoodResolutionAssistant, FoodResolutionAssistant>();
        services.AddScoped<IMealAnalysisPipeline, MealAnalysisPipeline>();
        services.AddScoped<IMealManagementService, MealManagementService>();

        return services;
    }
}
