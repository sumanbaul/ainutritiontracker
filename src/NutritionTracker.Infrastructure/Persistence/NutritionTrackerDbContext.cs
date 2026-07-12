using Microsoft.EntityFrameworkCore;
using NutritionTracker.Domain.Common;
using NutritionTracker.Domain.Profiles;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Domain.Meals;

namespace NutritionTracker.Infrastructure.Persistence;

public sealed class NutritionTrackerDbContext(DbContextOptions<NutritionTrackerDbContext> options) : DbContext(options)
{
    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<WeightEntry> WeightEntries => Set<WeightEntry>();
    public DbSet<DailyNutritionTarget> DailyNutritionTargets => Set<DailyNutritionTarget>();
    public DbSet<Food> Foods => Set<Food>();
    public DbSet<FoodAlias> FoodAliases => Set<FoodAlias>();
    public DbSet<ServingUnit> ServingUnits => Set<ServingUnit>();
    public DbSet<FoodServingConversion> FoodServingConversions => Set<FoodServingConversion>();
    public DbSet<Meal> Meals => Set<Meal>();
    public DbSet<MealImage> MealImages => Set<MealImage>();
    public DbSet<MealItem> MealItems => Set<MealItem>();
    public DbSet<AiAnalysisRun> AiAnalysisRuns => Set<AiAnalysisRun>();
    public DbSet<UserFoodCorrection> UserFoodCorrections => Set<UserFoodCorrection>();
    public DbSet<DailyNutritionSummary> DailyNutritionSummaries => Set<DailyNutritionSummary>();
    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        ApplyAuditTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        ApplyAuditTimestamps();
        return base.SaveChanges();
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(NutritionTrackerDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }

    private void ApplyAuditTimestamps()
    {
        var utcNow = DateTime.UtcNow;

        foreach (var entry in ChangeTracker.Entries<AuditableEntity>())
        {
            if (entry.State == EntityState.Added)
            {
                entry.Entity.CreatedAtUtc = utcNow;
                entry.Entity.UpdatedAtUtc = utcNow;
            }
            else if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAtUtc = utcNow;
            }
        }
    }
}
