using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Infrastructure.Persistence;
namespace NutritionTracker.Infrastructure.Foods;

public static class NutritionFoundationSeeder
{
    public static async Task SeedAsync(IServiceProvider services, CancellationToken ct = default)
    {
        var db = services.GetRequiredService<NutritionTrackerDbContext>();
        var core = new (string Code, string Name, NutrientUnit Unit)[]
        {
            ("energy_kcal", "Energy", NutrientUnit.Kilocalorie), ("protein_g", "Protein", NutrientUnit.Gram), ("carbohydrate_g", "Carbohydrate", NutrientUnit.Gram), ("fat_g", "Total fat", NutrientUnit.Gram), ("fibre_g", "Dietary fibre", NutrientUnit.Gram), ("sugar_g", "Total sugars", NutrientUnit.Gram), ("sodium_mg", "Sodium", NutrientUnit.Milligram), ("saturated_fat_g", "Saturated fat", NutrientUnit.Gram), ("monounsaturated_fat_g", "Monounsaturated fat", NutrientUnit.Gram), ("polyunsaturated_fat_g", "Polyunsaturated fat", NutrientUnit.Gram), ("cholesterol_mg", "Cholesterol", NutrientUnit.Milligram), ("calcium_mg", "Calcium", NutrientUnit.Milligram), ("iron_mg", "Iron", NutrientUnit.Milligram), ("potassium_mg", "Potassium", NutrientUnit.Milligram), ("vitamin_a_ug", "Vitamin A", NutrientUnit.Microgram), ("vitamin_c_mg", "Vitamin C", NutrientUnit.Milligram), ("vitamin_d_ug", "Vitamin D", NutrientUnit.Microgram), ("vitamin_b12_ug", "Vitamin B12", NutrientUnit.Microgram), ("folate_ug", "Folate", NutrientUnit.Microgram)
        };
        for (var i = 0; i < core.Length; i++) if (!await db.NutrientDefinitions.AnyAsync(x => x.Code == core[i].Code, ct)) db.NutrientDefinitions.Add(new NutrientDefinition { Code = core[i].Code, DisplayName = core[i].Name, Unit = core[i].Unit, DisplayOrder = i, IsCore = true });
        foreach (var tag in new[] { ("allergen.gluten", "Contains gluten", "allergen"), ("allergen.milk", "Contains milk", "allergen"), ("allergen.egg", "Contains egg", "allergen"), ("allergen.fish", "Contains fish", "allergen"), ("allergen.shellfish", "Contains shellfish", "allergen"), ("diet.vegetarian", "Vegetarian", "diet"), ("diet.vegan", "Vegan", "diet"), ("diet.halal", "Halal", "diet") }) if (!await db.FoodTags.AnyAsync(x => x.Code == tag.Item1, ct)) db.FoodTags.Add(new FoodTag { Code = tag.Item1, DisplayName = tag.Item2, Category = tag.Item3 });
        await db.SaveChangesAsync(ct);
    }
}
