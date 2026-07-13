using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.Foods;
using NutritionTracker.Application.Meals;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Domain.Meals;
using NutritionTracker.Infrastructure.Persistence;
using System.Net.Http.Headers;
using System.Text;
using System.Globalization;
namespace NutritionTracker.Infrastructure.Meals;

public sealed class MealAnalysisOptions
{
    public const string SectionName = "MealAnalysis";
    public string Provider { get; init; } = "Local";
    public string LocalStorageRoot { get; init; } = "App_Data/meal-images";
    public bool RetainImages { get; init; } = true;
    public int RetentionDays { get; init; } = 30;
    public bool DeleteOnMealDelete { get; init; } = true;
    /// <summary>Explicit opt-in for self-hosted Production deployments with protected local disk.</summary>
    public bool AllowLocalInProduction { get; init; }
    public int MaximumImageBytes { get; init; } = 5_000_000;
    public string[] AllowedMimeTypes { get; init; } = ["image/jpeg", "image/png", "image/webp"];
    public int MaximumFileNameLength { get; init; } = 160;
    public S3StorageOptions S3 { get; init; } = new();
}
public sealed class S3StorageOptions { public string Endpoint { get; init; } = string.Empty; public string Region { get; init; } = "auto"; public string Bucket { get; init; } = string.Empty; public string AccessKey { get; init; } = string.Empty; public string SecretKey { get; init; } = string.Empty; public bool ForcePathStyle { get; init; } = true; }
public sealed class LocalMealImageStorage(IOptions<MealAnalysisOptions> options) : IMealImageStorage
{
    public async Task<string> SaveAsync(ReadOnlyMemory<byte> image, string mimeType, string userId, Guid mealId, CancellationToken ct) { var extension = mimeType switch { "image/jpeg" => ".jpg", "image/png" => ".png", "image/webp" => ".webp", _ => throw new MealVisionImageValidationException("Unsupported image type.", 415) }; var root = Root(); Directory.CreateDirectory(root); var safeUser = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(userId))).ToLowerInvariant()[..24]; var key = $"{safeUser}/{DateTime.UtcNow:yyyy/MM}/{mealId:N}{extension}"; var path = Resolve(root, key); Directory.CreateDirectory(Path.GetDirectoryName(path)!); await File.WriteAllBytesAsync(path, image.ToArray(), ct); return key; }
    public async Task<byte[]?> ReadAsync(string storageKey, CancellationToken ct) { if (!options.Value.RetainImages) return null; var path = Resolve(Root(), storageKey); return File.Exists(path) ? await File.ReadAllBytesAsync(path, ct) : null; }
    public Task DeleteAsync(string storageKey, CancellationToken ct) { ct.ThrowIfCancellationRequested(); var path = Resolve(Root(), storageKey); if (File.Exists(path)) File.Delete(path); return Task.CompletedTask; }
    private string Root() => Path.GetFullPath(options.Value.LocalStorageRoot).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
    private static string Resolve(string root, string storageKey) { var path = Path.GetFullPath(Path.Combine(root, storageKey.Replace('/', Path.DirectorySeparatorChar))); if (!path.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Invalid meal-image storage path."); return path; }
}

public sealed class S3MealImageStorage(IOptions<MealAnalysisOptions> options, IHttpClientFactory clients) : IMealImageStorage
{
    private readonly MealAnalysisOptions _options = options.Value;
    public async Task<string> SaveAsync(ReadOnlyMemory<byte> image, string mimeType, string userId, Guid mealId, CancellationToken ct)
    {
        if (!_options.AllowedMimeTypes.Contains(mimeType, StringComparer.OrdinalIgnoreCase) || image.Length > _options.MaximumImageBytes) throw new MealVisionImageValidationException("Unsupported or oversized image.", 415);
        var extension = mimeType switch { "image/jpeg" => ".jpg", "image/png" => ".png", "image/webp" => ".webp", _ => throw new MealVisionImageValidationException("Unsupported image type.", 415) };
        var safeUser = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(userId))).ToLowerInvariant()[..24];
        var key = $"meal-images/{safeUser}/{DateTime.UtcNow:yyyy/MM}/{mealId:N}{extension}";
        using var request = Create(HttpMethod.Put, key, image.Span, mimeType);
        using var response = await clients.CreateClient("MealImageS3").SendAsync(request, ct);
        response.EnsureSuccessStatusCode(); return key;
    }
    public async Task<byte[]?> ReadAsync(string storageKey, CancellationToken ct)
    {
        ValidateKey(storageKey); using var request = Create(HttpMethod.Get, storageKey, [], null); using var response = await clients.CreateClient("MealImageS3").SendAsync(request, ct);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound) return null; response.EnsureSuccessStatusCode(); return await response.Content.ReadAsByteArrayAsync(ct);
    }
    public async Task DeleteAsync(string storageKey, CancellationToken ct) { ValidateKey(storageKey); using var request = Create(HttpMethod.Delete, storageKey, [], null); using var response = await clients.CreateClient("MealImageS3").SendAsync(request, ct); if (response.StatusCode != System.Net.HttpStatusCode.NotFound) response.EnsureSuccessStatusCode(); }
    private HttpRequestMessage Create(HttpMethod method, string key, ReadOnlySpan<byte> body, string? contentType)
    {
        ValidateKey(key); var s3 = _options.S3; var endpoint = new Uri(s3.Endpoint.TrimEnd('/') + "/"); var escapedKey = string.Join('/', key.Split('/').Select(Uri.EscapeDataString));
        var uri = new Uri(endpoint, $"{Uri.EscapeDataString(s3.Bucket)}/{escapedKey}"); var now = DateTime.UtcNow; var date = now.ToString("yyyyMMdd", CultureInfo.InvariantCulture); var amzDate = now.ToString("yyyyMMdd'T'HHmmss'Z'", CultureInfo.InvariantCulture);
        var payloadHash = Convert.ToHexString(SHA256.HashData(body)).ToLowerInvariant(); var host = uri.IsDefaultPort ? uri.Host : $"{uri.Host}:{uri.Port}";
        var canonicalHeaders = $"host:{host}\nx-amz-content-sha256:{payloadHash}\nx-amz-date:{amzDate}\n"; const string signedHeaders = "host;x-amz-content-sha256;x-amz-date";
        var canonical = $"{method.Method}\n{uri.AbsolutePath}\n\n{canonicalHeaders}\n{signedHeaders}\n{payloadHash}"; var scope = $"{date}/{s3.Region}/s3/aws4_request";
        var toSign = $"AWS4-HMAC-SHA256\n{amzDate}\n{scope}\n{HexSha(canonical)}"; var signingKey = Hmac(Hmac(Hmac(Hmac(Encoding.UTF8.GetBytes("AWS4" + s3.SecretKey), date), s3.Region), "s3"), "aws4_request"); var signature = Convert.ToHexString(Hmac(signingKey, toSign)).ToLowerInvariant();
        var request = new HttpRequestMessage(method, uri); request.Headers.TryAddWithoutValidation("x-amz-date", amzDate); request.Headers.TryAddWithoutValidation("x-amz-content-sha256", payloadHash); request.Headers.Authorization = new AuthenticationHeaderValue("AWS4-HMAC-SHA256", $"Credential={s3.AccessKey}/{scope}, SignedHeaders={signedHeaders}, Signature={signature}");
        if (method == HttpMethod.Put) { request.Content = new ByteArrayContent(body.ToArray()); request.Content.Headers.ContentType = new MediaTypeHeaderValue(contentType!); }
        return request;
    }
    private static void ValidateKey(string key) { if (string.IsNullOrWhiteSpace(key) || key.Contains("..", StringComparison.Ordinal) || key.StartsWith('/') || key.Contains('\\')) throw new InvalidOperationException("Invalid meal-image storage key."); }
    private static string HexSha(string value) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value))).ToLowerInvariant();
    private static byte[] Hmac(byte[] key, string value) => HMACSHA256.HashData(key, Encoding.UTF8.GetBytes(value));
}
public sealed class FoodMatcher(NutritionTrackerDbContext db, IFoodNameNormalizer normalizer) : IFoodMatcher
{
    public async Task<FoodMatchResult?> MatchAsync(string userId, string detectedName, string? regionalName, IReadOnlyList<string>? alternatives, CancellationToken ct)
    {
        var names = new[] { detectedName, regionalName }.Concat(alternatives ?? []).Where(x => !string.IsNullOrWhiteSpace(x)).SelectMany(x => FoodMatchNameVariants.Create(normalizer.Normalize(x!))).Distinct().ToArray();
        var matches = await db.Foods.AsNoTracking().Where(x => x.IsActive && (!x.IsUserCreated || x.OwnerUserId == userId) && (names.Contains(x.NormalizedName) || x.Aliases.Any(a => names.Contains(a.NormalizedAlias)))).OrderByDescending(x => x.IsVerified).Take(3).ToListAsync(ct);
        if (matches.Count != 1) return null; // Never guess between regional dishes with multiple safe candidates.
        var food = matches[0]; var confidence = names.Contains(food.NormalizedName) ? 1m : .95m;
        return new(food.Id, food.CanonicalName, new(food.CaloriesPer100Grams, food.ProteinGramsPer100Grams, food.CarbohydrateGramsPer100Grams, food.FatGramsPer100Grams, food.FibreGramsPer100Grams, food.SugarGramsPer100Grams, food.SodiumMilligramsPer100Grams), confidence);
    }
}

/// <summary>Conservative name cleanup for model labels. It never invents a food or turns a fuzzy match into a match.</summary>
public static class FoodMatchNameVariants
{
    private static readonly HashSet<string> PreparationWords = new(StringComparer.Ordinal) { "cooked", "steamed", "fried", "grilled", "roasted", "sauteed", "sautéed", "chopped", "sliced", "assorted", "prepared" };
    public static IReadOnlyList<string> Create(string normalized)
    {
        if (string.IsNullOrWhiteSpace(normalized)) return [];
        var values = new HashSet<string>(StringComparer.Ordinal) { normalized };
        var tokens = normalized.Split(' ', StringSplitOptions.RemoveEmptyEntries).Where(x => !PreparationWords.Contains(x)).ToArray();
        if (tokens.Length > 0 && tokens.Length < normalized.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length) values.Add(string.Join(' ', tokens));
        foreach (var value in values.ToArray())
        {
            var parts = value.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length > 0 && parts[^1].Length > 3 && parts[^1].EndsWith('s')) values.Add(string.Join(' ', parts[..^1].Append(parts[^1][..^1])));
        }
        return values.ToArray();
    }
}
public sealed class MealAnalysisPipeline(NutritionTrackerDbContext db, IMealVisionAnalysisService vision, IMealImageStorage storage, IFoodMatcher matcher, IFoodNutritionCalculator nutrition) : IMealAnalysisPipeline
{
    public async Task<MealReviewResult> AnalyseAsync(MealAnalysisCommand command, CancellationToken ct)
    {
        var hash = Convert.ToHexString(SHA256.HashData(command.ImageBytes)).ToLowerInvariant();
        var mealId = Guid.NewGuid();
        var storageKey = await storage.SaveAsync(command.ImageBytes, command.MimeType, command.UserId, mealId, ct);
        try
        {
            var previous = await db.Meals.AsNoTracking().AsSplitQuery().Include(x => x.Items).Include(x => x.AnalysisRuns)
                .Where(x => x.UserId == command.UserId && x.Images.Any(i => i.Sha256Hash == hash) && x.Status != MealStatus.Deleted)
                .OrderByDescending(x => x.CreatedAtUtc).FirstOrDefaultAsync(ct);
            if (previous is not null)
            {
                var cloned = CloneAnalysis(previous, command, hash, storageKey, mealId);
                db.Meals.Add(cloned); await db.SaveChangesAsync(ct); return ToReview(cloned);
            }
            var result = await vision.AnalyseAsync(new(command.ImageBytes, command.MimeType, command.FileName, null, null, command.Locale, [], command.CuisineHints, null, null, command.CorrelationId, command.MockScenario, command.ProviderId, command.ModelId), ct);
            var meal = new Meal { Id = mealId, UserId = command.UserId, Name = result.MealName, MealType = Enum.TryParse<MealType>(result.SuggestedMealType.ToString(), out var mealType) ? mealType : MealType.Unknown, ConsumedAtUtc = command.ConsumedAtUtc, Status = result.Status == AnalysisStatus.Rejected || !result.ContainsFood ? MealStatus.Failed : MealStatus.AwaitingReview };
            meal.Images.Add(new MealImage { StorageKey = storageKey, MimeType = command.MimeType, ByteLength = command.ImageBytes.Length, Sha256Hash = hash });
            meal.AnalysisRuns.Add(new AiAnalysisRun { UserId = command.UserId, Provider = result.Provider, Model = result.Model, PromptVersion = result.PromptVersion, SchemaVersion = result.SchemaVersion, InputImageHash = hash, Status = result.Status == AnalysisStatus.Rejected ? AnalysisRunStatus.Rejected : AnalysisRunStatus.Succeeded, ProcessingTimeMs = result.ProcessingDurationMs, ProviderRequestId = result.ProviderRequestId });
            foreach (var item in result.Items) meal.Items.Add(await CreateItem(command.UserId, item, ct)); CalculateTotals(meal); db.Meals.Add(meal); await db.SaveChangesAsync(ct); return ToReview(meal);
        }
        catch { await storage.DeleteAsync(storageKey, CancellationToken.None); throw; }
    }
    private static Meal CloneAnalysis(Meal source, MealAnalysisCommand command, string hash, string storageKey, Guid mealId)
    {
        var run = source.AnalysisRuns.OrderByDescending(x => x.CreatedAtUtc).First();
        var meal = new Meal { Id = mealId, UserId = command.UserId, Name = source.Name, MealType = source.MealType, ConsumedAtUtc = command.ConsumedAtUtc, Status = source.Status == MealStatus.Failed ? MealStatus.Failed : MealStatus.AwaitingReview };
        meal.Images.Add(new MealImage { StorageKey = storageKey, MimeType = command.MimeType, ByteLength = command.ImageBytes.Length, Sha256Hash = hash });
        meal.AnalysisRuns.Add(new AiAnalysisRun { UserId = command.UserId, Provider = run.Provider, Model = run.Model, PromptVersion = run.PromptVersion, SchemaVersion = run.SchemaVersion, InputImageHash = hash, Status = run.Status, ProcessingTimeMs = 0, ProviderRequestId = "reused-identical-image" });
        foreach (var item in source.Items) meal.Items.Add(new MealItem { FoodId = item.FoodId, DetectedName = item.DetectedName, RegionalName = item.RegionalName, CanonicalName = item.CanonicalName, PreparationMethod = item.PreparationMethod, EstimatedQuantity = item.EstimatedQuantity, EstimatedServingUnit = item.EstimatedServingUnit, EstimatedGrams = item.EstimatedGrams, Calories = item.Calories, ProteinGrams = item.ProteinGrams, CarbohydrateGrams = item.CarbohydrateGrams, FatGrams = item.FatGrams, FibreGrams = item.FibreGrams, RecognitionConfidence = item.RecognitionConfidence, PortionConfidence = item.PortionConfidence, NutritionMatchConfidence = item.NutritionMatchConfidence, NutritionMatchState = item.NutritionMatchState, RequiresConfirmation = item.RequiresConfirmation, Warnings = string.Join(" | ", new[] { item.Warnings, "Analysis reused for identical image bytes; review portions before confirming." }.Where(x => !string.IsNullOrWhiteSpace(x))) });
        CalculateTotals(meal); return meal;
    }
    public async Task<MealReviewResult?> GetReviewAsync(string userId, Guid mealId, CancellationToken ct) { var meal = await db.Meals.AsNoTracking().AsSplitQuery().Include(x => x.Items).Include(x => x.AnalysisRuns).Include(x => x.Images).SingleOrDefaultAsync(x => x.Id == mealId && x.UserId == userId && x.Status != MealStatus.Deleted, ct); return meal is null ? null : ToReview(meal); }
    private async Task<MealItem> CreateItem(string userId, MealVisionItem item, CancellationToken ct) { var match = await matcher.MatchAsync(userId, item.DetectedName, item.RegionalName, item.Alternatives.Where(x => x.Confidence >= .60m).Select(x => x.Name).ToList(), ct); ScaledNutritionResult? scaled = null; if (match is not null && item.EstimatedGrams > 0) scaled = nutrition.CalculateForGrams(match.Nutrition, item.EstimatedGrams.Value); var warnings = item.Warnings.ToList(); if (match is null) warnings.Add("Nutrition unavailable: resolve this food before confirmation."); else if (!match.CanonicalName.StartsWith("Cooked white rice", StringComparison.Ordinal)) warnings.Add("Regional dish nutrition is a curated estimate; recipe, oil, sugar, serving size, and vendor preparation can vary."); if (item.EstimatedGrams is null) warnings.Add("Portion weight requires confirmation."); return new MealItem { FoodId = match?.FoodId, DetectedName = item.DetectedName, RegionalName = item.RegionalName, CanonicalName = match?.CanonicalName, PreparationMethod = item.PreparationMethod, EstimatedQuantity = item.EstimatedQuantity, EstimatedServingUnit = item.EstimatedServingUnit.ToString().ToLowerInvariant(), EstimatedGrams = item.EstimatedGrams, Calories = scaled?.Calories, ProteinGrams = scaled?.Protein, CarbohydrateGrams = scaled?.Carbohydrates, FatGrams = scaled?.Fat, FibreGrams = scaled?.Fibre, RecognitionConfidence = item.RecognitionConfidence, PortionConfidence = item.PortionConfidence, NutritionMatchConfidence = match?.Confidence ?? 0, NutritionMatchState = match is null ? NutritionMatchState.Unresolved : match.Confidence >= .99m ? NutritionMatchState.MatchedVerified : NutritionMatchState.MatchedApproximate, RequiresConfirmation = item.RequiresConfirmation || match is null, Warnings = string.Join(" | ", warnings) }; }
    private static void CalculateTotals(Meal meal) { meal.HasIncompleteNutrition = meal.Items.Any(x => x.Calories is null || x.NutritionMatchState == NutritionMatchState.Unresolved); meal.TotalCalories = meal.Items.Sum(x => x.Calories ?? 0); meal.TotalProteinGrams = meal.Items.Sum(x => x.ProteinGrams ?? 0); meal.TotalCarbohydrateGrams = meal.Items.Sum(x => x.CarbohydrateGrams ?? 0); meal.TotalFatGrams = meal.Items.Sum(x => x.FatGrams ?? 0); meal.TotalFibreGrams = meal.Items.Sum(x => x.FibreGrams ?? 0); meal.OverallConfidence = meal.Items.Count == 0 ? 0 : decimal.Round(meal.Items.Average(x => (x.RecognitionConfidence + x.PortionConfidence + x.NutritionMatchConfidence) / 3m), 3); }
    private static MealReviewResult ToReview(Meal meal) { var run = meal.AnalysisRuns.OrderByDescending(x => x.CreatedAtUtc).First(); var items = meal.Items.Select(x => new MealItemReview(x.Id, x.FoodId, x.DetectedName, x.RegionalName, x.CanonicalName, x.PreparationMethod, x.EstimatedQuantity, x.EstimatedServingUnit, x.EstimatedGrams, x.Calories, x.ProteinGrams, x.CarbohydrateGrams, x.FatGrams, x.FibreGrams, x.RecognitionConfidence, x.PortionConfidence, x.NutritionMatchConfidence, x.NutritionMatchState, x.RequiresConfirmation, string.IsNullOrWhiteSpace(x.Warnings) ? [] : x.Warnings.Split(" | "))).ToList(); return new(meal.Id, meal.Name, meal.MealType, meal.ConsumedAtUtc, meal.Status, meal.TotalCalories, meal.TotalProteinGrams, meal.TotalCarbohydrateGrams, meal.TotalFatGrams, meal.TotalFibreGrams, meal.HasIncompleteNutrition, meal.OverallConfidence, items, items.SelectMany(x => x.Warnings).Distinct().ToList(), run.Provider, run.Model, run.PromptVersion, run.SchemaVersion, meal.Images.Count > 0); }
}
