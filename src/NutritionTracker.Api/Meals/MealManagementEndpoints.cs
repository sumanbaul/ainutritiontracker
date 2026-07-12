using NutritionTracker.Application.Meals;
using NutritionTracker.Domain.Foods;
namespace NutritionTracker.Api.Meals;

public sealed record EditMealItemRequest(Guid? FoodId, decimal? Grams, decimal? ServingQuantity, string? ServingUnitCode, PreparationMethod PreparationMethod);
public sealed record AddMealItemRequest(Guid FoodId, decimal? Grams, decimal? ServingQuantity, string? ServingUnitCode, PreparationMethod PreparationMethod);
public static class MealManagementEndpoints
{
    public static IEndpointRouteBuilder MapMealManagementEndpoints(this IEndpointRouteBuilder routes) { routes.MapPut("/api/meals/{mealId:guid}/items/{itemId:guid}", Edit); routes.MapPost("/api/meals/{mealId:guid}/items", Add); routes.MapDelete("/api/meals/{mealId:guid}/items/{itemId:guid}", Remove); routes.MapPost("/api/meals/{mealId:guid}/confirm", Confirm); routes.MapDelete("/api/meals/{mealId:guid}", Delete); routes.MapGet("/api/meals", History); routes.MapGet("/api/meals/{mealId:guid}/corrections", Corrections); routes.MapGet("/api/dashboard/today", Today); return routes; }
    private static async Task<IResult> Edit(HttpContext c, IMealManagementService s, Guid mealId, Guid itemId, EditMealItemRequest r, CancellationToken ct) => await Run(() => s.EditItemAsync(User(c), mealId, itemId, new(r.FoodId, r.Grams, r.ServingQuantity, r.ServingUnitCode, r.PreparationMethod), ct));
    private static async Task<IResult> Add(HttpContext c, IMealManagementService s, Guid mealId, AddMealItemRequest r, CancellationToken ct) => await Run(() => s.AddItemAsync(User(c), mealId, new(r.FoodId, r.Grams, r.ServingQuantity, r.ServingUnitCode, r.PreparationMethod), ct));
    private static async Task<IResult> Remove(HttpContext c, IMealManagementService s, Guid mealId, Guid itemId, CancellationToken ct) => await Run(() => s.RemoveItemAsync(User(c), mealId, itemId, ct));
    private static async Task<IResult> Confirm(HttpContext c, IMealManagementService s, Guid mealId, CancellationToken ct) => await Run(() => s.ConfirmAsync(User(c), mealId, ct));
    private static async Task<IResult> Delete(HttpContext c, IMealManagementService s, Guid mealId, CancellationToken ct) { var user = TryUser(c); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); return await s.DeleteAsync(user, mealId, ct) ? Results.NoContent() : Results.NotFound(); }
    private static async Task<IResult> History(HttpContext c, IMealManagementService s, DateTime? fromUtc, DateTime? toUtc, int take = 50, CancellationToken ct = default) { var user = TryUser(c); return user is null ? Results.Problem(statusCode: 401, title: "Development user identity is required.") : Results.Ok(await s.GetHistoryAsync(user, fromUtc, toUtc, take, ct)); }
    private static async Task<IResult> Corrections(HttpContext c, IMealManagementService s, Guid mealId, CancellationToken ct) { var user = TryUser(c); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); var result = await s.GetCorrectionsAsync(user, mealId, ct); return result is null ? Results.NotFound() : Results.Ok(result); }
    private static async Task<IResult> Today(HttpContext c, IMealManagementService s, DateOnly? date, CancellationToken ct) { var user = TryUser(c); return user is null ? Results.Problem(statusCode: 401, title: "Development user identity is required.") : Results.Ok(await s.GetSummaryAsync(user, date ?? DateOnly.FromDateTime(DateTime.UtcNow), ct)); }
    private static async Task<IResult> Run(Func<Task<MealReviewResult?>> action) { try { return await action() is { } result ? Results.Ok(result) : Results.NotFound(); } catch (ArgumentException x) { return Results.Problem(statusCode: 400, title: x.Message); } }
    private static string User(HttpContext c) => TryUser(c) ?? throw new BadHttpRequestException("Development user identity is required.", 401);
    private static string? TryUser(HttpContext c) => c.Request.Headers.TryGetValue("X-Development-User-Id", out var user) && !string.IsNullOrWhiteSpace(user) ? user.ToString() : null;
}
