using NutritionTracker.Application.Nutrition;
using NutritionTracker.Domain.Profiles;

namespace NutritionTracker.Application.Profiles;

public sealed record ProfileCommand(string Name, DateOnly DateOfBirth, BiologicalSex BiologicalSex, decimal HeightCm, decimal CurrentWeightKg, decimal TargetWeightKg, ActivityLevel ActivityLevel, GoalType GoalType, DietPreference DietPreference, PreferredMeasurementSystem PreferredMeasurementSystem, string Timezone, decimal? CustomCalories, decimal? CustomProteinGrams, decimal? CustomCarbohydrateGrams, decimal? CustomFatGrams);
public sealed record WeightEntryCommand(decimal WeightKg, DateTime RecordedAtUtc, string? Notes);
public sealed record ProfileResult(Guid Id, string Name, DateOnly DateOfBirth, int Age, BiologicalSex BiologicalSex, decimal HeightCm, decimal CurrentWeightKg, decimal TargetWeightKg, ActivityLevel ActivityLevel, GoalType GoalType, DietPreference DietPreference, PreferredMeasurementSystem PreferredMeasurementSystem, string Timezone, bool IsOnboardingComplete, NutritionTargetResult CurrentNutritionTarget);
public sealed record WeightEntryResult(Guid Id, decimal WeightKg, DateTime RecordedAtUtc, string? Notes);

public interface IProfileService
{
    Task<ProfileResult> CreateAsync(string userId, ProfileCommand command, CancellationToken cancellationToken);
    Task<ProfileResult?> GetAsync(string userId, CancellationToken cancellationToken);
    Task<ProfileResult?> UpdateAsync(string userId, ProfileCommand command, CancellationToken cancellationToken);
    Task<ProfileResult?> RecalculateAsync(string userId, CancellationToken cancellationToken);
    Task<WeightEntryResult?> AddWeightAsync(string userId, WeightEntryCommand command, CancellationToken cancellationToken);
    Task<IReadOnlyList<WeightEntryResult>> GetWeightsAsync(string userId, DateTime? fromUtc, DateTime? toUtc, bool descending, int take, CancellationToken cancellationToken);
}
