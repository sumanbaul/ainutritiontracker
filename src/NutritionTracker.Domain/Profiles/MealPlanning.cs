using NutritionTracker.Domain.Common;

namespace NutritionTracker.Domain.Profiles;

public enum PlannedMealSlot { Breakfast, Lunch, Dinner }

public sealed class MealPlan : AuditableEntity
{
    public string UserId { get; set; } = string.Empty;
    public DateOnly StartDate { get; set; }
    public ICollection<MealPlanEntry> Entries { get; } = new List<MealPlanEntry>();
}

public sealed class MealPlanEntry : AuditableEntity
{
    public Guid MealPlanId { get; set; }
    public DateOnly PlannedDate { get; set; }
    public PlannedMealSlot Slot { get; set; }
    public string CatalogRecipeId { get; set; } = string.Empty;
    public MealPlan MealPlan { get; set; } = null!;
}

public sealed class SavedCatalogRecipe : AuditableEntity
{
    public string UserId { get; set; } = string.Empty;
    public string CatalogRecipeId { get; set; } = string.Empty;
}

public sealed class ShoppingListItem : AuditableEntity
{
    public string UserId { get; set; } = string.Empty;
    public string Ingredient { get; set; } = string.Empty;
    public string NormalizedIngredient { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string Unit { get; set; } = string.Empty;
    public bool IsChecked { get; set; }
}
