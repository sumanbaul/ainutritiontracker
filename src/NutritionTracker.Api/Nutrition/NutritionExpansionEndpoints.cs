using Microsoft.EntityFrameworkCore;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Domain.Profiles;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Api.Nutrition;

public sealed record RecipeIngredientRequest(Guid FoodId, decimal Grams, string? Notes);
public sealed record RecipeRequest(string Name, string? Description, string? PreparationNotes, decimal YieldGrams, decimal ServingCount, bool IsSavedTemplate, IReadOnlyList<RecipeIngredientRequest> Ingredients);
public sealed record HabitOperationRequest(decimal? Millilitres, DateTime? RecordedAtUtc, DateTime? StartedAtUtc, DateTime? EndedAtUtc, string? Type, TimeOnly? LocalTime, string? Timezone, bool? IsEnabled, string? ClientOperationId);

public static class NutritionExpansionEndpoints
{
    public static IEndpointRouteBuilder MapNutritionExpansionEndpoints(this IEndpointRouteBuilder routes)
    {
        var recipes = routes.MapGroup("/api/recipes"); recipes.MapGet("", ListRecipes); recipes.MapGet("/{id:guid}", GetRecipe); recipes.MapPost("", CreateRecipe); recipes.MapPut("/{id:guid}", UpdateRecipe); recipes.MapDelete("/{id:guid}", DeleteRecipe);
        var preferences = routes.MapGroup("/api/dietary-preferences"); preferences.MapGet("", GetPreferences); preferences.MapPut("", PutPreferences);
        var habits = routes.MapGroup("/api/habits"); habits.MapGet("/summary", Summary); habits.MapPost("/hydration", AddHydration); habits.MapPost("/fasting", AddFasting); habits.MapPut("/reminders/{id:guid}", PutReminder); habits.MapGet("/reminders", GetReminders);
        return routes;
    }
    private static string User(HttpContext c) => c.Request.Headers.TryGetValue("X-Development-User-Id", out var x) && !string.IsNullOrWhiteSpace(x) ? x.ToString() : throw new BadHttpRequestException("X-Development-User-Id is required.", 401);
    private static IQueryable<Recipe> Owned(NutritionTrackerDbContext db, string user) => db.Recipes.Include(x => x.Ingredients).ThenInclude(x => x.Food).Where(x => x.UserId == user && x.IsActive);
    private static async Task<IResult> ListRecipes(HttpContext c, NutritionTrackerDbContext db, CancellationToken ct) => Results.Ok(await Owned(db, User(c)).AsNoTracking().OrderBy(x => x.Name).Select(x => View(x)).ToListAsync(ct));
    private static async Task<IResult> GetRecipe(HttpContext c, NutritionTrackerDbContext db, Guid id, CancellationToken ct) => await Owned(db, User(c)).AsNoTracking().SingleOrDefaultAsync(x => x.Id == id, ct) is { } r ? Results.Ok(View(r)) : Results.NotFound();
    private static async Task<IResult> CreateRecipe(HttpContext c, NutritionTrackerDbContext db, RecipeRequest r, CancellationToken ct) { var user = User(c); var recipe = await Apply(new Recipe { UserId = user }, r, db, ct); db.Recipes.Add(recipe); await db.SaveChangesAsync(ct); return Results.Created($"/api/recipes/{recipe.Id}", View(recipe)); }
    private static async Task<IResult> UpdateRecipe(HttpContext c, NutritionTrackerDbContext db, Guid id, RecipeRequest r, CancellationToken ct) { var recipe = await Owned(db, User(c)).SingleOrDefaultAsync(x => x.Id == id, ct); if (recipe is null) return Results.NotFound(); await Apply(recipe, r, db, ct); await db.SaveChangesAsync(ct); return Results.Ok(View(recipe)); }
    private static async Task<IResult> DeleteRecipe(HttpContext c, NutritionTrackerDbContext db, Guid id, CancellationToken ct) { var recipe = await db.Recipes.SingleOrDefaultAsync(x => x.Id == id && x.UserId == User(c), ct); if (recipe is null) return Results.NotFound(); recipe.IsActive = false; await db.SaveChangesAsync(ct); return Results.NoContent(); }
    private static async Task<Recipe> Apply(Recipe recipe, RecipeRequest request, NutritionTrackerDbContext db, CancellationToken ct) { if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Length > 160 || request.YieldGrams <= 0 || request.ServingCount <= 0 || request.Ingredients.Count == 0) throw new BadHttpRequestException("Recipe details are invalid."); var ids = request.Ingredients.Select(x => x.FoodId).Distinct().ToList(); if (ids.Count != request.Ingredients.Count || request.Ingredients.Any(x => x.Grams <= 0) || await db.Foods.CountAsync(x => ids.Contains(x.Id) && x.IsActive, ct) != ids.Count) throw new BadHttpRequestException("Recipe ingredients are invalid."); recipe.Name = request.Name.Trim(); recipe.Description = request.Description?.Trim(); recipe.PreparationNotes = request.PreparationNotes?.Trim(); recipe.YieldGrams = request.YieldGrams; recipe.ServingCount = request.ServingCount; recipe.IsSavedTemplate = request.IsSavedTemplate; recipe.Ingredients.Clear(); foreach (var x in request.Ingredients) recipe.Ingredients.Add(new RecipeIngredient { FoodId = x.FoodId, Grams = x.Grams, Notes = x.Notes?.Trim() }); return recipe; }
    private static object View(Recipe r) { var total = r.Ingredients.Sum(i => i.Grams / 100m * i.Food.CaloriesPer100Grams); return new { r.Id, r.Name, r.Description, r.PreparationNotes, r.YieldGrams, r.ServingCount, r.IsSavedTemplate, CaloriesPerServing = decimal.Round(total / r.ServingCount, 1), Ingredients = r.Ingredients.Select(i => new { i.FoodId, Food = i.Food.DisplayName, i.Grams, i.Notes }) }; }
    private static async Task<IResult> GetPreferences(HttpContext c, NutritionTrackerDbContext db, CancellationToken ct) => Results.Ok(await db.UserDietaryPreferences.Where(x => x.UserId == User(c)).OrderBy(x => x.Code).Select(x => new { x.Code, x.Notes }).ToListAsync(ct));
    private static async Task<IResult> PutPreferences(HttpContext c, NutritionTrackerDbContext db, IReadOnlyList<UserDietaryPreference> values, CancellationToken ct) { var user = User(c); db.UserDietaryPreferences.RemoveRange(db.UserDietaryPreferences.Where(x => x.UserId == user)); db.UserDietaryPreferences.AddRange(values.Where(x => !string.IsNullOrWhiteSpace(x.Code)).DistinctBy(x => x.Code.Trim(), StringComparer.OrdinalIgnoreCase).Select(x => new UserDietaryPreference { UserId = user, Code = x.Code.Trim().ToLowerInvariant(), Notes = x.Notes?.Trim() })); await db.SaveChangesAsync(ct); return await GetPreferences(c, db, ct); }
    private static async Task<IResult> AddHydration(HttpContext c, NutritionTrackerDbContext db, HabitOperationRequest r, CancellationToken ct) { var user = User(c); if (r.Millilitres is not > 0 or > 5000) return Results.BadRequest(); if (!string.IsNullOrWhiteSpace(r.ClientOperationId) && await db.HydrationEntries.AnyAsync(x => x.UserId == user && x.ClientOperationId == r.ClientOperationId, ct)) return Results.Conflict(); var entry = new HydrationEntry { UserId = user, Millilitres = r.Millilitres.Value, RecordedAtUtc = r.RecordedAtUtc?.ToUniversalTime() ?? DateTime.UtcNow, ClientOperationId = r.ClientOperationId }; db.HydrationEntries.Add(entry); await db.SaveChangesAsync(ct); return Results.Created("/api/habits/hydration", entry); }
    private static async Task<IResult> AddFasting(HttpContext c, NutritionTrackerDbContext db, HabitOperationRequest r, CancellationToken ct) { var user = User(c); if (r.StartedAtUtc is null || r.EndedAtUtc is null || r.EndedAtUtc <= r.StartedAtUtc) return Results.BadRequest(); if (!string.IsNullOrWhiteSpace(r.ClientOperationId) && await db.FastingWindows.AnyAsync(x => x.UserId == user && x.ClientOperationId == r.ClientOperationId, ct)) return Results.Conflict(); var entry = new FastingWindow { UserId = user, StartedAtUtc = r.StartedAtUtc.Value.ToUniversalTime(), EndedAtUtc = r.EndedAtUtc.Value.ToUniversalTime(), ClientOperationId = r.ClientOperationId }; db.FastingWindows.Add(entry); await db.SaveChangesAsync(ct); return Results.Created("/api/habits/fasting", entry); }
    private static async Task<IResult> GetReminders(HttpContext c, NutritionTrackerDbContext db, CancellationToken ct) => Results.Ok(await db.ReminderPreferences.Where(x => x.UserId == User(c)).OrderBy(x => x.LocalTime).ToListAsync(ct));
    private static async Task<IResult> PutReminder(HttpContext c, NutritionTrackerDbContext db, Guid id, HabitOperationRequest r, CancellationToken ct) { if (string.IsNullOrWhiteSpace(r.Type) || r.LocalTime is null || string.IsNullOrWhiteSpace(r.Timezone)) return Results.BadRequest(); var user = User(c); var item = await db.ReminderPreferences.SingleOrDefaultAsync(x => x.Id == id && x.UserId == user, ct) ?? new ReminderPreference { Id = id, UserId = user }; item.Type = r.Type; item.LocalTime = r.LocalTime.Value; item.Timezone = r.Timezone; item.IsEnabled = r.IsEnabled ?? true; if (item.CreatedAtUtc == default) db.ReminderPreferences.Add(item); await db.SaveChangesAsync(ct); return Results.Ok(item); }
    private static async Task<IResult> Summary(HttpContext c, NutritionTrackerDbContext db, DateOnly? date, string? period, CancellationToken ct)
    {
        var user = User(c);
        var anchor = date ?? DateOnly.FromDateTime(DateTime.UtcNow);
        var normalizedPeriod = period?.Trim().ToLowerInvariant() ?? "daily";
        var (firstDay, days) = normalizedPeriod switch
        {
            "weekly" => (anchor.AddDays(-(((int)anchor.DayOfWeek + 6) % 7)), 7),
            "monthly" => (new DateOnly(anchor.Year, anchor.Month, 1), DateTime.DaysInMonth(anchor.Year, anchor.Month)),
            "daily" => (anchor, 1),
            _ => (default, 0)
        };
        if (days == 0) return Results.BadRequest(new { Detail = "Period must be daily, weekly, or monthly." });

        var start = firstDay.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        var end = start.AddDays(days);
        var summaries = await db.DailyNutritionSummaries.AsNoTracking()
            .Where(x => x.UserId == user && x.SummaryDate >= firstDay && x.SummaryDate < firstDay.AddDays(days))
            .OrderBy(x => x.SummaryDate)
            .ToListAsync(ct);
        var water = await db.HydrationEntries.AsNoTracking().Where(x => x.UserId == user && x.RecordedAtUtc >= start && x.RecordedAtUtc < end).SumAsync(x => (decimal?)x.Millilitres, ct) ?? 0;
        var fastingWindows = await db.FastingWindows.AsNoTracking().Where(x => x.UserId == user && x.EndedAtUtc != null && x.StartedAtUtc < end && x.EndedAtUtc >= start).Select(x => new { x.StartedAtUtc, x.EndedAtUtc }).ToListAsync(ct);
        var fastingMinutes = (int)fastingWindows.Sum(x => (x.EndedAtUtc!.Value - x.StartedAtUtc).TotalMinutes);
        var profile = await db.UserProfiles.AsNoTracking().SingleOrDefaultAsync(x => x.UserId == user, ct);
        var target = profile is null ? null : await db.DailyNutritionTargets.AsNoTracking().Where(x => x.UserProfileId == profile.Id && x.EffectiveDate <= anchor).OrderByDescending(x => x.EffectiveDate).FirstOrDefaultAsync(ct);
        var weights = profile is null ? [] : await db.WeightEntries.AsNoTracking().Where(x => x.UserProfileId == profile.Id && x.RecordedAtUtc < end).OrderBy(x => x.RecordedAtUtc).ToListAsync(ct);
        var periodWeights = weights.Where(x => x.RecordedAtUtc >= start).ToList();
        var calories = summaries.Sum(x => x.TotalCalories);
        var targetCalories = target?.TargetCalories * days;
        var adherence = targetCalories is > 0 ? decimal.Round(calories / targetCalories.Value * 100m, 1) : (decimal?)null;
        return Results.Ok(new
        {
            Period = normalizedPeriod,
            StartDate = firstDay,
            EndDate = firstDay.AddDays(days - 1),
            Days = summaries.Select(x => new { Date = x.SummaryDate, Calories = x.TotalCalories, Meals = x.MealCount }).ToList(),
            TotalCalories = calories,
            AverageCalories = days == 0 ? 0 : decimal.Round(calories / days, 1),
            TotalProteinGrams = summaries.Sum(x => x.TotalProteinGrams),
            TotalCarbohydrateGrams = summaries.Sum(x => x.TotalCarbohydrateGrams),
            TotalFatGrams = summaries.Sum(x => x.TotalFatGrams),
            TotalFibreGrams = summaries.Sum(x => x.TotalFibreGrams),
            ConfirmedMeals = summaries.Sum(x => x.MealCount),
            HydrationMillilitres = water,
            FastingMinutes = fastingMinutes,
            TargetCalories = targetCalories,
            CalorieAdherencePercent = adherence,
            CurrentWeightKg = weights.LastOrDefault()?.WeightKg,
            WeightChangeKg = periodWeights.Count > 1 ? periodWeights[^1].WeightKg - periodWeights[0].WeightKg : (decimal?)null,
            Disclaimer = "Habit and nutrition summaries are informational and are not medical advice."
        });
    }
}
