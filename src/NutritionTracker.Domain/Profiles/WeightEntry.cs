using NutritionTracker.Domain.Common;

namespace NutritionTracker.Domain.Profiles;

public sealed class WeightEntry : AuditableEntity
{
    public Guid UserProfileId { get; set; }
    public decimal WeightKg { get; set; }
    public DateTime RecordedAtUtc { get; set; }
    public string? Notes { get; set; }
    public UserProfile UserProfile { get; set; } = null!;
}
