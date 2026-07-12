using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutritionTracker.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMealConfirmationAndDailySummaries : Migration
    {
        private static readonly string[] DailySummaryUserDateColumns = ["UserId", "SummaryDate"];
        private static readonly string[] CorrectionUserCreatedColumns = ["UserId", "CreatedAtUtc"];

        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "daily_nutrition_summaries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    SummaryDate = table.Column<DateOnly>(type: "date", nullable: false),
                    TotalCalories = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalProteinGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalCarbohydrateGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalFatGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalFibreGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    MealCount = table.Column<int>(type: "integer", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_daily_nutrition_summaries", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "user_food_corrections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    MealId = table.Column<Guid>(type: "uuid", nullable: false),
                    MealItemId = table.Column<Guid>(type: "uuid", nullable: true),
                    PredictedFoodId = table.Column<Guid>(type: "uuid", nullable: true),
                    CorrectedFoodId = table.Column<Guid>(type: "uuid", nullable: true),
                    PredictedGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    CorrectedGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    PredictedServingUnit = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    CorrectedServingUnit = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    CorrectionType = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_food_corrections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_user_food_corrections_meals_MealId",
                        column: x => x.MealId,
                        principalTable: "meals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_daily_nutrition_summaries_UserId_SummaryDate",
                table: "daily_nutrition_summaries",
                columns: DailySummaryUserDateColumns,
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_user_food_corrections_MealId",
                table: "user_food_corrections",
                column: "MealId");

            migrationBuilder.CreateIndex(
                name: "IX_user_food_corrections_UserId_CreatedAtUtc",
                table: "user_food_corrections",
                columns: CorrectionUserCreatedColumns);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "daily_nutrition_summaries");

            migrationBuilder.DropTable(
                name: "user_food_corrections");
        }
    }
}
