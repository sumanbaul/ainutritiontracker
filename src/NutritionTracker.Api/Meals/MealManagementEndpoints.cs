using NutritionTracker.Application.Meals;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Domain.Meals;
using NutritionTracker.Application.MealVision;
using Microsoft.EntityFrameworkCore;
using NutritionTracker.Infrastructure.Persistence;
namespace NutritionTracker.Api.Meals;

public sealed record EditMealItemRequest(Guid? FoodId, decimal? Grams, decimal? ServingQuantity, string? ServingUnitCode, PreparationMethod PreparationMethod);
public sealed record AddMealItemRequest(Guid FoodId, decimal? Grams, decimal? ServingQuantity, string? ServingUnitCode, PreparationMethod PreparationMethod);
public sealed record ManualMealItemRequest(Guid FoodId, decimal Grams, PreparationMethod PreparationMethod);
public sealed record ManualMealRequest(string? Name, MealType MealType, DateTime ConsumedAtUtc, IReadOnlyList<ManualMealItemRequest> Items);
public sealed record RecipeMealRequest(Guid RecipeId, decimal Servings, MealType MealType, DateTime ConsumedAtUtc);
public sealed record FoodResolutionRequest(string? Query, FoodResolutionMode Mode = FoodResolutionMode.CatalogMatch, string? ProviderId = null, string? ModelId = null);
public static class MealManagementEndpoints
{
    public static IEndpointRouteBuilder MapMealManagementEndpoints(this IEndpointRouteBuilder routes) { routes.MapPost("/api/meals/manual", Manual); routes.MapPost("/api/meals/manual/recipe", RecipeMeal); routes.MapPut("/api/meals/{mealId:guid}/items/{itemId:guid}", Edit); routes.MapPost("/api/meals/{mealId:guid}/items", Add); routes.MapDelete("/api/meals/{mealId:guid}/items/{itemId:guid}", Remove); routes.MapPost("/api/meals/{mealId:guid}/items/{itemId:guid}/resolve", Resolve); routes.MapPost("/api/meals/{mealId:guid}/items/{itemId:guid}/resolve/estimate/confirm", ConfirmEstimate); routes.MapPost("/api/meals/{mealId:guid}/confirm", Confirm); routes.MapDelete("/api/meals/{mealId:guid}", Delete); routes.MapGet("/api/meals", History); routes.MapGet("/api/meals/activity", Activity); routes.MapGet("/api/meals/{mealId:guid}/image", Image); routes.MapGet("/api/meals/{mealId:guid}/corrections", Corrections); routes.MapGet("/api/dashboard/today", Today); return routes; }
    private static async Task<IResult> Manual(HttpContext c, IMealManagementService s, ManualMealRequest r, CancellationToken ct) { try { var result = await s.CreateManualAsync(User(c), new(r.Name, r.MealType, r.ConsumedAtUtc, r.Items.Select(x => new ManualMealItemCommand(x.FoodId, x.Grams, x.PreparationMethod)).ToList()), ct); return Results.Created($"/api/meals/{result.MealId}/review", result); } catch (ArgumentException x) { return Results.Problem(statusCode: 400, title: x.Message); } }
    private static async Task<IResult> RecipeMeal(HttpContext c, NutritionTrackerDbContext db, IMealManagementService s, RecipeMealRequest r, CancellationToken ct) { var user = User(c); if (r.Servings is <= 0 or > 20) return Results.Problem(statusCode: 400, title: "Servings must be between 0 and 20."); var recipe = await db.Recipes.AsNoTracking().Include(x => x.Ingredients).SingleOrDefaultAsync(x => x.Id == r.RecipeId && x.UserId == user && x.IsActive, ct); if (recipe is null) return Results.NotFound(); var multiplier = r.Servings / recipe.ServingCount; var command = new ManualMealCommand(recipe.Name, r.MealType, r.ConsumedAtUtc, recipe.Ingredients.Select(x => new ManualMealItemCommand(x.FoodId, x.Grams * multiplier, PreparationMethod.Unknown)).ToList()); var result = await s.CreateManualAsync(user, command, ct); return Results.Created($"/api/meals/{result.MealId}/review", result); }
    private static async Task<IResult> Edit(HttpContext c, IMealManagementService s, Guid mealId, Guid itemId, EditMealItemRequest r, CancellationToken ct) => await Run(() => s.EditItemAsync(User(c), mealId, itemId, new(r.FoodId, r.Grams, r.ServingQuantity, r.ServingUnitCode, r.PreparationMethod), ct));
    private static async Task<IResult> Add(HttpContext c, IMealManagementService s, Guid mealId, AddMealItemRequest r, CancellationToken ct) => await Run(() => s.AddItemAsync(User(c), mealId, new(r.FoodId, r.Grams, r.ServingQuantity, r.ServingUnitCode, r.PreparationMethod), ct));
    private static async Task<IResult> Remove(HttpContext c, IMealManagementService s, Guid mealId, Guid itemId, CancellationToken ct) => await Run(() => s.RemoveItemAsync(User(c), mealId, itemId, ct));
    private static async Task<IResult> Resolve(HttpContext c, IFoodResolutionAssistant assistant, Guid mealId, Guid itemId, FoodResolutionRequest? request, CancellationToken ct)
    {
        try
        {
            var result = await assistant.SuggestAsync(User(c), mealId, itemId, new(request?.Query, request?.Mode ?? FoodResolutionMode.CatalogMatch, request?.ProviderId, request?.ModelId), ct);
            return result is null ? Results.NotFound() : Results.Ok(result);
        }
        catch (MealVisionProviderException x)
        {
            return x.FailureType switch
            {
                ProviderFailureType.RateLimited => Results.Problem(statusCode: 429, title: "The AI resolver is temporarily rate limited."),
                ProviderFailureType.Authentication or ProviderFailureType.Configuration => Results.Problem(statusCode: 503, title: "The AI resolver is not configured or is temporarily unavailable."),
                ProviderFailureType.Timeout => Results.Problem(statusCode: 504, title: "The AI resolver timed out. Try again."),
                _ => Results.Problem(statusCode: 502, title: "The AI resolver returned an unusable response.")
            };
        }
        catch (ArgumentException x) { return Results.Problem(statusCode: 400, title: x.Message); }
    }
    private static async Task<IResult> ConfirmEstimate(HttpContext c, IFoodResolutionAssistant assistant, Guid mealId, Guid itemId, ConfirmFoodEstimateCommand request, CancellationToken ct) => await Run(() => assistant.ConfirmEstimateAsync(User(c), mealId, itemId, request, ct));
    private static async Task<IResult> Confirm(HttpContext c, IMealManagementService s, Guid mealId, CancellationToken ct) => await Run(() => s.ConfirmAsync(User(c), mealId, ct));
    private static async Task<IResult> Delete(HttpContext c, IMealManagementService s, Guid mealId, CancellationToken ct) { var user = TryUser(c); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); return await s.DeleteAsync(user, mealId, ct) ? Results.NoContent() : Results.NotFound(); }
    private static async Task<IResult> History(HttpContext c, IMealManagementService s, DateTime? fromUtc, DateTime? toUtc, int take = 50, CancellationToken ct = default) { var user = TryUser(c); return user is null ? Results.Problem(statusCode: 401, title: "Development user identity is required.") : Results.Ok(await s.GetHistoryAsync(user, fromUtc, toUtc, take, ct)); }
    private static async Task<IResult> Activity(HttpContext c, IMealManagementService s, DateOnly? fromDate, DateOnly? toDate, CancellationToken ct) { var user = TryUser(c); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); if (fromDate is null || toDate is null || toDate < fromDate || toDate.Value.DayNumber - fromDate.Value.DayNumber >= 371) return Results.Problem(statusCode: 400, title: "Activity range must contain between 1 and 371 days."); return Results.Ok(await s.GetActivityAsync(user, fromDate.Value, toDate.Value, ct)); }
    private static async Task<IResult> Image(HttpContext c, NutritionTrackerDbContext db, IMealImageStorage storage, Guid mealId, CancellationToken ct) { var user = TryUser(c); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); var image = await db.MealImages.AsNoTracking().Where(x => x.MealId == mealId && x.Meal.UserId == user && x.Meal.Status != MealStatus.Deleted).OrderByDescending(x => x.CreatedAtUtc).Select(x => new { x.StorageKey, x.MimeType, x.Sha256Hash }).FirstOrDefaultAsync(ct); if (image is null) return Results.NotFound(); var etag = $"\"{image.Sha256Hash}\""; c.Response.Headers.ETag = etag; c.Response.Headers.CacheControl = "private, max-age=300"; if (c.Request.Headers.IfNoneMatch.Any(x => string.Equals(x, etag, StringComparison.Ordinal))) return Results.StatusCode(StatusCodes.Status304NotModified); try { var bytes = await storage.ReadAsync(image.StorageKey, ct); return bytes is null ? Results.NotFound() : Results.Bytes(bytes, image.MimeType); } catch (InvalidOperationException) { return Results.NotFound(); } }
    private static async Task<IResult> Corrections(HttpContext c, IMealManagementService s, Guid mealId, CancellationToken ct) { var user = TryUser(c); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); var result = await s.GetCorrectionsAsync(user, mealId, ct); return result is null ? Results.NotFound() : Results.Ok(result); }
    private static async Task<IResult> Today(HttpContext c, IMealManagementService s, DateOnly? date, CancellationToken ct) { var user = TryUser(c); return user is null ? Results.Problem(statusCode: 401, title: "Development user identity is required.") : Results.Ok(await s.GetSummaryAsync(user, date ?? DateOnly.FromDateTime(DateTime.UtcNow), ct)); }
    private static async Task<IResult> Run(Func<Task<MealReviewResult?>> action) { try { return await action() is { } result ? Results.Ok(result) : Results.NotFound(); } catch (ArgumentException x) { return Results.Problem(statusCode: 400, title: x.Message); } }
    private static string User(HttpContext c) => TryUser(c) ?? throw new BadHttpRequestException("Development user identity is required.", 401);
    private static string? TryUser(HttpContext c) => c.Request.Headers.TryGetValue("X-Development-User-Id", out var user) && !string.IsNullOrWhiteSpace(user) ? user.ToString() : null;
}
