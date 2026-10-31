using Microsoft.EntityFrameworkCore;
using NutritionTracker.Domain.Profiles;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Api.Nutrition;

public sealed record CatalogIngredient(string Name, decimal Quantity, string Unit);
public sealed record CatalogRecipe(string Id, string Name, string Cuisine, PlannedMealSlot Slot, decimal Calories, decimal ProteinGrams, IReadOnlySet<string> DietTags, IReadOnlySet<string> AllergenCodes, IReadOnlyList<CatalogIngredient> Ingredients, IReadOnlyList<string> Preparation, int PreparationMinutes);
public sealed record SwapRequest(string? RecipeId);
public sealed record ShoppingCheckRequest(bool IsChecked);

public static class DiscoverMealsEndpoints
{
    public static IEndpointRouteBuilder MapDiscoverMealsEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/discover-meals");
        group.MapGet("/catalog", Catalog);
        group.MapGet("/recommendations", Recommendations);
        group.MapPost("/plan/regenerate", Regenerate);
        group.MapPost("/plan/{date}/swap/{slot}", Swap);
        group.MapGet("/saved", Saved);
        group.MapPut("/saved/{recipeId}", Save);
        group.MapDelete("/saved/{recipeId}", Unsave);
        group.MapGet("/shopping-list", Shopping);
        group.MapPost("/shopping-list/from-plan", AddPlanToShopping);
        group.MapPut("/shopping-list/{id:guid}", CheckShopping);
        return routes;
    }

    private static async Task<IResult> Catalog(HttpContext c, NutritionTrackerDbContext db, CancellationToken ct)
    {
        var user = User(c);
        var excluded = await Exclusions(db, user, ct);
        var profile = await db.UserProfiles.AsNoTracking().SingleOrDefaultAsync(x => x.UserId == user, ct);
        return Results.Ok(MealCatalog.All.Where(x => Compatible(x, profile?.DietPreference, excluded)).Select(View));
    }

    private static async Task<IResult> Recommendations(HttpContext c, NutritionTrackerDbContext db, DateOnly? startDate, CancellationToken ct)
    {
        var user = User(c);
        var start = startDate ?? DateOnly.FromDateTime(DateTime.UtcNow);
        if (start < DateOnly.FromDateTime(DateTime.UtcNow).AddDays(-1) || start > DateOnly.FromDateTime(DateTime.UtcNow).AddDays(30)) return Results.BadRequest(new { detail = "Start date must be within the current planning window." });
        var plan = await GetOrCreatePlan(db, user, start, false, ct);
        return Results.Ok(await ViewPlan(db, user, plan, ct));
    }

    private static async Task<IResult> Regenerate(HttpContext c, NutritionTrackerDbContext db, DateOnly? startDate, CancellationToken ct)
    {
        var plan = await GetOrCreatePlan(db, User(c), startDate ?? DateOnly.FromDateTime(DateTime.UtcNow), true, ct);
        return Results.Ok(await ViewPlan(db, User(c), plan, ct));
    }

    private static async Task<IResult> Swap(HttpContext c, NutritionTrackerDbContext db, DateOnly date, PlannedMealSlot slot, SwapRequest request, CancellationToken ct)
    {
        var user = User(c);
        var plan = await GetOrCreatePlan(db, user, date, false, ct);
        var entry = await db.MealPlanEntries.SingleOrDefaultAsync(x => x.MealPlanId == plan.Id && x.PlannedDate == date && x.Slot == slot, ct);
        if (entry is null) return Results.NotFound();
        var profile = await db.UserProfiles.AsNoTracking().SingleOrDefaultAsync(x => x.UserId == user, ct);
        var excluded = await Exclusions(db, user, ct);
        var current = MealCatalog.ById(entry.CatalogRecipeId);
        var candidates = MealCatalog.All.Where(x => x.Slot == slot && x.Id != entry.CatalogRecipeId && Compatible(x, profile?.DietPreference, excluded))
            .OrderBy(x => Math.Abs(x.Calories - current.Calories) + Math.Abs(x.ProteinGrams - current.ProteinGrams) * 8).ToList();
        var selected = string.IsNullOrWhiteSpace(request.RecipeId) ? candidates.FirstOrDefault() : candidates.FirstOrDefault(x => x.Id == request.RecipeId);
        if (selected is null) return Results.Problem(statusCode: 422, title: "No safe equivalent swap is available.");
        entry.CatalogRecipeId = selected.Id;
        await db.SaveChangesAsync(ct);
        return Results.Ok(new { entry.PlannedDate, entry.Slot, Recipe = View(selected), Reason = "Similar calorie and protein budget; dietary and allergen checks passed." });
    }

    private static async Task<IResult> Saved(HttpContext c, NutritionTrackerDbContext db, CancellationToken ct)
    {
        var saved = await db.SavedCatalogRecipes.AsNoTracking().Where(x => x.UserId == User(c)).Select(x => x.CatalogRecipeId).ToListAsync(ct);
        return Results.Ok(MealCatalog.All.Where(x => saved.Contains(x.Id)).Select(View));
    }
    private static async Task<IResult> Save(HttpContext c, NutritionTrackerDbContext db, string recipeId, CancellationToken ct)
    {
        if (MealCatalog.ByIdOrNull(recipeId) is null) return Results.NotFound();
        var user = User(c);
        if (!await db.SavedCatalogRecipes.AnyAsync(x => x.UserId == user && x.CatalogRecipeId == recipeId, ct)) db.SavedCatalogRecipes.Add(new SavedCatalogRecipe { UserId = user, CatalogRecipeId = recipeId });
        await db.SaveChangesAsync(ct); return Results.NoContent();
    }
    private static async Task<IResult> Unsave(HttpContext c, NutritionTrackerDbContext db, string recipeId, CancellationToken ct)
    {
        await db.SavedCatalogRecipes.Where(x => x.UserId == User(c) && x.CatalogRecipeId == recipeId).ExecuteDeleteAsync(ct); return Results.NoContent();
    }

    private static async Task<IResult> Shopping(HttpContext c, NutritionTrackerDbContext db, CancellationToken ct) => Results.Ok(await db.ShoppingListItems.AsNoTracking().Where(x => x.UserId == User(c)).OrderBy(x => x.IsChecked).ThenBy(x => x.Ingredient).ToListAsync(ct));
    private static async Task<IResult> AddPlanToShopping(HttpContext c, NutritionTrackerDbContext db, DateOnly? startDate, CancellationToken ct)
    {
        var user = User(c); var plan = await GetOrCreatePlan(db, user, startDate ?? DateOnly.FromDateTime(DateTime.UtcNow), false, ct);
        var ingredients = plan.Entries.Select(x => MealCatalog.ById(x.CatalogRecipeId)).SelectMany(x => x.Ingredients).GroupBy(x => (Key: Normalize(x.Name), x.Unit), StringTupleComparer.Instance);
        foreach (var group in ingredients) { var item = await db.ShoppingListItems.SingleOrDefaultAsync(x => x.UserId == user && x.NormalizedIngredient == group.Key.Key && x.Unit == group.Key.Unit, ct); if (item is null) db.ShoppingListItems.Add(new ShoppingListItem { UserId = user, Ingredient = group.First().Name, NormalizedIngredient = group.Key.Key, Quantity = group.Sum(x => x.Quantity), Unit = group.Key.Unit }); else { item.Quantity += group.Sum(x => x.Quantity); item.IsChecked = false; } }
        await db.SaveChangesAsync(ct); return await Shopping(c, db, ct);
    }
    private static async Task<IResult> CheckShopping(HttpContext c, NutritionTrackerDbContext db, Guid id, ShoppingCheckRequest request, CancellationToken ct) { var item = await db.ShoppingListItems.SingleOrDefaultAsync(x => x.Id == id && x.UserId == User(c), ct); if (item is null) return Results.NotFound(); item.IsChecked = request.IsChecked; await db.SaveChangesAsync(ct); return Results.Ok(item); }

    private static async Task<MealPlan> GetOrCreatePlan(NutritionTrackerDbContext db, string user, DateOnly start, bool regenerate, CancellationToken ct)
    {
        var plan = await db.MealPlans.SingleOrDefaultAsync(x => x.UserId == user && x.StartDate == start, ct);
        if (plan is not null && !regenerate)
        {
            await db.Entry(plan).Collection(x => x.Entries).LoadAsync(ct);
            return plan;
        }

        // Delete existing entries in a separate database operation before inserting
        // replacement rows. Keeping deleted and replacement entities tracked at the
        // same time causes EF Core to reject the duplicate composite keys on refresh.
        if (plan is not null)
        {
            await db.MealPlanEntries.Where(x => x.MealPlanId == plan.Id).ExecuteDeleteAsync(ct);
            await db.SaveChangesAsync(ct);
        }
        else
        {
            plan = new MealPlan { UserId = user, StartDate = start };
            db.MealPlans.Add(plan);
            await db.SaveChangesAsync(ct);
        }
        var profile = await db.UserProfiles.AsNoTracking().SingleOrDefaultAsync(x => x.UserId == user, ct);
        var excluded = await Exclusions(db, user, ct);
        var safe = MealCatalog.All.Where(x => Compatible(x, profile?.DietPreference, excluded)).ToList();
        if (safe.Count == 0) throw new BadHttpRequestException("No catalog recipes match the saved dietary exclusions.");
        for (var day = 0; day < 7; day++)
        {
            foreach (var slot in Enum.GetValues<PlannedMealSlot>())
            {
                var choices = safe.Where(x => x.Slot == slot).ToList();
                var choice = choices[(day + (int)slot * 3) % choices.Count];
                db.MealPlanEntries.Add(new MealPlanEntry
                {
                    MealPlanId = plan.Id,
                    PlannedDate = start.AddDays(day),
                    Slot = slot,
                    CatalogRecipeId = choice.Id
                });
            }
        }

        await db.SaveChangesAsync(ct);
        await db.Entry(plan).Collection(x => x.Entries).LoadAsync(ct);
        return plan;
    }

    private static async Task<object> ViewPlan(NutritionTrackerDbContext db, string user, MealPlan plan, CancellationToken ct)
    {
        var saved = await db.SavedCatalogRecipes.AsNoTracking().Where(x => x.UserId == user).Select(x => x.CatalogRecipeId).ToListAsync(ct);
        return new { plan.StartDate, Days = plan.Entries.OrderBy(x => x.PlannedDate).ThenBy(x => x.Slot).GroupBy(x => x.PlannedDate).Select(day => new { Date = day.Key, Meals = day.Select(x => new { x.Slot, Recipe = View(MealCatalog.ById(x.CatalogRecipeId)), IsSaved = saved.Contains(x.CatalogRecipeId), Reason = "Fits your saved diet, exclusions, and meal budget." }) }), Disclaimer = "Meal suggestions are general wellness guidance, not medical advice. Check ingredient labels and seek professional advice for medical needs." };
    }
    private static object View(CatalogRecipe x) => new { x.Id, x.Name, x.Cuisine, x.Slot, x.Calories, x.ProteinGrams, DietTags = x.DietTags, AllergenCodes = x.AllergenCodes, x.Ingredients, x.Preparation, x.PreparationMinutes, SafetyStatus = "Structured ingredient and allergen data complete." };
    private static async Task<HashSet<string>> Exclusions(NutritionTrackerDbContext db, string user, CancellationToken ct) => (await db.UserDietaryPreferences.AsNoTracking().Where(x => x.UserId == user).Select(x => x.Code).ToListAsync(ct)).ToHashSet(StringComparer.OrdinalIgnoreCase);
    private static bool Compatible(CatalogRecipe recipe, DietPreference? diet, HashSet<string> excluded) { if (recipe.AllergenCodes.Any(excluded.Contains) || recipe.Ingredients.Any(x => excluded.Contains($"ingredient.{Normalize(x.Name)}"))) return false; return diet switch { DietPreference.Vegan => recipe.DietTags.Contains("vegan"), DietPreference.Vegetarian => recipe.DietTags.Contains("vegetarian") || recipe.DietTags.Contains("vegan"), DietPreference.Eggetarian => recipe.DietTags.Contains("vegetarian") || recipe.DietTags.Contains("vegan") || recipe.DietTags.Contains("eggetarian"), DietPreference.Pescatarian => !recipe.DietTags.Contains("meat") && !recipe.DietTags.Contains("poultry"), _ => true }; }
    private static string User(HttpContext c) => c.Request.Headers.TryGetValue("X-Development-User-Id", out var x) && !string.IsNullOrWhiteSpace(x) ? x.ToString() : throw new BadHttpRequestException("Development user identity is required.", 401);
    private static string Normalize(string value) => string.Join(' ', value.Trim().ToLowerInvariant().Split(' ', StringSplitOptions.RemoveEmptyEntries));
}

internal sealed class StringTupleComparer : IEqualityComparer<(string Key, string Unit)> { public static readonly StringTupleComparer Instance = new(); public bool Equals((string Key, string Unit) x, (string Key, string Unit) y) => x.Key == y.Key && x.Unit == y.Unit; public int GetHashCode((string Key, string Unit) x) => HashCode.Combine(x.Key, x.Unit); }

internal static class MealCatalog
{
    private static readonly string[] Names = ["Moong dal chilla","Vegetable poha","Ragi idli","Masala oats","Besan cheela","Methi thepla","Sattu paratha","Pesarattu","Appam with stew","Sabudana khichdi","Upma","Aloo matar","Rajma bowl","Chana masala","Palak paneer","Vegetable khichdi","Sambar rice","Lemon rice","Bisi bele bath","Avial bowl","Kadhi chawal","Baingan bharta","Dal dhokli","Misal pav","Bengali shukto","Assamese tenga","Odia dalma","Kashmiri haakh","Goan fish curry","Kerala fish curry","Thai basil tofu","Japanese vegetable donburi","Korean bibimbap","Chinese tofu stir fry","Vietnamese rice bowl","Mediterranean chickpea bowl","Italian lentil minestrone","Greek bean salad","Mexican black bean tacos","Peruvian quinoa bowl","Turkish lentil soup","Lebanese mujaddara","Moroccan vegetable tagine","Ethiopian misir wat","Spanish vegetable paella","French ratatouille","German potato salad","British shepherdless pie","American turkey chili","Brazilian feijoada bowl","Indonesian gado-gado","Malaysian laksa","Filipino chicken adobo","Sri Lankan dhal curry","Nepalese thukpa","Tibetan vegetable momos","Middle Eastern chicken shawarma bowl","African peanut stew","Caribbean jerk chicken bowl","Australian barramundi bowl"];
    private static readonly string[] Cuisines = ["North Indian","South Indian","Punjabi","Gujarati","Maharashtrian","Bengali","Assamese","Odia","Kerala","Kashmiri","Goan","Rajasthani","Thai","Japanese","Korean","Chinese","Vietnamese","Mediterranean","Italian","Greek","Mexican","Turkish","Moroccan","Ethiopian","Spanish","French","German","British","American","Brazilian","Indonesian","Malaysian","Filipino","Sri Lankan","Nepalese","Tibetan","Middle Eastern","Caribbean","Australian"];
    public static readonly IReadOnlyList<CatalogRecipe> All = Names.Select((name, index) => Create(name, Cuisines[index % Cuisines.Length], index)).ToList();
    public static CatalogRecipe ById(string id) => ByIdOrNull(id) ?? throw new InvalidOperationException("Catalog recipe not found.");
    public static CatalogRecipe? ByIdOrNull(string id) => All.FirstOrDefault(x => x.Id == id);
    private static CatalogRecipe Create(string name, string cuisine, int index)
    {
        var slot = (PlannedMealSlot)(index % 3); var fish = name.Contains("fish", StringComparison.OrdinalIgnoreCase) || name.Contains("barramundi", StringComparison.OrdinalIgnoreCase); var chicken = name.Contains("chicken", StringComparison.OrdinalIgnoreCase) || name.Contains("turkey", StringComparison.OrdinalIgnoreCase) || name.Contains("adobo", StringComparison.OrdinalIgnoreCase) || name.Contains("shawarma", StringComparison.OrdinalIgnoreCase) || name.Contains("jerk", StringComparison.OrdinalIgnoreCase); var tags = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { fish ? "pescatarian" : chicken ? "poultry" : "vegetarian" }; if (!fish && !chicken) tags.Add("vegan"); var allergens = new HashSet<string>(StringComparer.OrdinalIgnoreCase); if (name.Contains("peanut", StringComparison.OrdinalIgnoreCase)) allergens.Add("allergen.peanut"); if (fish) allergens.Add("allergen.fish"); return new CatalogRecipe($"catalog-{index + 1:00}", name, cuisine, slot, 280 + index % 7 * 35, 12 + index % 9 * 3, tags, allergens, [new("seasonal vegetables", 250, "g"), new(fish ? "fish" : chicken ? "lean poultry" : "lentils", 150, "g"), new("whole grain", 120, "g")], ["Prepare and wash the ingredients.", "Cook gently with spices and serve warm."], 20 + index % 4 * 10);
    }
}
