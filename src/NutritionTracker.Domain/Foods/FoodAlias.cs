using NutritionTracker.Domain.Common;
namespace NutritionTracker.Domain.Foods;

public sealed class FoodAlias : AuditableEntity { public Guid FoodId { get; set; } public string Alias { get; set; } = string.Empty; public string NormalizedAlias { get; set; } = string.Empty; public string? LanguageCode { get; set; } public string? Region { get; set; } public string? Transliteration { get; set; } public AliasType AliasType { get; set; } public int Priority { get; set; } public bool IsPrimary { get; set; } public Food Food { get; set; } = null!; }
