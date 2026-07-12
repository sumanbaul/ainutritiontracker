using System.Text;
using System.Text.RegularExpressions;
using NutritionTracker.Domain.Foods;

namespace NutritionTracker.Application.Foods;

public sealed record FoodNutritionValues(decimal Calories, decimal Protein, decimal Carbohydrates, decimal Fat, decimal Fibre, decimal? Sugar = null, decimal? SodiumMilligrams = null);
public sealed record FoodServingConversionValue(decimal Quantity, decimal EquivalentGrams, string Source, DataConfidence Confidence);
public sealed record ScaledNutritionResult(decimal Grams, decimal Calories, decimal Protein, decimal Carbohydrates, decimal Fat, decimal Fibre, decimal? Sugar, decimal? SodiumMilligrams);
public interface IFoodNameNormalizer { string Normalize(string value); }
public interface IFoodNutritionCalculator { ScaledNutritionResult CalculateForGrams(FoodNutritionValues nutrition, decimal grams); ScaledNutritionResult CalculateForServing(FoodNutritionValues nutrition, FoodServingConversionValue conversion, decimal servingQuantity); }
public sealed partial class FoodNameNormalizer : IFoodNameNormalizer
{
    [GeneratedRegex(@"[\p{P}\p{S}&&[^\p{Sc}]]+", RegexOptions.CultureInvariant)] private static partial Regex PunctuationRegex();
    [GeneratedRegex(@"\s+", RegexOptions.CultureInvariant)] private static partial Regex WhitespaceRegex();
    public string Normalize(string value) { ArgumentException.ThrowIfNullOrWhiteSpace(value); var normalized = value.Normalize(NormalizationForm.FormC).ToLowerInvariant().Replace('’', '\'').Replace('–', '-').Replace('—', '-').Replace('-', ' '); normalized = PunctuationRegex().Replace(normalized, " "); return WhitespaceRegex().Replace(normalized, " ").Trim(); }
}
public sealed class FoodNutritionCalculator : IFoodNutritionCalculator
{
    public ScaledNutritionResult CalculateForGrams(FoodNutritionValues nutrition, decimal grams) { ArgumentOutOfRangeException.ThrowIfNegativeOrZero(grams); Validate(nutrition); var f = grams / 100m; return new(R(grams), R(nutrition.Calories * f), R(nutrition.Protein * f), R(nutrition.Carbohydrates * f), R(nutrition.Fat * f), R(nutrition.Fibre * f), nutrition.Sugar is null ? null : R(nutrition.Sugar.Value * f), nutrition.SodiumMilligrams is null ? null : R(nutrition.SodiumMilligrams.Value * f)); }
    public ScaledNutritionResult CalculateForServing(FoodNutritionValues nutrition, FoodServingConversionValue conversion, decimal servingQuantity) { ArgumentOutOfRangeException.ThrowIfNegativeOrZero(servingQuantity); ArgumentOutOfRangeException.ThrowIfNegativeOrZero(conversion.Quantity); ArgumentOutOfRangeException.ThrowIfNegativeOrZero(conversion.EquivalentGrams); return CalculateForGrams(nutrition, servingQuantity * conversion.EquivalentGrams / conversion.Quantity); }
    private static void Validate(FoodNutritionValues n) { if (n.Calories < 0 || n.Protein is < 0 or > 100 || n.Carbohydrates is < 0 or > 100 || n.Fat is < 0 or > 100 || n.Fibre is < 0 or > 100 || n.Sugar < 0 || n.SodiumMilligrams < 0) throw new ArgumentOutOfRangeException(nameof(n)); }
    private static decimal R(decimal v) => decimal.Round(v, 3, MidpointRounding.AwayFromZero);
}
public enum FoodMatchType { ExactCanonical, ExactAlias, CanonicalPrefix, AliasPrefix, CanonicalContains, AliasContains, UserCustom }
public sealed record FoodSummary(Guid Id, string DisplayName, string CanonicalName, string? RegionalName, FoodCategory Category, Cuisine Cuisine, PreparationMethod PreparationMethod, FoodState FoodState, FoodNutritionValues NutritionPer100Grams, bool IsVerified, bool IsUserCreated, FoodMatchType MatchType, IReadOnlyList<string> ServingUnits);
public sealed record FoodDetails(Guid Id, string CanonicalName, string DisplayName, string? Description, FoodCategory Category, Cuisine Cuisine, PreparationMethod PreparationMethod, FoodState FoodState, FoodNutritionValues NutritionPer100Grams, IReadOnlyList<string> Aliases, IReadOnlyList<ServingConversionResult> ServingConversions, string DataSource, string? SourceReference, string? SourceVersion, bool IsVerified, bool IsUserCreated);
public sealed record ServingConversionResult(string Code, decimal Quantity, decimal EquivalentGrams, string Source, DataConfidence Confidence);
public sealed record CustomFoodCommand(string DisplayName, string? CanonicalName, string? Description, FoodCategory Category, Cuisine Cuisine, PreparationMethod PreparationMethod, FoodState FoodState, FoodNutritionValues NutritionPer100Grams, IReadOnlyList<string> Aliases);
public interface IFoodService { Task<IReadOnlyList<FoodSummary>> SearchAsync(string userId, string query, FoodCategory? category, Cuisine? cuisine, PreparationMethod? preparation, bool verifiedOnly, bool includeUserFoods, int limit, CancellationToken ct); Task<FoodDetails?> GetAsync(string userId, Guid id, CancellationToken ct); Task<ScaledNutritionResult?> CalculateGramsAsync(string userId, Guid id, decimal grams, CancellationToken ct); Task<ScaledNutritionResult?> CalculateServingAsync(string userId, Guid id, string code, decimal quantity, CancellationToken ct); Task<FoodDetails> CreateCustomAsync(string userId, CustomFoodCommand command, CancellationToken ct); Task<FoodDetails?> UpdateCustomAsync(string userId, Guid id, CustomFoodCommand command, CancellationToken ct); Task<bool> DeactivateCustomAsync(string userId, Guid id, CancellationToken ct); }
