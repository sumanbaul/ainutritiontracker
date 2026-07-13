using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NutritionTracker.Application.Foods;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Infrastructure.Foods;

/// <summary>Idempotent, source-labelled West Bengal/Kolkata dish estimates. Not IFCT data.</summary>
public static class BengaliFoodSeeder
{
    public const string CatalogVersion = "bengal-kolkata-v1";
    private const string Source = "NutriLens curated Bengal recipe estimate";
    private const string Reference = "USDA FoodData Central ingredient composition; NutriLens standard household recipe";

    public static async Task SeedAsync(IServiceProvider services, CancellationToken ct = default)
    {
        var db = services.GetRequiredService<NutritionTrackerDbContext>();
        var normalizer = services.GetRequiredService<IFoodNameNormalizer>();
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(71420602)", ct);
        var unit = await db.ServingUnits.SingleAsync(x => x.Code == "serving", ct);
        var now = DateTime.UtcNow;
        foreach (var d in Definitions)
        {
            if (await db.Foods.AnyAsync(x => x.NormalizedName == normalizer.Normalize(d.Name), ct)) continue;
            var food = new Food { CanonicalName = d.Name, DisplayName = d.Bengali is null ? d.Name : $"{d.Name} ({d.Bengali})", NormalizedName = normalizer.Normalize(d.Name), Category = d.Category, Cuisine = Cuisine.Bengali, PreparationMethod = d.Method, FoodState = FoodState.Prepared, CaloriesPer100Grams = d.Kcal, ProteinGramsPer100Grams = d.Protein, CarbohydrateGramsPer100Grams = d.Carbs, FatGramsPer100Grams = d.Fat, FibreGramsPer100Grams = d.Fibre, DataSource = Source, SourceReference = Reference, SourceVersion = CatalogVersion, IsVerified = false, IsActive = true, CreatedAtUtc = now, UpdatedAtUtc = now };
            foreach (var alias in new[] { d.Bengali, d.Regional }.Concat(d.Aliases).Where(x => !string.IsNullOrWhiteSpace(x)).Distinct(StringComparer.OrdinalIgnoreCase))
                food.Aliases.Add(new FoodAlias { Alias = alias!, NormalizedAlias = normalizer.Normalize(alias!), LanguageCode = alias!.Any(c => c >= '\u0980' && c <= '\u09ff') ? "bn" : "en", Region = "West Bengal", Transliteration = d.Regional, AliasType = AliasType.CommonName, Priority = 100, CreatedAtUtc = now, UpdatedAtUtc = now });
            food.ServingConversions.Add(new FoodServingConversion { ServingUnitId = unit.Id, Quantity = 1, EquivalentGrams = d.ServingGrams, Source = Source, SourceReference = Reference, Confidence = DataConfidence.Medium, IsDefault = true, CreatedAtUtc = now, UpdatedAtUtc = now });
            db.Foods.Add(food);
        }
        await db.SaveChangesAsync(ct); await tx.CommitAsync(ct);
    }

    public static IReadOnlyList<BengaliFoodDefinition> Definitions { get; } = [
        D("Cooked white rice", "ভাত", "bhaat", FoodCategory.Grain, PreparationMethod.Boiled,130,2.4m,28.2m,.3m,.4m,180,"steamed rice","sada bhat","chawal"),
        D("Bengali khichuri", "খিচুড়ি", "khichuri", FoodCategory.PreparedDish, PreparationMethod.Mixed,142,4.5m,23m,4m,2.5m,250,"khichdi","bhuna khichuri"),
        D("Plain masoor dal", "মুসুর ডাল", "musur dal", FoodCategory.Pulse, PreparationMethod.Boiled,116,8m,18m,2m,5m,180,"masoor dal","dal"),
        D("Cholar dal", "ছোলার ডাল", "cholar dal", FoodCategory.Pulse, PreparationMethod.Curried,156,6m,22m,5m,5m,180,"chana dal","bengal gram dal"),
        D("Aloo posto", "আলু পোস্ত", "aloo posto", FoodCategory.PreparedDish, PreparationMethod.Curried,155,3m,18m,8m,3m,150,"potato poppy seed curry","aloo poshto"),
        D("Shukto", "শুক্তো", "shukto", FoodCategory.PreparedDish, PreparationMethod.Curried,82,2m,10m,4m,3m,180,"bengali mixed vegetables"),
        D("Mixed vegetable curry", "মিশ্র সবজি", "mishti sobji", FoodCategory.PreparedDish, PreparationMethod.Curried,95,2.5m,12m,4m,3.5m,180,"vegetable curry","mixed veg curry"),
        D("Begun bhaja", "বেগুন ভাজা", "begun bhaja", FoodCategory.Vegetable, PreparationMethod.ShallowFried,170,2m,12m,12m,5m,80,"fried eggplant","brinjal fry"),
        D("Potol posto", "পটল পোস্ত", "potol posto", FoodCategory.PreparedDish, PreparationMethod.Curried,135,3m,14m,7m,3m,150,"pointed gourd poppy seed curry"),
        D("Dhokar dalna", "ধোকার ডালনা", "dhokar dalna", FoodCategory.PreparedDish, PreparationMethod.Curried,164,7m,19m,7m,4m,160,"lentil cake curry","dhoka dalna"),
        D("Labra", "লাবড়া", "labra", FoodCategory.PreparedDish, PreparationMethod.Curried,90,2.5m,12m,4m,3m,180,"mixed vegetable labra"),
        D("Macher jhol", "মাছের ঝোল", "macher jhol", FoodCategory.Fish, PreparationMethod.Curried,132,14m,4m,7m,1m,180,"fish curry","bengali fish curry"),
        D("Rohu fish curry", "রুই মাছের ঝোল", "rui macher jhol", FoodCategory.Fish, PreparationMethod.Curried,145,15m,4m,8m,1m,170,"rui mach","rohu curry"),
        D("Shorshe ilish", "সরষে ইলিশ", "shorshe ilish", FoodCategory.Fish, PreparationMethod.Curried,225,18m,3m,16m,1m,150,"hilsa mustard curry","ilish mach"),
        D("Chingri malaikari", "চিংড়ি মালাইকারি", "chingri malaikari", FoodCategory.Seafood, PreparationMethod.Curried,205,16m,6m,13m,1m,150,"prawn malai curry","shrimp coconut curry"),
        D("Bengali fish fry", "ফিশ ফ্রাই", "fish fry", FoodCategory.Fish, PreparationMethod.DeepFried,250,17m,16m,13m,1m,100,"kolkata fish fry"),
        D("Chicken curry", "মুরগির ঝোল", "murgir jhol", FoodCategory.Poultry, PreparationMethod.Curried,180,17m,5m,10m,1m,180,"bengali chicken curry","chicken jhol"),
        D("Kosha mangsho", "কষা মাংস", "kosha mangsho", FoodCategory.Meat, PreparationMethod.Curried,260,18m,7m,18m,1m,180,"bengali mutton curry","mutton kosha"),
        D("Dim er dalna", "ডিমের ডালনা", "dim er dalna", FoodCategory.Egg, PreparationMethod.Curried,168,10m,5m,11m,1m,160,"egg curry","bengali egg curry"),
        D("Luchi", "লুচি", "luchi", FoodCategory.Grain, PreparationMethod.DeepFried,330,6m,44m,14m,2m,35,"puri","poori","luchi puri"),
        D("Kolkata kathi roll", "কাঠি রোল", "kathi roll", FoodCategory.Snack, PreparationMethod.Mixed,250,10m,28m,11m,2m,180,"kati roll","egg roll","kolkata roll"),
        D("Puchka", "ফুচকা", "phuchka", FoodCategory.Snack, PreparationMethod.Mixed,145,3m,25m,4m,2m,120,"puchka","panipuri","golgappa"),
        D("Jhal muri", "ঝাল মুড়ি", "jhal muri", FoodCategory.Snack, PreparationMethod.Mixed,180,4m,30m,5m,4m,120,"spicy puffed rice","jhaal muri"),
        D("Ghugni", "ঘুগনি", "ghugni", FoodCategory.PreparedDish, PreparationMethod.Curried,150,7m,22m,4m,6m,180,"yellow pea curry","matar ghugni"),
        D("Aloor chop", "আলুর চপ", "aloor chop", FoodCategory.Snack, PreparationMethod.DeepFried,245,4m,29m,13m,3m,80,"potato chop","aloo chop"),
        D("Beguni", "বেগুনি", "beguni", FoodCategory.Snack, PreparationMethod.DeepFried,210,4m,23m,11m,4m,70,"eggplant fritter","brinjal pakora"),
        D("Peyaji", "পেঁয়াজি", "peyaji", FoodCategory.Snack, PreparationMethod.DeepFried,235,5m,25m,12m,3m,70,"onion fritter","pyaji"),
        D("Singara", "সিঙ্গাড়া", "singara", FoodCategory.Snack, PreparationMethod.DeepFried,285,5m,33m,15m,3m,90,"samosa","bengali samosa"),
        D("Vegetable chop", "ভেজিটেবল চপ", "vegetable chop", FoodCategory.Snack, PreparationMethod.DeepFried,230,5m,25m,11m,4m,90,"veg chop"),
        D("Fish chop", "ফিশ চপ", "fish chop", FoodCategory.Snack, PreparationMethod.DeepFried,235,12m,20m,12m,2m,90,"bengali fish cutlet"),
        D("Chicken chowmein", "চিকেন চাউমিন", "chicken chowmein", FoodCategory.PreparedDish, PreparationMethod.Sauteed,190,9m,24m,7m,2m,250,"noodles","chicken noodles","kolkata chowmein"),
        D("Vegetable chowmein", "ভেজ চাউমিন", "veg chowmein", FoodCategory.PreparedDish, PreparationMethod.Sauteed,165,5m,25m,5m,2m,250,"vegetable noodles","veg noodles"),
        D("Mishti doi", "মিষ্টি দই", "mishti doi", FoodCategory.Dairy, PreparationMethod.Fermented,165,4m,25m,5m,0m,100,"sweet yogurt","sweet curd","yogurt"),
        D("Roshogolla", "রসগোল্লা", "roshogolla", FoodCategory.Sweet, PreparationMethod.Mixed,186,4m,40m,1m,0m,50,"rasgulla","rasagola"),
        D("Sandesh", "সন্দেশ", "sandesh", FoodCategory.Sweet, PreparationMethod.Mixed,260,8m,37m,9m,0m,50,"sondesh"),
        D("Chomchom", "চমচম", "chomchom", FoodCategory.Sweet, PreparationMethod.Mixed,280,6m,45m,8m,0m,60,"cham cham"),
        D("Pantua", "পান্তুয়া", "pantua", FoodCategory.Sweet, PreparationMethod.DeepFried,330,5m,50m,12m,0m,55,"gulab jamun","pantowa"),
        D("Jalebi", "জিলাপি", "jalebi", FoodCategory.Sweet, PreparationMethod.DeepFried,415,3m,75m,12m,0m,45,"jilipi"),
        D("Tomato chutney", "টমেটো চাটনি", "tomato chutney", FoodCategory.Condiment, PreparationMethod.Boiled,115,1m,27m,1m,2m,40,"red chutney","bengali tomato chutney"),
        D("Mango chutney", "আমের চাটনি", "aamer chutney", FoodCategory.Condiment, PreparationMethod.Boiled,135,1m,33m,1m,2m,40,"sweet mango chutney"),
        D("Bengali tea with milk", "দুধ চা", "dudh cha", FoodCategory.Beverage, PreparationMethod.Boiled,55,1.5m,8m,2m,0m,150,"chai","milk tea"),
        D("Muri", "মুড়ি", "muri", FoodCategory.Grain, PreparationMethod.Mixed,380,8m,83m,1m,1m,30,"puffed rice","murmura"),
        D("Chanachur", "চানাচুর", "chanachur", FoodCategory.Snack, PreparationMethod.Mixed,515,11m,50m,29m,5m,40,"bengali mixture","namkeen"),
        D("Kabiraji cutlet", "কবিরাজি কাটলেট", "kabiraji cutlet", FoodCategory.Snack, PreparationMethod.DeepFried,310,16m,20m,19m,1m,140,"kobiraji","chicken cutlet"),
        D("Mughlai paratha", "মোগলাই পরোটা", "mughlai paratha", FoodCategory.PreparedDish, PreparationMethod.ShallowFried,295,10m,31m,15m,2m,180,"moglai porota","egg stuffed paratha"),
        D("Kochuri", "কচুরি", "kochuri", FoodCategory.Snack, PreparationMethod.DeepFried,325,7m,42m,14m,3m,50,"kachaori","kachori"),
        D("Telebhaja", "তেলেভাজা", "telebhaja", FoodCategory.Snack, PreparationMethod.DeepFried,280,5m,29m,16m,3m,70,"fried snack","bengali fritter")
    ];

    private static BengaliFoodDefinition D(string n, string? b, string r, FoodCategory c, PreparationMethod m, decimal kcal, decimal p, decimal carb, decimal f, decimal fibre, decimal g, params string[] a) => new(n, b, r, c, m, kcal, p, carb, f, fibre, g, a);
}

public sealed record BengaliFoodDefinition(string Name, string? Bengali, string Regional, FoodCategory Category, PreparationMethod Method, decimal Kcal, decimal Protein, decimal Carbs, decimal Fat, decimal Fibre, decimal ServingGrams, IReadOnlyList<string> Aliases);
