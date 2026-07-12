using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutritionTracker.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUserProfilesAndNutritionTargets : Migration
    {
        private static readonly string[] DailyNutritionTargetIndexColumns = ["UserProfileId", "EffectiveDate"];
        private static readonly string[] WeightEntryIndexColumns = ["UserProfileId", "RecordedAtUtc"];
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "user_profiles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    DateOfBirth = table.Column<DateOnly>(type: "date", nullable: false),
                    BiologicalSex = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    HeightCm = table.Column<decimal>(type: "numeric(6,2)", precision: 6, scale: 2, nullable: false),
                    CurrentWeightKg = table.Column<decimal>(type: "numeric(6,2)", precision: 6, scale: 2, nullable: false),
                    TargetWeightKg = table.Column<decimal>(type: "numeric(6,2)", precision: 6, scale: 2, nullable: false),
                    ActivityLevel = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    GoalType = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    DietPreference = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    PreferredMeasurementSystem = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    Timezone = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    IsOnboardingComplete = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_profiles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "daily_nutrition_targets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserProfileId = table.Column<Guid>(type: "uuid", nullable: false),
                    EffectiveDate = table.Column<DateOnly>(type: "date", nullable: false),
                    BasalMetabolicRate = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: false),
                    TotalDailyEnergyExpenditure = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: false),
                    TargetCalories = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: false),
                    ProteinGrams = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: false),
                    CarbohydrateGrams = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: false),
                    FatGrams = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: false),
                    FibreGrams = table.Column<decimal>(type: "numeric(8,2)", precision: 8, scale: 2, nullable: false),
                    CalculationMethod = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    CalculationWarnings = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    GoalType = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_daily_nutrition_targets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_daily_nutrition_targets_user_profiles_UserProfileId",
                        column: x => x.UserProfileId,
                        principalTable: "user_profiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "weight_entries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserProfileId = table.Column<Guid>(type: "uuid", nullable: false),
                    WeightKg = table.Column<decimal>(type: "numeric(6,2)", precision: 6, scale: 2, nullable: false),
                    RecordedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_weight_entries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_weight_entries_user_profiles_UserProfileId",
                        column: x => x.UserProfileId,
                        principalTable: "user_profiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_daily_nutrition_targets_UserProfileId_EffectiveDate",
                table: "daily_nutrition_targets",
                columns: DailyNutritionTargetIndexColumns);

            migrationBuilder.CreateIndex(
                name: "IX_user_profiles_UserId",
                table: "user_profiles",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_weight_entries_UserProfileId_RecordedAtUtc",
                table: "weight_entries",
                columns: WeightEntryIndexColumns);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "daily_nutrition_targets");

            migrationBuilder.DropTable(
                name: "weight_entries");

            migrationBuilder.DropTable(
                name: "user_profiles");
        }
    }
}
