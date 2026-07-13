using NutritionTracker.Domain.Common;
namespace NutritionTracker.Domain.Profiles;

public sealed class UserDietaryPreference : AuditableEntity { public string UserId { get; set; } = string.Empty; public string Code { get; set; } = string.Empty; public string? Notes { get; set; } }
public sealed class HydrationEntry : AuditableEntity { public string UserId { get; set; } = string.Empty; public decimal Millilitres { get; set; } public DateTime RecordedAtUtc { get; set; } public string? ClientOperationId { get; set; } }
public sealed class FastingWindow : AuditableEntity { public string UserId { get; set; } = string.Empty; public DateTime StartedAtUtc { get; set; } public DateTime? EndedAtUtc { get; set; } public string? ClientOperationId { get; set; } }
public sealed class ReminderPreference : AuditableEntity { public string UserId { get; set; } = string.Empty; public string Type { get; set; } = string.Empty; public TimeOnly LocalTime { get; set; } public string Timezone { get; set; } = string.Empty; public bool IsEnabled { get; set; } public string? ClientOperationId { get; set; } }
