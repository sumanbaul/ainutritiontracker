using Microsoft.EntityFrameworkCore;
using NutritionTracker.Domain.Common;
using NutritionTracker.Domain.Profiles;
using NutritionTracker.Domain.Foods;
using NutritionTracker.Domain.Meals;
using NutritionTracker.Domain.Authentication;

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
    public DbSet<NutrientDefinition> NutrientDefinitions => Set<NutrientDefinition>();
    public DbSet<FoodNutrient> FoodNutrients => Set<FoodNutrient>();
    public DbSet<FoodTag> FoodTags => Set<FoodTag>();
    public DbSet<FoodTagAssignment> FoodTagAssignments => Set<FoodTagAssignment>();
    public DbSet<Recipe> Recipes => Set<Recipe>();
    public DbSet<RecipeIngredient> RecipeIngredients => Set<RecipeIngredient>();
    public DbSet<Meal> Meals => Set<Meal>();
    public DbSet<MealImage> MealImages => Set<MealImage>();
    public DbSet<MealItem> MealItems => Set<MealItem>();
    public DbSet<AiAnalysisRun> AiAnalysisRuns => Set<AiAnalysisRun>();
    public DbSet<UserFoodCorrection> UserFoodCorrections => Set<UserFoodCorrection>();
    public DbSet<DailyNutritionSummary> DailyNutritionSummaries => Set<DailyNutritionSummary>();
    public DbSet<UserDietaryPreference> UserDietaryPreferences => Set<UserDietaryPreference>();
    public DbSet<HydrationEntry> HydrationEntries => Set<HydrationEntry>();
    public DbSet<FastingWindow> FastingWindows => Set<FastingWindow>();
    public DbSet<ReminderPreference> ReminderPreferences => Set<ReminderPreference>();
    public DbSet<ApplicationUser> ApplicationUsers => Set<ApplicationUser>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<IdempotencyRecord> IdempotencyRecords => Set<IdempotencyRecord>();
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
        foreach (var entityType in modelBuilder.Model.GetEntityTypes().Where(x => typeof(AuditableEntity).IsAssignableFrom(x.ClrType)))
            modelBuilder.Entity(entityType.ClrType).Property<long>(nameof(AuditableEntity.Version)).IsConcurrencyToken();
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
                entry.Entity.Version = 1;
            }
            else if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAtUtc = utcNow;
                entry.Entity.Version++;
            }
        }
    }
}
