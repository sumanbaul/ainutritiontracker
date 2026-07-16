using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.Foods;
using NutritionTracker.Application.Meals;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Domain.Meals;
using NutritionTracker.Infrastructure.MealVision;
using NutritionTracker.Infrastructure.Persistence;

namespace NutritionTracker.Infrastructure.Meals;

public interface IFoodResolutionModel
{
    Task<ResolutionModelResult> RankAsync(byte[] image, string mimeType, string query, IReadOnlyList<ResolutionCandidate> candidates, string? providerId, string? modelId, CancellationToken ct);
    Task<EstimateModelResult> EstimateAsync(byte[] image, string mimeType, string query, string? providerId, string? modelId, CancellationToken ct);
}

public sealed record ResolutionCandidate(Guid Id, string Name, IReadOnlyList<string> Aliases);
public sealed record RankedCandidate(Guid CandidateId, decimal Confidence, string Rationale);
public sealed record ResolutionModelResult(IReadOnlyList<RankedCandidate> Suggestions, string Provider, string? Model);
public sealed record EstimateModelResult(string Name, string? Description, FoodCategory Category, Cuisine Cuisine, PreparationMethod PreparationMethod, FoodState FoodState, FoodNutritionValues Nutrition, decimal Confidence, IReadOnlyList<string> Assumptions, string Provider, string? Model);

public sealed class FoodResolutionAssistant(
    NutritionTrackerDbContext db,
    IMealImageStorage storage,
    IFoodNameNormalizer normalizer,
    IFoodResolutionModel model,
    IMealManagementService mealManagement,
    IDataProtectionProvider dataProtection) : IFoodResolutionAssistant
{
    private readonly IDataProtector _tokens = dataProtection.CreateProtector("NutritionTracker.FoodEstimate.v1");

    public async Task<FoodResolutionResult?> SuggestAsync(string userId, Guid mealId, Guid mealItemId, FoodResolutionCommand command, CancellationToken ct)
    {
        var meal = await db.Meals.AsNoTracking().Include(x => x.Items).Include(x => x.Images)
            .SingleOrDefaultAsync(x => x.Id == mealId && x.UserId == userId && x.Status == MealStatus.AwaitingReview, ct);
        var item = meal?.Items.SingleOrDefault(x => x.Id == mealItemId);
        if (meal is null || item is null) return null;

        var query = Clean(command.Query ?? item.DetectedName);
        if (query.Length is 0 or > 160) throw new ArgumentException("Resolution query must be between 1 and 160 characters.");
        var normalized = normalizer.Normalize(query);

        if (command.Mode == FoodResolutionMode.CatalogMatch)
        {
            var foods = await db.Foods.AsNoTracking().Include(x => x.Aliases)
                .Where(x => x.IsActive && (!x.IsUserCreated || x.OwnerUserId == userId) &&
                    (x.NormalizedName.Contains(normalized) || x.Aliases.Any(a => a.NormalizedAlias.Contains(normalized))))
                .OrderByDescending(x => x.NormalizedName == normalized || x.Aliases.Any(a => a.NormalizedAlias == normalized))
                .ThenByDescending(x => x.IsVerified).ThenBy(x => x.DisplayName).Take(20).ToListAsync(ct);
            if (foods.Count == 0)
                return new(mealId, mealItemId, item.DetectedName, query, [], "No catalog food matched the search text.", null, "Unavailable", null);

            var image = await ReadImage(meal, ct);
            if (image is null) return new(mealId, mealItemId, item.DetectedName, query, [], "The meal image is unavailable.", null, "Unavailable", null);
            var ranked = await model.RankAsync(image.Value.Bytes, image.Value.MimeType, query,
                foods.Select(x => new ResolutionCandidate(x.Id, x.CanonicalName, x.Aliases.Select(a => a.Alias).Take(6).ToList())).ToList(), command.ProviderId, command.ModelId, ct);
            var allowed = foods.ToDictionary(x => x.Id);
            var suggestions = ranked.Suggestions.Where(x => allowed.ContainsKey(x.CandidateId)).DistinctBy(x => x.CandidateId).Take(5)
                .Select(x => { var food = allowed[x.CandidateId]; return new FoodResolutionSuggestion(food.Id, food.DisplayName, food.CanonicalName, Values(food), decimal.Clamp(x.Confidence, 0, 1), Clean(x.Rationale), food.IsVerified, food.IsUserCreated); }).ToList();
            return new(mealId, mealItemId, item.DetectedName, query, suggestions, suggestions.Count == 0 ? "AI found no safe catalog match." : null, null, ranked.Provider, ranked.Model);
        }

        var estimateImage = await ReadImage(meal, ct);
        if (estimateImage is null) return new(mealId, mealItemId, item.DetectedName, query, [], "The meal image is unavailable.", null, "Unavailable", null);
        var estimate = await model.EstimateAsync(estimateImage.Value.Bytes, estimateImage.Value.MimeType, query, command.ProviderId, command.ModelId, ct);
        ValidateNutrition(estimate.Nutrition);
        var payload = new EstimateToken(userId, mealId, mealItemId, query, estimate.Provider, estimate.Model, DateTime.UtcNow.AddMinutes(15));
        var token = _tokens.Protect(JsonSerializer.Serialize(payload));
        var draft = new FoodNutritionEstimate(query, Clean(estimate.Description), estimate.Category, estimate.Cuisine, estimate.PreparationMethod, estimate.FoodState, estimate.Nutrition, decimal.Clamp(estimate.Confidence, 0, 1), estimate.Assumptions.Select(Clean).Where(x => x.Length > 0).Take(8).ToList(), "AI estimate — review every value before saving.", token);
        return new(mealId, mealItemId, item.DetectedName, query, [], null, draft, estimate.Provider, estimate.Model);
    }

    public async Task<MealReviewResult?> ConfirmEstimateAsync(string userId, Guid mealId, Guid mealItemId, ConfirmFoodEstimateCommand command, CancellationToken ct)
    {
        EstimateToken payload;
        try { payload = JsonSerializer.Deserialize<EstimateToken>(_tokens.Unprotect(command.EstimateToken)) ?? throw new InvalidOperationException(); }
        catch { throw new ArgumentException("The AI estimate has expired or is invalid."); }
        if (payload.ExpiresUtc < DateTime.UtcNow || payload.UserId != userId || payload.MealId != mealId || payload.MealItemId != mealItemId)
            throw new ArgumentException("The AI estimate has expired or does not belong to this food item.");
        if (command.Grams <= 0 || string.IsNullOrWhiteSpace(command.Name) || command.Name.Length > 160) throw new ArgumentException("Review the food name and grams.");
        ValidateNutrition(command.NutritionPer100Grams);
        return await mealManagement.ApplyEstimatedFoodAsync(userId, mealId, mealItemId, command, payload.Provider, payload.Model, ct);
    }

    private async Task<(byte[] Bytes, string MimeType)?> ReadImage(Meal meal, CancellationToken ct)
    {
        var image = meal.Images.OrderByDescending(x => x.CreatedAtUtc).FirstOrDefault();
        if (image is null) return null;
        var bytes = await storage.ReadAsync(image.StorageKey, ct);
        return bytes is { Length: > 0 } ? (bytes, image.MimeType) : null;
    }
    private static string Clean(string? value) => new string((value ?? string.Empty).Where(c => !char.IsControl(c)).ToArray()).Trim();
    private static FoodNutritionValues Values(Food x) => new(x.CaloriesPer100Grams, x.ProteinGramsPer100Grams, x.CarbohydrateGramsPer100Grams, x.FatGramsPer100Grams, x.FibreGramsPer100Grams, x.SugarGramsPer100Grams, x.SodiumMilligramsPer100Grams);
    private static void ValidateNutrition(FoodNutritionValues x) { if (x.Calories <= 0 || x.Calories > 1000 || x.Protein < 0 || x.Protein > 100 || x.Carbohydrates < 0 || x.Carbohydrates > 100 || x.Fat < 0 || x.Fat > 100 || x.Fibre < 0 || x.Fibre > 100 || x.Sugar is < 0 or > 100 || x.SodiumMilligrams is < 0 or > 100000) throw new ArgumentException("AI nutrition values are outside supported ranges."); }
    private sealed record EstimateToken(string UserId, Guid MealId, Guid MealItemId, string Query, string Provider, string? Model, DateTime ExpiresUtc);
}

public sealed class FoodResolutionModel(HttpClient client, IOptions<MealVisionOptions> options) : IFoodResolutionModel
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);
    public async Task<ResolutionModelResult> RankAsync(byte[] image, string mimeType, string query, IReadOnlyList<ResolutionCandidate> candidates, string? providerId, string? modelId, CancellationToken ct)
    {
        if (IsMock(providerId)) return new([new(candidates[0].Id, .90m, "AI-ranked catalog candidate; review before applying.")], "Mock", "mock-resolution-v1");
        var list = string.Join('\n', candidates.Select(x => $"- id={x.Id}; name={x.Name}; aliases={string.Join(", ", x.Aliases)}"));
        var prompt = $"Target search text: {query}\nCandidates:\n{list}\nRank only defensible matches for the target. The image is context only; do not identify other meal foods. Return no suggestions when ambiguous.";
        var raw = await Send(image, mimeType, "Choose only candidate IDs supplied by the server. Never return nutrition.", prompt, modelId, "food_catalog_resolution", CatalogSchema, ct);
        var parsed = JsonSerializer.Deserialize<CatalogResponse>(raw.Text, Json) ?? throw Malformed();
        return new(parsed.Suggestions.Select(x => new RankedCandidate(x.CandidateId, x.Confidence, x.Rationale)).ToList(), "OpenAi", raw.Model);
    }
    public async Task<EstimateModelResult> EstimateAsync(byte[] image, string mimeType, string query, string? providerId, string? modelId, CancellationToken ct)
    {
        if (IsMock(providerId)) return new(query, "AI-estimated nutrition for user review.", FoodCategory.Condiment, Cuisine.General, PreparationMethod.Mixed, FoodState.Prepared, new(150, 1, 10, 12, 2, 5, 1200), .55m, ["Generic recipe and serving composition assumed."], "Mock", "mock-estimate-v1");
        var prompt = $"Estimate nutrition per 100 grams for exactly this unresolved food: {query}. Use the image only as supporting context. State assumptions and remain conservative.";
        var raw = await Send(image, mimeType, "Create a reviewable nutrition estimate for the named food. Do not substitute another visible meal item.", prompt, modelId, "food_nutrition_estimate", EstimateSchema, ct);
        var x = JsonSerializer.Deserialize<EstimateResponse>(raw.Text, Json) ?? throw Malformed();
        return new(x.Name, x.Description, Parse<FoodCategory>(x.Category), Parse<Cuisine>(x.Cuisine), Parse<PreparationMethod>(x.PreparationMethod), Parse<FoodState>(x.FoodState), new(x.Calories, x.Protein, x.Carbohydrates, x.Fat, x.Fibre, x.Sugar, x.SodiumMilligrams), x.Confidence, x.Assumptions, "OpenAi", raw.Model);
    }
    private bool IsMock(string? providerId) => string.Equals(providerId, "Mock", StringComparison.OrdinalIgnoreCase) || providerId is null && options.Value.Provider == MealVisionProviderKind.Mock;
    private async Task<(string Text, string? Model)> Send(byte[] image, string mimeType, string instructions, string prompt, string? modelId, string schemaName, JsonElement schema, CancellationToken ct)
    {
        var o = options.Value.OpenAi;
        if (string.IsNullOrWhiteSpace(o.ApiKey)) throw new MealVisionProviderException("OpenAI food resolution is not configured.", ProviderFailureType.Configuration);
        using var request = new HttpRequestMessage(HttpMethod.Post, "responses");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", o.ApiKey);
        request.Content = JsonContent.Create(new { model = modelId ?? o.Model, instructions, input = new[] { new { role = "user", content = new object[] { new { type = "input_text", text = prompt }, new { type = "input_image", image_url = $"data:{mimeType};base64,{Convert.ToBase64String(image)}", detail = o.ImageDetail } } } }, max_output_tokens = o.MaxOutputTokens, text = new { format = new { type = "json_schema", name = schemaName, strict = true, schema } } });
        using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct);
        if (!response.IsSuccessStatusCode) throw new MealVisionProviderException(response.StatusCode == (HttpStatusCode)429 ? "OpenAI rate limit reached." : "OpenAI food resolution is unavailable.", response.StatusCode == (HttpStatusCode)429 ? ProviderFailureType.RateLimited : ProviderFailureType.Network);
        using var document = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        var text = Extract(document.RootElement) ?? throw Malformed();
        return (text, document.RootElement.TryGetProperty("model", out var m) ? m.GetString() : modelId ?? o.Model);
    }
    private static string? Extract(JsonElement root) { if (root.TryGetProperty("output_text", out var direct)) return direct.GetString(); if (!root.TryGetProperty("output", out var output)) return null; foreach (var item in output.EnumerateArray()) if (item.TryGetProperty("content", out var content)) foreach (var part in content.EnumerateArray()) if (part.TryGetProperty("text", out var text)) return text.GetString(); return null; }
    private static T Parse<T>(string value) where T : struct, Enum => Enum.TryParse<T>(value, true, out var result) ? result : default;
    private static MealVisionProviderException Malformed() => new("AI returned an invalid food-resolution response.", ProviderFailureType.MalformedResponse);
    private sealed record CatalogResponse(IReadOnlyList<CatalogSuggestion> Suggestions);
    private sealed record CatalogSuggestion(Guid CandidateId, decimal Confidence, string Rationale);
    private sealed record EstimateResponse(string Name, string? Description, string Category, string Cuisine, string PreparationMethod, string FoodState, decimal Calories, decimal Protein, decimal Carbohydrates, decimal Fat, decimal Fibre, decimal? Sugar, decimal? SodiumMilligrams, decimal Confidence, IReadOnlyList<string> Assumptions);
    private static readonly JsonElement CatalogSchema = JsonDocument.Parse("""{"type":"object","additionalProperties":false,"required":["suggestions"],"properties":{"suggestions":{"type":"array","maxItems":5,"items":{"type":"object","additionalProperties":false,"required":["candidateId","confidence","rationale"],"properties":{"candidateId":{"type":"string","format":"uuid"},"confidence":{"type":"number","minimum":0,"maximum":1},"rationale":{"type":"string"}}}}}}""").RootElement.Clone();
    private static readonly JsonElement EstimateSchema = JsonDocument.Parse("""{"type":"object","additionalProperties":false,"required":["name","description","category","cuisine","preparationMethod","foodState","calories","protein","carbohydrates","fat","fibre","sugar","sodiumMilligrams","confidence","assumptions"],"properties":{"name":{"type":"string"},"description":{"type":["string","null"]},"category":{"type":"string"},"cuisine":{"type":"string"},"preparationMethod":{"type":"string"},"foodState":{"type":"string"},"calories":{"type":"number"},"protein":{"type":"number"},"carbohydrates":{"type":"number"},"fat":{"type":"number"},"fibre":{"type":"number"},"sugar":{"type":["number","null"]},"sodiumMilligrams":{"type":["number","null"]},"confidence":{"type":"number","minimum":0,"maximum":1},"assumptions":{"type":"array","items":{"type":"string"}}}}""").RootElement.Clone();
}
