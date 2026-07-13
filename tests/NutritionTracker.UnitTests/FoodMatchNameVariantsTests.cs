using FluentAssertions;
using NutritionTracker.Infrastructure.Meals;
using Xunit;

namespace NutritionTracker.UnitTests;

public sealed class FoodMatchNameVariantsTests
{
    private static readonly string[] NoodleVariants = ["noodles", "noodle"];
    [Fact]
    public void RemovesOnlyCommonPreparationWordsAndKeepsOriginal()
    {
        FoodMatchNameVariants.Create("steamed cooked white rice").Should().BeEquivalentTo("steamed cooked white rice", "white rice");
    }

    [Fact]
    public void AddsConservativeSingularVariant()
    {
        FoodMatchNameVariants.Create("noodles").Should().Contain(NoodleVariants);
    }
}
