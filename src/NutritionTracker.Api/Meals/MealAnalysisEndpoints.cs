using System.Globalization;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.Meals;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Infrastructure.MealVision;
namespace NutritionTracker.Api.Meals;

public static class MealAnalysisEndpoints
{
    public static IEndpointRouteBuilder MapMealAnalysisEndpoints(this IEndpointRouteBuilder routes) { routes.MapPost("/api/meals/analyse", Analyse).DisableAntiforgery(); routes.MapGet("/api/meals/{mealId:guid}/review", Review); return routes; }
    private static async Task<IResult> Analyse(HttpContext context, IMealAnalysisPipeline pipeline, IOptions<MealVisionOptions> visionOptions, CancellationToken ct)
    { var user = User(context); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); if (!context.Request.HasFormContentType) return Results.Problem(statusCode: 415, title: "Multipart form data is required."); if (context.Request.ContentLength > visionOptions.Value.MaximumImageBytes + 64_000L) return Results.Problem(statusCode: 413, title: "Image upload is too large."); var form = await context.Request.ReadFormAsync(ct); var file = form.Files.GetFile("image"); if (file is null || file.Length == 0) return Results.Problem(statusCode: 400, title: "A non-empty image field is required."); if (file.Length > visionOptions.Value.MaximumImageBytes) return Results.Problem(statusCode: 413, title: "Image upload is too large."); await using var input = file.OpenReadStream(); using var memory = new MemoryStream(); await input.CopyToAsync(memory, ct); var consumedAt = DateTime.TryParse(form["consumedAtUtc"], CultureInfo.InvariantCulture, DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal, out var parsed) ? parsed.ToUniversalTime() : DateTime.UtcNow; var hints = form["cuisineHints"].ToString().Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).Take(8).ToList(); try { var result = await pipeline.AnalyseAsync(new(user, memory.ToArray(), file.ContentType, Path.GetFileName(file.FileName), consumedAt, form["locale"].FirstOrDefault() ?? "en-IN", hints, form["mockScenario"].FirstOrDefault(), context.TraceIdentifier), ct); return Results.Created($"/api/meals/{result.MealId}/review", result); } catch (MealVisionImageValidationException x) { return Results.Problem(statusCode: x.StatusCode, title: x.Message); } catch (MealVisionTimeoutException x) { return Results.Problem(statusCode: 504, title: x.Message); } catch (MealVisionSchemaValidationException) { return Results.Problem(statusCode: 502, title: "The provider returned an unusable structured response."); } catch (MealVisionProviderException x) { return ProviderProblem(x); } }
    private static async Task<IResult> Review(HttpContext context, IMealAnalysisPipeline pipeline, Guid mealId, CancellationToken ct) { var user = User(context); if (user is null) return Results.Problem(statusCode: 401, title: "Development user identity is required."); return await pipeline.GetReviewAsync(user, mealId, ct) is { } result ? Results.Ok(result) : Results.NotFound(); }
    private static string? User(HttpContext context) => context.Request.Headers.TryGetValue("X-Development-User-Id", out var user) && !string.IsNullOrWhiteSpace(user) ? user.ToString() : null;
    private static IResult ProviderProblem(MealVisionProviderException exception) => exception.FailureType switch
    {
        ProviderFailureType.RateLimited => Results.Problem(statusCode: 429, title: "Meal analysis is temporarily rate limited. Please try again shortly."),
        ProviderFailureType.Authentication or ProviderFailureType.Configuration => Results.Problem(statusCode: 503, title: "Meal analysis is not configured or is temporarily unavailable."),
        ProviderFailureType.MalformedResponse => Results.Problem(statusCode: 502, title: "The provider returned an unusable structured response."),
        _ => Results.Problem(statusCode: 502, title: "Meal analysis provider is unavailable.")
    };
}


