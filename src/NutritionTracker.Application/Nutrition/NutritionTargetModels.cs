using NutritionTracker.Domain.Profiles;

namespace NutritionTracker.Application.Nutrition;

public sealed record NutritionTargetInput(
    DateOnly DateOfBirth,
    BiologicalSex BiologicalSex,
    decimal HeightCm,
    decimal CurrentWeightKg,
    ActivityLevel ActivityLevel,
    GoalType GoalType,
    DateOnly EffectiveDate,
    decimal? CustomCalories = null,
    decimal? CustomProteinGrams = null,
    decimal? CustomCarbohydrateGrams = null,
    decimal? CustomFatGrams = null);

public sealed record NutritionTargetResult(
    int Age,
    decimal BasalMetabolicRate,
    decimal TotalDailyEnergyExpenditure,
    decimal TargetCalories,
    decimal ProteinGrams,
    decimal CarbohydrateGrams,
    decimal FatGrams,
    decimal FibreGrams,
    string CalculationMethod,
    IReadOnlyList<string> Warnings);

public interface INutritionTargetCalculator
{
    NutritionTargetResult Calculate(NutritionTargetInput input);
}

public sealed class NutritionCalculationException(string message) : Exception(message);
