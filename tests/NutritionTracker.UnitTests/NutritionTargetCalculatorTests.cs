using FluentAssertions;
using NutritionTracker.Application.Nutrition;
using NutritionTracker.Domain.Profiles;
using Xunit;

namespace NutritionTracker.UnitTests;

public sealed class NutritionTargetCalculatorTests
{
    [Fact]
    public void CalculatesMaleMifflinStJeorTarget()
    {
        var result = Calculator().Calculate(new(new DateOnly(1990, 1, 1), BiologicalSex.Male, 180m, 80m, ActivityLevel.ModeratelyActive, GoalType.MaintainWeight, new DateOnly(2026, 7, 12)));
        result.Age.Should().Be(36); result.BasalMetabolicRate.Should().Be(1750m); result.TotalDailyEnergyExpenditure.Should().Be(2712.5m); result.TargetCalories.Should().Be(2712.5m);
    }
    [Fact]
    public void ClampsAutomaticLowFemaleTargetAndWarns()
    { var r = Calculator().Calculate(new(new DateOnly(1990, 1, 1), BiologicalSex.Female, 100m, 25m, ActivityLevel.Sedentary, GoalType.LoseWeightModerately, new DateOnly(2026, 7, 12))); r.TargetCalories.Should().Be(1200m); r.Warnings.Should().NotBeEmpty(); }
    [Fact]
    public void RejectsUnspecifiedAutomaticCalculation()
    { var act = () => Calculator().Calculate(new(new DateOnly(1990, 1, 1), BiologicalSex.Unspecified, 170m, 70m, ActivityLevel.Sedentary, GoalType.MaintainWeight, new DateOnly(2026, 7, 12))); act.Should().Throw<NutritionCalculationException>(); }
    private static MifflinStJeorNutritionTargetCalculator Calculator() => new(new() { ActivityMultipliers = new() { [ActivityLevel.Sedentary] = 1.2m, [ActivityLevel.LightlyActive] = 1.375m, [ActivityLevel.ModeratelyActive] = 1.55m, [ActivityLevel.VeryActive] = 1.725m, [ActivityLevel.ExtraActive] = 1.9m }, GoalCalorieAdjustments = new() { [GoalType.MaintainWeight] = 0m, [GoalType.LoseWeightSlowly] = -250m, [GoalType.LoseWeightModerately] = -500m, [GoalType.GainWeightSlowly] = 250m, [GoalType.GainMuscle] = 300m, [GoalType.Custom] = 0m }, ProteinMultipliers = new() { [GoalType.MaintainWeight] = 1.4m, [GoalType.LoseWeightSlowly] = 1.6m, [GoalType.LoseWeightModerately] = 1.8m, [GoalType.GainWeightSlowly] = 1.6m, [GoalType.GainMuscle] = 1.8m, [GoalType.Custom] = 0m }, MinimumCaloriesMale = 1500m, MinimumCaloriesFemale = 1200m, FatPercentage = .25m, MinimumFatGramsPerKg = .6m, FibreGramsPer1000Calories = 14m, MacroCalorieTolerance = 25m, MinimumSupportedAge = 18, MaximumSupportedAge = 120 });
}
