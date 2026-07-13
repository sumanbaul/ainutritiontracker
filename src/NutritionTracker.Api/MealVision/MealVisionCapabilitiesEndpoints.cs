using NutritionTracker.Application.MealVision;

namespace NutritionTracker.Api.MealVision;

public static class MealVisionCapabilitiesEndpoints
{
    public static IEndpointRouteBuilder MapMealVisionCapabilitiesEndpoints(this IEndpointRouteBuilder routes)
    {
        routes.MapGet("/api/meal-vision/capabilities", (IMealVisionProviderCatalog catalog) => Results.Ok(catalog.GetCapabilities()));
        return routes;
    }
}
