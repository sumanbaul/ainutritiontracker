using NutritionTracker.Domain.Common;

namespace NutritionTracker.Domain.Profiles;

public sealed class UserProfile : AuditableEntity
{
    public string UserId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public DateOnly DateOfBirth { get; set; }
    public BiologicalSex BiologicalSex { get; set; }
    public decimal HeightCm { get; set; }
    public decimal CurrentWeightKg { get; set; }
    public decimal TargetWeightKg { get; set; }
    public ActivityLevel ActivityLevel { get; set; }
    public GoalType GoalType { get; set; }
    public DietPreference DietPreference { get; set; }
    public PreferredMeasurementSystem PreferredMeasurementSystem { get; set; }
    public string Timezone { get; set; } = string.Empty;
    public bool IsOnboardingComplete { get; set; }
    public ICollection<WeightEntry> WeightEntries { get; } = new List<WeightEntry>();
    public ICollection<DailyNutritionTarget> NutritionTargets { get; } = new List<DailyNutritionTarget>();
}
