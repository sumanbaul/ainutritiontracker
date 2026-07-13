using NutritionTracker.Domain.Common;
using NutritionTracker.Domain.Foods;
namespace NutritionTracker.Domain.Meals;

public enum MealType { Breakfast, Lunch, Dinner, Snack, Beverage, Unknown }
public enum MealStatus { PendingAnalysis, AwaitingReview, Confirmed, Failed, Deleted }
public enum AnalysisRunStatus { Processing, Succeeded, Rejected, Failed }
/// <summary>Describes whether an item has a safe nutrition-record basis. Zero never means unknown.</summary>
public enum NutritionMatchState { MatchedVerified, MatchedApproximate, UserSelected, UserDefined, Unresolved, NotApplicable }

public sealed class Meal : AuditableEntity
{
    public string UserId { get; set; } = string.Empty; public MealType MealType { get; set; }
    public DateTime ConsumedAtUtc { get; set; }
    public string? Name { get; set; }
    public decimal TotalCalories { get; set; }
    public decimal TotalProteinGrams { get; set; }
    public decimal TotalCarbohydrateGrams { get; set; }
    public decimal TotalFatGrams { get; set; }
    public decimal TotalFibreGrams { get; set; }
    public decimal OverallConfidence { get; set; }
    public bool HasIncompleteNutrition { get; set; }
    public MealStatus Status { get; set; }
    public ICollection<MealImage> Images { get; } = new List<MealImage>(); public ICollection<MealItem> Items { get; } = new List<MealItem>(); public ICollection<AiAnalysisRun> AnalysisRuns { get; } = new List<AiAnalysisRun>();
}
public sealed class MealImage : AuditableEntity
{
    public Guid MealId { get; set; }
    public string StorageKey { get; set; } = string.Empty; public string MimeType { get; set; } = string.Empty; public long ByteLength { get; set; }
    public string Sha256Hash { get; set; } = string.Empty; public int? Width { get; set; }
    public int? Height { get; set; }
    public Meal Meal { get; set; } = null!;
}
public sealed class MealItem : AuditableEntity
{
    public Guid MealId { get; set; }
    public Guid? FoodId { get; set; }
    public string DetectedName { get; set; } = string.Empty; public string? RegionalName { get; set; }
    public string? CanonicalName { get; set; }
    public PreparationMethod PreparationMethod { get; set; }
    public decimal? EstimatedQuantity { get; set; }
    public string EstimatedServingUnit { get; set; } = "unknown"; public decimal? EstimatedGrams { get; set; }
    public decimal? Calories { get; set; }
    public decimal? ProteinGrams { get; set; }
    public decimal? CarbohydrateGrams { get; set; }
    public decimal? FatGrams { get; set; }
    public decimal? FibreGrams { get; set; }
    public decimal RecognitionConfidence { get; set; }
    public decimal PortionConfidence { get; set; }
    public decimal NutritionMatchConfidence { get; set; }
    public NutritionMatchState NutritionMatchState { get; set; } = NutritionMatchState.Unresolved;
    public bool RequiresConfirmation { get; set; }
    public bool UserConfirmed { get; set; }
    public string? Warnings { get; set; }
    public Meal Meal { get; set; } = null!; public Food? Food { get; set; }
}
public sealed class AiAnalysisRun : AuditableEntity
{
    public Guid MealId { get; set; }
    public string UserId { get; set; } = string.Empty; public string Provider { get; set; } = string.Empty; public string? Model { get; set; }
    public string PromptVersion { get; set; } = string.Empty; public string SchemaVersion { get; set; } = string.Empty; public string InputImageHash { get; set; } = string.Empty; public AnalysisRunStatus Status { get; set; }
    public long ProcessingTimeMs { get; set; }
    public string? ProviderRequestId { get; set; }
    public string? FailureType { get; set; }
    public string? ErrorCode { get; set; }
    public Meal Meal { get; set; } = null!;
}
public sealed class UserFoodCorrection : AuditableEntity
{
    public string UserId { get; set; } = string.Empty; public Guid MealId { get; set; }
    public Guid? MealItemId { get; set; }
    public Guid? PredictedFoodId { get; set; }
    public Guid? CorrectedFoodId { get; set; }
    public decimal? PredictedGrams { get; set; }
    public decimal? CorrectedGrams { get; set; }
    public string? PredictedServingUnit { get; set; }
    public string? CorrectedServingUnit { get; set; }
    public string CorrectionType { get; set; } = string.Empty; public Meal Meal { get; set; } = null!;
}
public sealed class DailyNutritionSummary : AuditableEntity
{
    public string UserId { get; set; } = string.Empty; public DateOnly SummaryDate { get; set; }
    public decimal TotalCalories { get; set; }
    public decimal TotalProteinGrams { get; set; }
    public decimal TotalCarbohydrateGrams { get; set; }
    public decimal TotalFatGrams { get; set; }
    public decimal TotalFibreGrams { get; set; }
    public int MealCount { get; set; }
}
