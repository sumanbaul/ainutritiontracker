using FluentAssertions;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Infrastructure.MealVision;
using Xunit;

namespace NutritionTracker.UnitTests;

public sealed class ImagePreflightPolicyTests
{
    [Fact]
    public void AcceptedFoodImagePasses()
    {
        var warnings = new List<string>();
        new ImagePreflightPolicy(Options()).Evaluate(Result(ImagePreflightDecision.Accepted, .95m, .95m, true), warnings);
        warnings.Should().BeEmpty();
    }

    [Fact]
    public void NonFoodImageIsRejected()
    {
        var action = () => new ImagePreflightPolicy(Options()).Evaluate(Result(ImagePreflightDecision.Rejected, .05m, .95m, true, "NonFoodImage"), []);
        action.Should().Throw<MealVisionPreflightRejectedException>().Which.Issues.Should().Contain("NonFoodImage");
    }

    [Fact]
    public void PoorQualityImageIsRejected()
    {
        var action = () => new ImagePreflightPolicy(Options()).Evaluate(Result(ImagePreflightDecision.Accepted, .95m, .40m, false, "Blurry"), []);
        action.Should().Throw<MealVisionPreflightRejectedException>().Which.Issues.Should().Contain("Blurry");
    }

    [Fact]
    public void UncertainImageIsAllowedWhenDevelopmentFallbackIsEnabled()
    {
        var warnings = new List<string>();
        new ImagePreflightPolicy(new MealVisionPreflightOptions { FailClosed = false, AllowUncertainInDevelopment = true }).Evaluate(Result(ImagePreflightDecision.Uncertain, .75m, .75m, true), warnings);
        warnings.Should().ContainSingle().Which.Should().Contain("uncertain");
    }

    [Fact]
    public void UncertainImageIsBlockedWhenProductionFailsClosed()
    {
        var action = () => new ImagePreflightPolicy(Options()).Evaluate(Result(ImagePreflightDecision.Uncertain, .75m, .75m, true), []);
        action.Should().Throw<MealVisionPreflightUnavailableException>();
    }

    private static MealVisionPreflightOptions Options() => new() { FailClosed = true, MinimumFoodConfidence = .80m, MinimumQualityScore = .70m };
    private static ImagePreflightResult Result(ImagePreflightDecision decision, decimal food, decimal quality, bool acceptable, params string[] issues) => new(decision, food, quality, acceptable, issues, "test", 1);
}
