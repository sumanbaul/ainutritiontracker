using NutritionTracker.Application.MealVision;
namespace NutritionTracker.Api.MealVision;

public sealed record MealVisionDevelopmentRequest(string ImageBase64, string MimeType, string? FileName, string Locale, IReadOnlyList<string>? PreferredLanguages, IReadOnlyList<string>? CuisineHints, string? DietPreference, string? MealContext, string? ClientCorrelationId, string? MockScenario);
public static class MealVisionDevelopmentEndpoints
{
    public static IEndpointRouteBuilder MapMealVisionDevelopmentEndpoints(this IEndpointRouteBuilder routes) { routes.MapPost("/api/development/meal-vision/analyse", Analyse); return routes; }
    private static async Task<IResult> Analyse(HttpContext context, IMealVisionAnalysisService service, MealVisionDevelopmentRequest request, CancellationToken ct)
    { if (!context.Request.Headers.TryGetValue("X-Development-User-Id", out var user) || string.IsNullOrWhiteSpace(user)) return Results.Problem(statusCode: 401, title: "Development user identity is required."); byte[] bytes; try { bytes = Convert.FromBase64String(request.ImageBase64); } catch (FormatException) { return Results.Problem(statusCode: 400, title: "ImageBase64 is invalid."); } try { return Results.Ok(await service.AnalyseAsync(new(bytes, request.MimeType, request.FileName, null, null, request.Locale, request.PreferredLanguages ?? [], request.CuisineHints ?? [], request.DietPreference, request.MealContext, request.ClientCorrelationId, request.MockScenario), ct)); } catch (MealVisionPreflightRejectedException x) { return Results.Problem(statusCode: 422, title: x.Message, extensions: new Dictionary<string, object?> { ["code"] = "ImagePreflightRejected", ["issues"] = x.Issues }); } catch (MealVisionPreflightUnavailableException x) { return Results.Problem(statusCode: 503, title: x.Message); } catch (MealVisionImageValidationException x) { return Results.Problem(statusCode: x.StatusCode, title: x.Message); } catch (MealVisionTimeoutException x) { return Results.Problem(statusCode: 504, title: x.Message); } catch (MealVisionSchemaValidationException x) { return Results.Problem(statusCode: 502, title: "The provider returned an unusable structured response.", detail: x.Message); } catch (MealVisionProviderException x) { return Results.Problem(statusCode: 502, title: x.Message); } }
}

public static class MealVisionStatusEndpoints
{
    public static IEndpointRouteBuilder MapMealVisionStatusEndpoints(this IEndpointRouteBuilder routes)
    {
        routes.MapGet("/api/meal-vision/status", (IMealVisionProviderCatalog catalog, Microsoft.Extensions.Options.IOptions<NutritionTracker.Infrastructure.MealVision.MealVisionOptions> configured) =>
        {
            var selected = configured.Value.Provider.ToString();
            var capabilities = catalog.GetCapabilities();
            var preflight = configured.Value.Preflight;
            return Results.Ok(new { Provider = selected, IsConfigured = capabilities.Any(x => x.Id.Equals(selected, StringComparison.OrdinalIgnoreCase) && x.IsAvailable), PromptVersion = configured.Value.PromptVersion, SchemaVersion = configured.Value.SchemaVersion, Preflight = new { preflight.Enabled, preflight.FailClosed, EndpointConfigured = preflight.Enabled && Uri.TryCreate(preflight.Endpoint, UriKind.Absolute, out _) }, Diagnostics = "Credentials, endpoints, model paths, and provider responses are never returned." });
        });
        return routes;
    }
}

