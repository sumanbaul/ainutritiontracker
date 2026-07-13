using NutritionTracker.Domain.Common;

namespace NutritionTracker.Domain.Authentication;

public sealed class ApplicationUser : AuditableEntity
{
    public string Email { get; set; } = string.Empty;
    public string NormalizedEmail { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
}

public sealed class RefreshToken : AuditableEntity
{
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiresAtUtc { get; set; }
    public DateTime? RevokedAtUtc { get; set; }
    public string? ReplacedByHash { get; set; }
    public ApplicationUser User { get; set; } = null!;
}

public sealed class IdempotencyRecord : AuditableEntity
{
    public string UserId { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;
    public string Operation { get; set; } = string.Empty;
    public int StatusCode { get; set; }
    public string? ResponseJson { get; set; }
    public DateTime ExpiresAtUtc { get; set; }
}
