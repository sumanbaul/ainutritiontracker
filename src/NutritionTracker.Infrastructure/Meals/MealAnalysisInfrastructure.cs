using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using NutritionTracker.Application.Foods;
using NutritionTracker.Application.Meals;
using NutritionTracker.Application.MealVision;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Domain.Meals;
using NutritionTracker.Infrastructure.Persistence;
namespace NutritionTracker.Infrastructure.Meals;

public sealed class MealAnalysisOptions
{
    public const string SectionName = "MealAnalysis"; public string LocalStorageRoot { get; init; } = "App_Data/meal-images"; public bool RetainImages { get; init; } = true; public int MaximumFileNameLength { get; init; } = 160;
}
public sealed class LocalMealImageStorage(IOptions<MealAnalysisOptions> options) : IMealImageStorage
{
    public async Task<string> SaveAsync(ReadOnlyMemory<byte> image, string mimeType, CancellationToken ct) { var extension = mimeType switch { "image/jpeg" => ".jpg", "image/png" => ".png", "image/webp" => ".webp", _ => throw new MealVisionImageValidationException("Unsupported image type.", 415) }; var root = Root(); Directory.CreateDirectory(root); var key = $"{DateTime.UtcNow:yyyy/MM}/{Guid.NewGuid():N}{extension}"; var path = Resolve(root, key); Directory.CreateDirectory(Path.GetDirectoryName(path)!); await File.WriteAllBytesAsync(path, image.ToArray(), ct); return key; }
    public async Task<byte[]?> ReadAsync(string storageKey, CancellationToken ct) { if (!options.Value.RetainImages) return null; var path = Resolve(Root(), storageKey); return File.Exists(path) ? await File.ReadAllBytesAsync(path, ct) : null; }
    public Task DeleteAsync(string storageKey, CancellationToken ct) { ct.ThrowIfCancellationRequested(); var path = Resolve(Root(), storageKey); if (File.Exists(path)) File.Delete(path); return Task.CompletedTask; }
    private string Root() => Path.GetFullPath(options.Value.LocalStorageRoot).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
    private static string Resolve(string root, string storageKey) { var path = Path.GetFullPath(Path.Combine(root, storageKey.Replace('/', Path.DirectorySeparatorChar))); if (!path.StartsWith(root + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Invalid meal-image storage path."); return path; }
}
public sealed class FoodMatcher(NutritionTrackerDbContext db, IFoodNameNormalizer normalizer) : IFoodMatcher
{
    public async Task<FoodMatchResult?> MatchAsync(string userId, string detectedName, string? regionalName, IReadOnlyList<string>? alternatives, CancellationToken ct)
    {
        var names = new[] { detectedName, regionalName }.Concat(alternatives ?? []).Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => normalizer.Normalize(x!)).Where(x => x.Length > 0).Distinct().ToArray();
        var matches = await db.Foods.AsNoTracking().Where(x => x.IsActive && (!x.IsUserCreated || x.OwnerUserId == userId) && (names.Contains(x.NormalizedName) || x.Aliases.Any(a => names.Contains(a.NormalizedAlias)))).OrderByDescending(x => x.IsVerified).Take(3).ToListAsync(ct);
        if (matches.Count != 1) return null; // Never guess between regional dishes with multiple safe candidates.
        var food = matches[0]; var confidence = names.Contains(food.NormalizedName) ? 1m : .95m;
        return new(food.Id, food.CanonicalName, new(food.CaloriesPer100Grams, food.ProteinGramsPer100Grams, food.CarbohydrateGramsPer100Grams, food.FatGramsPer100Grams, food.FibreGramsPer100Grams, food.SugarGramsPer100Grams, food.SodiumMilligramsPer100Grams), confidence);
    }
}
public sealed class MealAnalysisPipeline(NutritionTrackerDbContext db, IMealVisionAnalysisService vision, IMealImageStorage storage, IFoodMatcher matcher, IFoodNutritionCalculator nutrition) : IMealAnalysisPipeline
{
    public async Task<MealReviewResult> AnalyseAsync(MealAnalysisCommand command, CancellationToken ct)
    {
        var hash = Convert.ToHexString(SHA256.HashData(command.ImageBytes)).ToLowerInvariant();
        var storageKey = await storage.SaveAsync(command.ImageBytes, command.MimeType, ct);
        try
        {
            var previous = await db.Meals.AsNoTracking().AsSplitQuery().Include(x => x.Items).Include(x => x.AnalysisRuns)
                .Where(x => x.UserId == command.UserId && x.Images.Any(i => i.Sha256Hash == hash) && x.Status != MealStatus.Deleted)
                .OrderByDescending(x => x.CreatedAtUtc).FirstOrDefaultAsync(ct);
            if (previous is not null)
            {
                var cloned = CloneAnalysis(previous, command, hash, storageKey);
                db.Meals.Add(cloned); await db.SaveChangesAsync(ct); return ToReview(cloned);
            }
            var result = await vision.AnalyseAsync(new(command.ImageBytes, command.MimeType, command.FileName, null, null, command.Locale, [], command.CuisineHints, null, null, command.CorrelationId, command.MockScenario, command.ProviderId, command.ModelId), ct);
            var meal = new Meal { UserId = command.UserId, Name = result.MealName, MealType = Enum.TryParse<MealType>(result.SuggestedMealType.ToString(), out var mealType) ? mealType : MealType.Unknown, ConsumedAtUtc = command.ConsumedAtUtc, Status = result.Status == AnalysisStatus.Rejected || !result.ContainsFood ? MealStatus.Failed : MealStatus.AwaitingReview };
            meal.Images.Add(new MealImage { StorageKey = storageKey, MimeType = command.MimeType, ByteLength = command.ImageBytes.Length, Sha256Hash = hash });
            meal.AnalysisRuns.Add(new AiAnalysisRun { UserId = command.UserId, Provider = result.Provider, Model = result.Model, PromptVersion = result.PromptVersion, SchemaVersion = result.SchemaVersion, InputImageHash = hash, Status = result.Status == AnalysisStatus.Rejected ? AnalysisRunStatus.Rejected : AnalysisRunStatus.Succeeded, ProcessingTimeMs = result.ProcessingDurationMs, ProviderRequestId = result.ProviderRequestId });
            foreach (var item in result.Items) meal.Items.Add(await CreateItem(command.UserId, item, ct)); CalculateTotals(meal); db.Meals.Add(meal); await db.SaveChangesAsync(ct); return ToReview(meal);
        }
        catch { await storage.DeleteAsync(storageKey, CancellationToken.None); throw; }
    }
    private static Meal CloneAnalysis(Meal source, MealAnalysisCommand command, string hash, string storageKey)
    {
        var run = source.AnalysisRuns.OrderByDescending(x => x.CreatedAtUtc).First();
        var meal = new Meal { UserId = command.UserId, Name = source.Name, MealType = source.MealType, ConsumedAtUtc = command.ConsumedAtUtc, Status = source.Status == MealStatus.Failed ? MealStatus.Failed : MealStatus.AwaitingReview };
        meal.Images.Add(new MealImage { StorageKey = storageKey, MimeType = command.MimeType, ByteLength = command.ImageBytes.Length, Sha256Hash = hash });
        meal.AnalysisRuns.Add(new AiAnalysisRun { UserId = command.UserId, Provider = run.Provider, Model = run.Model, PromptVersion = run.PromptVersion, SchemaVersion = run.SchemaVersion, InputImageHash = hash, Status = run.Status, ProcessingTimeMs = 0, ProviderRequestId = "reused-identical-image" });
        foreach (var item in source.Items) meal.Items.Add(new MealItem { FoodId = item.FoodId, DetectedName = item.DetectedName, RegionalName = item.RegionalName, CanonicalName = item.CanonicalName, PreparationMethod = item.PreparationMethod, EstimatedQuantity = item.EstimatedQuantity, EstimatedServingUnit = item.EstimatedServingUnit, EstimatedGrams = item.EstimatedGrams, Calories = item.Calories, ProteinGrams = item.ProteinGrams, CarbohydrateGrams = item.CarbohydrateGrams, FatGrams = item.FatGrams, FibreGrams = item.FibreGrams, RecognitionConfidence = item.RecognitionConfidence, PortionConfidence = item.PortionConfidence, NutritionMatchConfidence = item.NutritionMatchConfidence, RequiresConfirmation = item.RequiresConfirmation, Warnings = string.Join(" | ", new[] { item.Warnings, "Analysis reused for identical image bytes; review portions before confirming." }.Where(x => !string.IsNullOrWhiteSpace(x))) });
        CalculateTotals(meal); return meal;
    }
    public async Task<MealReviewResult?> GetReviewAsync(string userId, Guid mealId, CancellationToken ct) { var meal = await db.Meals.AsNoTracking().AsSplitQuery().Include(x => x.Items).Include(x => x.AnalysisRuns).Include(x => x.Images).SingleOrDefaultAsync(x => x.Id == mealId && x.UserId == userId && x.Status != MealStatus.Deleted, ct); return meal is null ? null : ToReview(meal); }
    private async Task<MealItem> CreateItem(string userId, MealVisionItem item, CancellationToken ct) { var match = await matcher.MatchAsync(userId, item.DetectedName, item.RegionalName, item.Alternatives.Where(x => x.Confidence >= .60m).Select(x => x.Name).ToList(), ct); ScaledNutritionResult? scaled = null; if (match is not null && item.EstimatedGrams > 0) scaled = nutrition.CalculateForGrams(match.Nutrition, item.EstimatedGrams.Value); var warnings = item.Warnings.ToList(); if (match is null) warnings.Add("No matching food database record was found."); else if (!match.CanonicalName.StartsWith("Cooked white rice", StringComparison.Ordinal)) warnings.Add("Regional dish nutrition is a curated estimate; recipe, oil, sugar, serving size, and vendor preparation can vary."); if (item.EstimatedGrams is null) warnings.Add("Portion weight requires confirmation."); return new MealItem { FoodId = match?.FoodId, DetectedName = item.DetectedName, RegionalName = item.RegionalName, CanonicalName = match?.CanonicalName, PreparationMethod = item.PreparationMethod, EstimatedQuantity = item.EstimatedQuantity, EstimatedServingUnit = item.EstimatedServingUnit.ToString().ToLowerInvariant(), EstimatedGrams = item.EstimatedGrams, Calories = scaled?.Calories ?? 0, ProteinGrams = scaled?.Protein ?? 0, CarbohydrateGrams = scaled?.Carbohydrates ?? 0, FatGrams = scaled?.Fat ?? 0, FibreGrams = scaled?.Fibre ?? 0, RecognitionConfidence = item.RecognitionConfidence, PortionConfidence = item.PortionConfidence, NutritionMatchConfidence = match?.Confidence ?? 0, RequiresConfirmation = item.RequiresConfirmation || match is null, Warnings = string.Join(" | ", warnings) }; }
    private static void CalculateTotals(Meal meal) { meal.TotalCalories = meal.Items.Sum(x => x.Calories); meal.TotalProteinGrams = meal.Items.Sum(x => x.ProteinGrams); meal.TotalCarbohydrateGrams = meal.Items.Sum(x => x.CarbohydrateGrams); meal.TotalFatGrams = meal.Items.Sum(x => x.FatGrams); meal.TotalFibreGrams = meal.Items.Sum(x => x.FibreGrams); meal.OverallConfidence = meal.Items.Count == 0 ? 0 : decimal.Round(meal.Items.Average(x => (x.RecognitionConfidence + x.PortionConfidence + x.NutritionMatchConfidence) / 3m), 3); }
    private static MealReviewResult ToReview(Meal meal) { var run = meal.AnalysisRuns.OrderByDescending(x => x.CreatedAtUtc).First(); var items = meal.Items.Select(x => new MealItemReview(x.Id, x.FoodId, x.DetectedName, x.RegionalName, x.CanonicalName, x.PreparationMethod, x.EstimatedQuantity, x.EstimatedServingUnit, x.EstimatedGrams, x.Calories, x.ProteinGrams, x.CarbohydrateGrams, x.FatGrams, x.FibreGrams, x.RecognitionConfidence, x.PortionConfidence, x.NutritionMatchConfidence, x.RequiresConfirmation, string.IsNullOrWhiteSpace(x.Warnings) ? [] : x.Warnings.Split(" | "))).ToList(); return new(meal.Id, meal.Name, meal.MealType, meal.ConsumedAtUtc, meal.Status, meal.TotalCalories, meal.TotalProteinGrams, meal.TotalCarbohydrateGrams, meal.TotalFatGrams, meal.TotalFibreGrams, meal.OverallConfidence, items, items.SelectMany(x => x.Warnings).Distinct().ToList(), run.Provider, run.Model, run.PromptVersion, run.SchemaVersion, meal.Images.Count > 0); }
}
