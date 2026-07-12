using NutritionTracker.Application.MealVision;
namespace NutritionTracker.Api.MealVision;

public sealed record MealVisionDevelopmentRequest(string ImageBase64, string MimeType, string? FileName, string Locale, IReadOnlyList<string>? PreferredLanguages, IReadOnlyList<string>? CuisineHints, string? DietPreference, string? MealContext, string? ClientCorrelationId, string? MockScenario);
public static class MealVisionDevelopmentEndpoints
{
    public static IEndpointRouteBuilder MapMealVisionDevelopmentEndpoints(this IEndpointRouteBuilder routes) { routes.MapPost("/api/development/meal-vision/analyse", Analyse); return routes; }
    private static async Task<IResult> Analyse(HttpContext context, IMealVisionAnalysisService service, MealVisionDevelopmentRequest request, CancellationToken ct)
    { if (!context.Request.Headers.TryGetValue("X-Development-User-Id", out var user) || string.IsNullOrWhiteSpace(user)) return Results.Problem(statusCode: 401, title: "Development user identity is required."); byte[] bytes; try { bytes = Convert.FromBase64String(request.ImageBase64); } catch (FormatException) { return Results.Problem(statusCode: 400, title: "ImageBase64 is invalid."); } try { return Results.Ok(await service.AnalyseAsync(new(bytes, request.MimeType, request.FileName, null, null, request.Locale, request.PreferredLanguages ?? [], request.CuisineHints ?? [], request.DietPreference, request.MealContext, request.ClientCorrelationId, request.MockScenario), ct)); } catch (MealVisionImageValidationException x) { return Results.Problem(statusCode: x.StatusCode, title: x.Message); } catch (MealVisionTimeoutException x) { return Results.Problem(statusCode: 504, title: x.Message); } catch (MealVisionSchemaValidationException x) { return Results.Problem(statusCode: 502, title: "The provider returned an unusable structured response.", detail: x.Message); } catch (MealVisionProviderException x) { return Results.Problem(statusCode: 502, title: x.Message); } }
}

