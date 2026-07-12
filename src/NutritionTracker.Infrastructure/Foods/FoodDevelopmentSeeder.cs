using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Infrastructure.Persistence;
namespace NutritionTracker.Infrastructure.Foods;

public static class FoodDevelopmentSeeder
{
    public static async Task SeedAsync(IServiceProvider services, CancellationToken ct = default)
    {
        var db = services.GetRequiredService<NutritionTrackerDbContext>();
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(71420601)", ct);
        var now = DateTime.UtcNow;
        var units = new[] { ("gram", "Gram", ServingUnitType.Mass), ("millilitre", "Millilitre", ServingUnitType.Volume), ("teaspoon", "Teaspoon", ServingUnitType.HouseholdMeasure), ("tablespoon", "Tablespoon", ServingUnitType.HouseholdMeasure), ("cup", "Cup", ServingUnitType.HouseholdMeasure), ("katori", "Katori", ServingUnitType.HouseholdMeasure), ("bowl", "Bowl", ServingUnitType.HouseholdMeasure), ("ladle", "Ladle", ServingUnitType.HouseholdMeasure), ("plate", "Plate", ServingUnitType.HouseholdMeasure), ("piece", "Piece", ServingUnitType.Count), ("slice", "Slice", ServingUnitType.Count), ("roti", "Roti", ServingUnitType.DishSpecific), ("chapati", "Chapati", ServingUnitType.DishSpecific), ("paratha", "Paratha", ServingUnitType.DishSpecific), ("serving", "Serving", ServingUnitType.DishSpecific) };
        foreach (var unit in units) if (!await db.ServingUnits.AnyAsync(x => x.Code == unit.Item1, ct)) db.ServingUnits.Add(new ServingUnit { Code = unit.Item1, DisplayName = unit.Item2, UnitType = unit.Item3, IsMetric = unit.Item1 is "gram" or "millilitre", IsCountBased = unit.Item3 is ServingUnitType.Count or ServingUnitType.DishSpecific, CreatedAtUtc = now, UpdatedAtUtc = now });
        await db.SaveChangesAsync(ct);
        if (!await db.Foods.AnyAsync(x => x.DataSource == "Development seed v1", ct))
        {
            var rice = Food("Cooked white rice", "cooked white rice", FoodCategory.Grain, Cuisine.General, PreparationMethod.Boiled, 130, 2.4m, 28.2m, .3m, .4m, now); AddAliases(rice, ("bhaat", "bn", AliasType.RegionalName), ("bhat", "bn-Latn", AliasType.Transliteration), ("chawal", "hi-Latn", AliasType.RegionalName), ("sada bhaat", "bn-Latn", AliasType.RegionalName), ("steamed rice", "en", AliasType.CommonName));
            var dal = Food("Plain cooked masoor dal", "plain cooked masoor dal", FoodCategory.Pulse, Cuisine.Bengali, PreparationMethod.Boiled, 116, 9m, 20m, .4m, 8m, now); AddAliases(dal, ("masoor dal", "hi-Latn", AliasType.CommonName), ("musur dal", "bn-Latn", AliasType.RegionalName), ("musurir dal", "bn-Latn", AliasType.RegionalName));
            var rohu = Food("Rohu fish curry", "rohu fish curry", FoodCategory.PreparedDish, Cuisine.Bengali, PreparationMethod.Curried, 145, 15m, 4m, 8m, 1m, now); AddAliases(rohu, ("rui macher jhol", "bn-Latn", AliasType.RegionalName), ("rui mach", "bn-Latn", AliasType.RegionalName), ("rohu curry", "en", AliasType.CommonName));
            db.Foods.AddRange(rice, dal, rohu); await db.SaveChangesAsync(ct);
            await AddConversion(db, rice, "cup", 158, now, ct); await AddConversion(db, dal, "katori", 180, now, ct);
        }
        await transaction.CommitAsync(ct);
    }
    private static Food Food(string display, string normalized, FoodCategory category, Cuisine cuisine, PreparationMethod method, decimal calories, decimal protein, decimal carbs, decimal fat, decimal fibre, DateTime now) => new() { CanonicalName = display, DisplayName = display, NormalizedName = normalized, Category = category, Cuisine = cuisine, PreparationMethod = method, FoodState = FoodState.Cooked, CaloriesPer100Grams = calories, ProteinGramsPer100Grams = protein, CarbohydrateGramsPer100Grams = carbs, FatGramsPer100Grams = fat, FibreGramsPer100Grams = fibre, DataSource = "Development seed v1", SourceVersion = "1", IsVerified = false, IsActive = true, CreatedAtUtc = now, UpdatedAtUtc = now };
    private static void AddAliases(Food food, params (string Alias, string Language, AliasType Type)[] aliases) { foreach (var a in aliases) food.Aliases.Add(new FoodAlias { Alias = a.Alias, NormalizedAlias = a.Alias, LanguageCode = a.Language, AliasType = a.Type, Priority = 100, CreatedAtUtc = food.CreatedAtUtc, UpdatedAtUtc = food.UpdatedAtUtc }); }
    private static async Task AddConversion(NutritionTrackerDbContext db, Food food, string code, decimal grams, DateTime now, CancellationToken ct) { var unit = await db.ServingUnits.SingleAsync(x => x.Code == code, ct); db.FoodServingConversions.Add(new FoodServingConversion { FoodId = food.Id, ServingUnitId = unit.Id, Quantity = 1, EquivalentGrams = grams, Source = "Development seed v1", Confidence = DataConfidence.Medium, IsDefault = true, CreatedAtUtc = now, UpdatedAtUtc = now }); await db.SaveChangesAsync(ct); }
}
