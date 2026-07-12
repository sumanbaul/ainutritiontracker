namespace NutritionTracker.Api.Configuration;

public sealed class HealthReadinessOptions
{
    public const string SectionName = "HealthChecks";

    public bool EnableDatabaseReadinessCheck { get; init; } = true;
}
