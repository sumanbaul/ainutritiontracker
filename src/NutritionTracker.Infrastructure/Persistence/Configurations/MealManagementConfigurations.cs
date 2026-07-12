using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NutritionTracker.Domain.Meals;
namespace NutritionTracker.Infrastructure.Persistence.Configurations;

public sealed class UserFoodCorrectionConfiguration : IEntityTypeConfiguration<UserFoodCorrection>
{ public void Configure(EntityTypeBuilder<UserFoodCorrection> builder) { builder.ToTable("user_food_corrections"); builder.HasKey(x => x.Id); builder.Property(x => x.UserId).HasMaxLength(128).IsRequired(); builder.Property(x => x.PredictedServingUnit).HasMaxLength(32); builder.Property(x => x.CorrectedServingUnit).HasMaxLength(32); builder.Property(x => x.CorrectionType).HasMaxLength(32).IsRequired(); builder.Property(x => x.PredictedGrams).HasPrecision(9, 3); builder.Property(x => x.CorrectedGrams).HasPrecision(9, 3); builder.HasIndex(x => new { x.UserId, x.CreatedAtUtc }); builder.HasIndex(x => x.MealId); builder.HasOne(x => x.Meal).WithMany().HasForeignKey(x => x.MealId).OnDelete(DeleteBehavior.Cascade); } }
public sealed class DailyNutritionSummaryConfiguration : IEntityTypeConfiguration<DailyNutritionSummary>
{ public void Configure(EntityTypeBuilder<DailyNutritionSummary> builder) { builder.ToTable("daily_nutrition_summaries"); builder.HasKey(x => x.Id); builder.Property(x => x.UserId).HasMaxLength(128).IsRequired(); builder.Property(x => x.TotalCalories).HasPrecision(9, 3); builder.Property(x => x.TotalProteinGrams).HasPrecision(9, 3); builder.Property(x => x.TotalCarbohydrateGrams).HasPrecision(9, 3); builder.Property(x => x.TotalFatGrams).HasPrecision(9, 3); builder.Property(x => x.TotalFibreGrams).HasPrecision(9, 3); builder.HasIndex(x => new { x.UserId, x.SummaryDate }).IsUnique(); } }
