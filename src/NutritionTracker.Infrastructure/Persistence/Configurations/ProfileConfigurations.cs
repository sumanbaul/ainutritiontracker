using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NutritionTracker.Domain.Profiles;

namespace NutritionTracker.Infrastructure.Persistence.Configurations;

public sealed class UserProfileConfiguration : IEntityTypeConfiguration<UserProfile>
{
    public void Configure(EntityTypeBuilder<UserProfile> builder)
    {
        builder.ToTable("user_profiles"); builder.HasKey(x => x.Id); builder.HasIndex(x => x.UserId).IsUnique();
        builder.Property(x => x.UserId).HasMaxLength(128).IsRequired(); builder.Property(x => x.Name).HasMaxLength(120).IsRequired();
        builder.Property(x => x.HeightCm).HasPrecision(6, 2); builder.Property(x => x.CurrentWeightKg).HasPrecision(6, 2); builder.Property(x => x.TargetWeightKg).HasPrecision(6, 2);
        builder.Property(x => x.Timezone).HasMaxLength(64).IsRequired(); builder.Property(x => x.BiologicalSex).HasConversion<string>().HasMaxLength(24); builder.Property(x => x.ActivityLevel).HasConversion<string>().HasMaxLength(32); builder.Property(x => x.GoalType).HasConversion<string>().HasMaxLength(32); builder.Property(x => x.DietPreference).HasConversion<string>().HasMaxLength(32); builder.Property(x => x.PreferredMeasurementSystem).HasConversion<string>().HasMaxLength(16);
        builder.HasMany(x => x.WeightEntries).WithOne(x => x.UserProfile).HasForeignKey(x => x.UserProfileId).OnDelete(DeleteBehavior.Cascade);
        builder.HasMany(x => x.NutritionTargets).WithOne(x => x.UserProfile).HasForeignKey(x => x.UserProfileId).OnDelete(DeleteBehavior.Cascade);
    }
}

public sealed class WeightEntryConfiguration : IEntityTypeConfiguration<WeightEntry>
{
    public void Configure(EntityTypeBuilder<WeightEntry> builder)
    { builder.ToTable("weight_entries"); builder.HasKey(x => x.Id); builder.HasIndex(x => new { x.UserProfileId, x.RecordedAtUtc }); builder.Property(x => x.WeightKg).HasPrecision(6, 2); builder.Property(x => x.Notes).HasMaxLength(500); }
}

public sealed class DailyNutritionTargetConfiguration : IEntityTypeConfiguration<DailyNutritionTarget>
{
    public void Configure(EntityTypeBuilder<DailyNutritionTarget> builder)
    { builder.ToTable("daily_nutrition_targets"); builder.HasKey(x => x.Id); builder.HasIndex(x => new { x.UserProfileId, x.EffectiveDate }); builder.Property(x => x.BasalMetabolicRate).HasPrecision(8, 2); builder.Property(x => x.TotalDailyEnergyExpenditure).HasPrecision(8, 2); builder.Property(x => x.TargetCalories).HasPrecision(8, 2); builder.Property(x => x.ProteinGrams).HasPrecision(8, 2); builder.Property(x => x.CarbohydrateGrams).HasPrecision(8, 2); builder.Property(x => x.FatGrams).HasPrecision(8, 2); builder.Property(x => x.FibreGrams).HasPrecision(8, 2); builder.Property(x => x.CalculationMethod).HasMaxLength(64).IsRequired(); builder.Property(x => x.CalculationWarnings).HasMaxLength(1000); builder.Property(x => x.GoalType).HasConversion<string>().HasMaxLength(32); }
}
