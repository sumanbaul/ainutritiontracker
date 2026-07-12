using System.ComponentModel.DataAnnotations;

namespace NutritionTracker.Infrastructure.Configuration;

public sealed class DatabaseOptions
{
    public const string SectionName = "ConnectionStrings";

    [Required]
    public string DefaultConnection { get; init; } = string.Empty;
}
