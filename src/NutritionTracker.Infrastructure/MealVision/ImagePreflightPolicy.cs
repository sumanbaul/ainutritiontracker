using NutritionTracker.Application.MealVision;

namespace NutritionTracker.Infrastructure.MealVision;

public sealed class ImagePreflightPolicy(MealVisionPreflightOptions options)
{
    public void Evaluate(ImagePreflightResult result, List<string> warnings)
    {
        var issues = result.Issues.Where(x => !string.IsNullOrWhiteSpace(x)).Distinct(StringComparer.OrdinalIgnoreCase).Take(10).ToArray();
        if (result.Decision == ImagePreflightDecision.Rejected || !result.QualityAcceptable)
            throw new MealVisionPreflightRejectedException("The image did not pass meal-image preflight checks.", issues.Length == 0 ? ["Image is not an acceptable meal photo."] : issues);
        if (result.Decision == ImagePreflightDecision.Uncertain || result.FoodConfidence < options.MinimumFoodConfidence || result.QualityScore < options.MinimumQualityScore)
        {
            if (options.FailClosed && !options.AllowUncertainInDevelopment) throw new MealVisionPreflightUnavailableException("Image preflight was uncertain and production fail-closed policy is enabled.");
            warnings.Add("Image preflight was uncertain; review the meal analysis carefully.");
        }
    }
}
