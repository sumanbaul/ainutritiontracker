using NutritionTracker.Domain.Common;
namespace NutritionTracker.Domain.Foods;

public sealed class ServingUnit : AuditableEntity { public string Code { get; set; } = string.Empty; public string DisplayName { get; set; } = string.Empty; public string? Symbol { get; set; } public ServingUnitType UnitType { get; set; } public bool IsMetric { get; set; } public bool IsCountBased { get; set; } public bool IsActive { get; set; } = true; public ICollection<FoodServingConversion> FoodServingConversions { get; } = new List<FoodServingConversion>(); }
