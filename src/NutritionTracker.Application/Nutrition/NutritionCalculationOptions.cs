using NutritionTracker.Domain.Profiles;

namespace NutritionTracker.Application.Nutrition;

public sealed class NutritionCalculationOptions
{
    public const string SectionName = "NutritionCalculation";
    public Dictionary<ActivityLevel, decimal> ActivityMultipliers { get; init; } = new();
    public Dictionary<GoalType, decimal> GoalCalorieAdjustments { get; init; } = new();
    public Dictionary<GoalType, decimal> ProteinMultipliers { get; init; } = new();
    public decimal MinimumCaloriesMale { get; init; }
    public decimal MinimumCaloriesFemale { get; init; }
    public decimal FatPercentage { get; init; }
    public decimal MinimumFatGramsPerKg { get; init; }
    public decimal FibreGramsPer1000Calories { get; init; }
    public decimal MacroCalorieTolerance { get; init; }
    public int MinimumSupportedAge { get; init; }
    public int MaximumSupportedAge { get; init; }
}
