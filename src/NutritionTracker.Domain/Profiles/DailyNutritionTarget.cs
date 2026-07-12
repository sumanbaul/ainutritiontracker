using NutritionTracker.Domain.Common;

namespace NutritionTracker.Domain.Profiles;

public sealed class DailyNutritionTarget : AuditableEntity
{
    public Guid UserProfileId { get; set; }
    public DateOnly EffectiveDate { get; set; }
    public decimal BasalMetabolicRate { get; set; }
    public decimal TotalDailyEnergyExpenditure { get; set; }
    public decimal TargetCalories { get; set; }
    public decimal ProteinGrams { get; set; }
    public decimal CarbohydrateGrams { get; set; }
    public decimal FatGrams { get; set; }
    public decimal FibreGrams { get; set; }
    public string CalculationMethod { get; set; } = string.Empty;
    public string? CalculationWarnings { get; set; }
    public GoalType GoalType { get; set; }
    public UserProfile UserProfile { get; set; } = null!;
}
