using Microsoft.Extensions.DependencyInjection;
using NutritionTracker.Application.Nutrition;
using NutritionTracker.Application.Foods;

namespace NutritionTracker.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddSingleton<INutritionTargetCalculator, MifflinStJeorNutritionTargetCalculator>();
        services.AddSingleton<IFoodNameNormalizer, FoodNameNormalizer>();
        services.AddSingleton<IFoodNutritionCalculator, FoodNutritionCalculator>();
        return services;
    }
}
