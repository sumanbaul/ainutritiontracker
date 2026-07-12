using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutritionTracker.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddMealAnalysisPipeline : Migration
    {
        private static readonly string[] AnalysisHashIndexColumns = ["UserId", "InputImageHash"];
        private static readonly string[] MealImageHashIndexColumns = ["MealId", "Sha256Hash"];
        private static readonly string[] MealConsumedIndexColumns = ["UserId", "ConsumedAtUtc"];
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "meals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    MealType = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    ConsumedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Name = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    TotalCalories = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalProteinGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalCarbohydrateGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalFatGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    TotalFibreGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    OverallConfidence = table.Column<decimal>(type: "numeric(5,4)", precision: 5, scale: 4, nullable: false),
                    Status = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_meals", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ai_analysis_runs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MealId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    Provider = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    Model = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    PromptVersion = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    SchemaVersion = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    InputImageHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    Status = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    ProcessingTimeMs = table.Column<long>(type: "bigint", nullable: false),
                    ProviderRequestId = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    FailureType = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    ErrorCode = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_analysis_runs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ai_analysis_runs_meals_MealId",
                        column: x => x.MealId,
                        principalTable: "meals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "meal_images",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MealId = table.Column<Guid>(type: "uuid", nullable: false),
                    StorageKey = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    MimeType = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    ByteLength = table.Column<long>(type: "bigint", nullable: false),
                    Sha256Hash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    Width = table.Column<int>(type: "integer", nullable: true),
                    Height = table.Column<int>(type: "integer", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_meal_images", x => x.Id);
                    table.ForeignKey(
                        name: "FK_meal_images_meals_MealId",
                        column: x => x.MealId,
                        principalTable: "meals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "meal_items",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MealId = table.Column<Guid>(type: "uuid", nullable: false),
                    FoodId = table.Column<Guid>(type: "uuid", nullable: true),
                    DetectedName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    RegionalName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    CanonicalName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    PreparationMethod = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    EstimatedQuantity = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    EstimatedServingUnit = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    EstimatedGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    Calories = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    ProteinGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    CarbohydrateGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    FatGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    FibreGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    RecognitionConfidence = table.Column<decimal>(type: "numeric(5,4)", precision: 5, scale: 4, nullable: false),
                    PortionConfidence = table.Column<decimal>(type: "numeric(5,4)", precision: 5, scale: 4, nullable: false),
                    NutritionMatchConfidence = table.Column<decimal>(type: "numeric(5,4)", precision: 5, scale: 4, nullable: false),
                    RequiresConfirmation = table.Column<bool>(type: "boolean", nullable: false),
                    UserConfirmed = table.Column<bool>(type: "boolean", nullable: false),
                    Warnings = table.Column<string>(type: "character varying(1500)", maxLength: 1500, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_meal_items", x => x.Id);
                    table.ForeignKey(
                        name: "FK_meal_items_foods_FoodId",
                        column: x => x.FoodId,
                        principalTable: "foods",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_meal_items_meals_MealId",
                        column: x => x.MealId,
                        principalTable: "meals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ai_analysis_runs_MealId",
                table: "ai_analysis_runs",
                column: "MealId");

            migrationBuilder.CreateIndex(
                name: "IX_ai_analysis_runs_UserId_InputImageHash",
                table: "ai_analysis_runs",
                columns: AnalysisHashIndexColumns);

            migrationBuilder.CreateIndex(
                name: "IX_meal_images_MealId",
                table: "meal_images",
                column: "MealId");

            migrationBuilder.CreateIndex(
                name: "IX_meal_images_MealId_Sha256Hash",
                table: "meal_images",
                columns: MealImageHashIndexColumns);

            migrationBuilder.CreateIndex(
                name: "IX_meal_items_FoodId",
                table: "meal_items",
                column: "FoodId");

            migrationBuilder.CreateIndex(
                name: "IX_meal_items_MealId",
                table: "meal_items",
                column: "MealId");

            migrationBuilder.CreateIndex(
                name: "IX_meals_Status",
                table: "meals",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_meals_UserId_ConsumedAtUtc",
                table: "meals",
                columns: MealConsumedIndexColumns);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ai_analysis_runs");

            migrationBuilder.DropTable(
                name: "meal_images");

            migrationBuilder.DropTable(
                name: "meal_items");

            migrationBuilder.DropTable(
                name: "meals");
        }
    }
}
