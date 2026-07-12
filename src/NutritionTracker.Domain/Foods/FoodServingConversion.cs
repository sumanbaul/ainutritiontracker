using NutritionTracker.Domain.Common;
namespace NutritionTracker.Domain.Foods;

public sealed class FoodServingConversion : AuditableEntity { public Guid FoodId { get; set; } public Guid ServingUnitId { get; set; } public decimal Quantity { get; set; } public decimal EquivalentGrams { get; set; } public string Source { get; set; } = string.Empty; public string? SourceReference { get; set; } public DataConfidence Confidence { get; set; } public bool IsDefault { get; set; } public Food Food { get; set; } = null!; public ServingUnit ServingUnit { get; set; } = null!; }
