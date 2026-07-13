using Microsoft.EntityFrameworkCore;
using NutritionTracker.Application.Meals;
using NutritionTracker.Domain.Meals;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Api.Privacy;

public static class PrivacyEndpoints
{
    public static IEndpointRouteBuilder MapPrivacyEndpoints(this IEndpointRouteBuilder routes)
    {
        routes.MapGet("/api/account/export", Export);
        routes.MapDelete("/api/account", Delete);
        return routes;
    }

    private static string User(HttpContext c) => c.Request.Headers.TryGetValue("X-Development-User-Id", out var value) && !string.IsNullOrWhiteSpace(value) ? value.ToString() : throw new BadHttpRequestException("Authentication is required.", 401);

    private static async Task<IResult> Export(HttpContext context, NutritionTrackerDbContext db, CancellationToken ct)
    {
        var user = User(context);
        var export = new
        {
            ExportedAtUtc = DateTime.UtcNow,
            Profile = await db.UserProfiles.AsNoTracking().SingleOrDefaultAsync(x => x.UserId == user, ct),
            Weights = await db.WeightEntries.AsNoTracking().Where(x => x.UserProfile.UserId == user).ToListAsync(ct),
            Meals = await db.Meals.AsNoTracking().Where(x => x.UserId == user && x.Status != MealStatus.Deleted).Select(x => new { x.Id, x.Name, x.MealType, x.ConsumedAtUtc, x.Status, x.TotalCalories, x.TotalProteinGrams, x.TotalCarbohydrateGrams, x.TotalFatGrams, x.TotalFibreGrams }).ToListAsync(ct),
            Recipes = await db.Recipes.AsNoTracking().Where(x => x.UserId == user && x.IsActive).Select(x => new { x.Id, x.Name, x.Description, x.YieldGrams, x.ServingCount }).ToListAsync(ct),
            Hydration = await db.HydrationEntries.AsNoTracking().Where(x => x.UserId == user).ToListAsync(ct),
            Fasting = await db.FastingWindows.AsNoTracking().Where(x => x.UserId == user).ToListAsync(ct),
            Reminders = await db.ReminderPreferences.AsNoTracking().Where(x => x.UserId == user).ToListAsync(ct),
            DietaryPreferences = await db.UserDietaryPreferences.AsNoTracking().Where(x => x.UserId == user).ToListAsync(ct),
            Notice = "Nutrition and AI estimates are informational and are not medical advice. Image bytes are intentionally excluded from this JSON export."
        };
        context.Response.Headers.ContentDisposition = $"attachment; filename=nutrilens-export-{DateTime.UtcNow:yyyyMMdd}.json";
        return Results.Json(export);
    }

    private static async Task<IResult> Delete(HttpContext context, NutritionTrackerDbContext db, IMealImageStorage storage, CancellationToken ct)
    {
        var user = User(context);
        var keys = await db.MealImages.AsNoTracking().Where(x => x.Meal.UserId == user).Select(x => x.StorageKey).ToListAsync(ct);
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await db.UserFoodCorrections.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.DailyNutritionSummaries.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.Meals.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.Recipes.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.HydrationEntries.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.FastingWindows.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.ReminderPreferences.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.UserDietaryPreferences.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.Foods.Where(x => x.IsUserCreated && x.OwnerUserId == user).ExecuteDeleteAsync(ct);
        await db.UserProfiles.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        await db.IdempotencyRecords.Where(x => x.UserId == user).ExecuteDeleteAsync(ct);
        if (Guid.TryParse(user, out var applicationUserId)) await db.ApplicationUsers.Where(x => x.Id == applicationUserId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
        foreach (var key in keys) { try { await storage.DeleteAsync(key, ct); } catch { /* private orphan cleanup is retried operationally */ } }
        return Results.NoContent();
    }
}
