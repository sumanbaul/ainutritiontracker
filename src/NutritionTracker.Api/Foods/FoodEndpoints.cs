using NutritionTracker.Application.Foods;
using NutritionTracker.Domain.Foods;
namespace NutritionTracker.Api.Foods;

public sealed record GramsRequest(Guid FoodId, decimal Grams);
public sealed record ServingRequest(Guid FoodId, string ServingUnitCode, decimal Quantity);
public sealed record CustomFoodRequest(string DisplayName, string? CanonicalName, string? Description, FoodCategory Category, Cuisine Cuisine, PreparationMethod PreparationMethod, FoodState FoodState, FoodNutritionValues NutritionPer100Grams, IReadOnlyList<string>? Aliases);
public static class FoodEndpoints
{
    public static IEndpointRouteBuilder MapFoodEndpoints(this IEndpointRouteBuilder r) { var g = r.MapGroup("/api/foods"); g.MapGet("/search", Search); g.MapGet("/{id:guid}", Get); g.MapPost("/calculate/grams", Grams); g.MapPost("/calculate/serving", Serving); g.MapPost("/custom", Create); g.MapPut("/custom/{id:guid}", Update); g.MapDelete("/custom/{id:guid}", Delete); return r; }
    private static async Task<IResult> Search(HttpContext c, IFoodService s, string q, FoodCategory? category, Cuisine? cuisine, PreparationMethod? preparationMethod, bool verifiedOnly = false, bool includeUserFoods = true, int limit = 20, CancellationToken ct = default) => string.IsNullOrWhiteSpace(q) || q.Length > 160 ? Results.BadRequest() : Results.Ok(await s.SearchAsync(User(c), q, category, cuisine, preparationMethod, verifiedOnly, includeUserFoods, limit, ct));
    private static async Task<IResult> Get(HttpContext c, IFoodService s, Guid id, CancellationToken ct) => await s.GetAsync(User(c), id, ct) is { } x ? Results.Ok(x) : Results.NotFound();
    private static async Task<IResult> Grams(HttpContext c, IFoodService s, GramsRequest x, CancellationToken ct) => x.Grams <= 0 ? Results.BadRequest() : await s.CalculateGramsAsync(User(c), x.FoodId, x.Grams, ct) is { } r ? Results.Ok(r) : Results.NotFound();
    private static async Task<IResult> Serving(HttpContext c, IFoodService s, ServingRequest x, CancellationToken ct) => x.Quantity <= 0 ? Results.BadRequest() : await s.CalculateServingAsync(User(c), x.FoodId, x.ServingUnitCode, x.Quantity, ct) is { } r ? Results.Ok(r) : Results.NotFound();
    private static async Task<IResult> Create(HttpContext c, IFoodService s, CustomFoodRequest x, CancellationToken ct) { if (!Valid(x)) return Results.BadRequest(); try { var food = await s.CreateCustomAsync(User(c), Command(x), ct); return Results.Created($"/api/foods/{food.Id}", food); } catch (InvalidOperationException) { return Results.Conflict(); } }
    private static async Task<IResult> Update(HttpContext c, IFoodService s, Guid id, CustomFoodRequest x, CancellationToken ct) => !Valid(x) ? Results.BadRequest() : await s.UpdateCustomAsync(User(c), id, Command(x), ct) is { } food ? Results.Ok(food) : Results.NotFound();
    private static async Task<IResult> Delete(HttpContext c, IFoodService s, Guid id, CancellationToken ct) => await s.DeactivateCustomAsync(User(c), id, ct) ? Results.NoContent() : Results.NotFound();
    private static bool Valid(CustomFoodRequest x) => !string.IsNullOrWhiteSpace(x.DisplayName) && x.DisplayName == x.DisplayName.Trim() && x.DisplayName.Length <= 160 && x.Description?.Length <= 1000;
    private static CustomFoodCommand Command(CustomFoodRequest x) => new(x.DisplayName, x.CanonicalName, x.Description, x.Category, x.Cuisine, x.PreparationMethod, x.FoodState, x.NutritionPer100Grams, x.Aliases ?? []);
    private static string User(HttpContext c) => c.Request.Headers.TryGetValue("X-Development-User-Id", out var x) && !string.IsNullOrWhiteSpace(x) ? x.ToString() : throw new BadHttpRequestException("X-Development-User-Id is required.", 401);
}
