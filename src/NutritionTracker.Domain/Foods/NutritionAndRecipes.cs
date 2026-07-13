using NutritionTracker.Domain.Common;

namespace NutritionTracker.Domain.Foods;

public enum NutrientUnit { Gram, Milligram, Microgram, Kilocalorie, InternationalUnit }
public sealed class NutrientDefinition : AuditableEntity { public string Code { get; set; } = string.Empty; public string DisplayName { get; set; } = string.Empty; public NutrientUnit Unit { get; set; } public int DisplayOrder { get; set; } public bool IsCore { get; set; } public bool IsActive { get; set; } = true; }
public sealed class FoodNutrient : AuditableEntity { public Guid FoodId { get; set; } public Guid NutrientDefinitionId { get; set; } public decimal ValuePer100Grams { get; set; } public string Source { get; set; } = string.Empty; public string? SourceReference { get; set; } public DataConfidence Confidence { get; set; } public Food Food { get; set; } = null!; public NutrientDefinition NutrientDefinition { get; set; } = null!; }
public sealed class FoodTag : AuditableEntity { public string Code { get; set; } = string.Empty; public string DisplayName { get; set; } = string.Empty; public string Category { get; set; } = string.Empty; }
public sealed class FoodTagAssignment : AuditableEntity { public Guid FoodId { get; set; } public Guid FoodTagId { get; set; } public Food Food { get; set; } = null!; public FoodTag FoodTag { get; set; } = null!; }
public sealed class Recipe : AuditableEntity { public string UserId { get; set; } = string.Empty; public string Name { get; set; } = string.Empty; public string? Description { get; set; } public string? PreparationNotes { get; set; } public decimal YieldGrams { get; set; } public decimal ServingCount { get; set; } public bool IsSavedTemplate { get; set; } public bool IsActive { get; set; } = true; public ICollection<RecipeIngredient> Ingredients { get; } = new List<RecipeIngredient>(); }
public sealed class RecipeIngredient : AuditableEntity { public Guid RecipeId { get; set; } public Guid FoodId { get; set; } public decimal Grams { get; set; } public string? Notes { get; set; } public Recipe Recipe { get; set; } = null!; public Food Food { get; set; } = null!; }
