using FluentAssertions;
using NutritionTracker.Application.Foods;
using NutritionTracker.Domain.Foods;
using Xunit;
namespace NutritionTracker.UnitTests;

public sealed class FoodServicesTests
{
    [Theory][InlineData("  Cooked   White Rice ", "cooked white rice")][InlineData("Rui-Macher Jhol", "rui macher jhol")][InlineData("BHAAT", "bhaat")][InlineData("রুই মাছ", "রুই মাছ")] public void NormalizesFoodNames(string input, string expected) => new FoodNameNormalizer().Normalize(input).Should().Be(expected);
    [Fact] public void ScalesAndPreservesUnknowns() { var x = new FoodNutritionCalculator().CalculateForGrams(new(130, 2.4m, 28, .3m, .4m), 50); x.Calories.Should().Be(65); x.Sugar.Should().BeNull(); }
    [Fact] public void ConvertsServing() => new FoodNutritionCalculator().CalculateForServing(new(130, 2.4m, 28, .3m, .4m), new(1, 158, "Development seed", DataConfidence.Medium), 1.5m).Grams.Should().Be(237);
    [Theory][InlineData(0)][InlineData(-1)] public void RejectsInvalidGrams(decimal grams) => FluentActions.Invoking(() => new FoodNutritionCalculator().CalculateForGrams(new(1, 1, 1, 1, 1), grams)).Should().Throw<ArgumentOutOfRangeException>();
}
