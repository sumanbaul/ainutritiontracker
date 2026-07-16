using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable
#pragma warning disable CA1861 // EF Core generated migration creates an index-column array.

namespace NutritionTracker.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class TemporaryAutomaticFoodResolution : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "PendingMealId",
                table: "foods",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "food_resolution_events",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    MealId = table.Column<Guid>(type: "uuid", nullable: false),
                    MealItemId = table.Column<Guid>(type: "uuid", nullable: true),
                    SelectedFoodId = table.Column<Guid>(type: "uuid", nullable: true),
                    DetectedName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    Grams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    Calories = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    ProteinGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    CarbohydrateGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    FatGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    FibreGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    Method = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    Confidence = table.Column<decimal>(type: "numeric(5,4)", precision: 5, scale: 4, nullable: true),
                    Provider = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    Model = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    Rationale = table.Column<string>(type: "character varying(600)", maxLength: 600, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Version = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_food_resolution_events", x => x.Id);
                    table.ForeignKey(
                        name: "FK_food_resolution_events_meals_MealId",
                        column: x => x.MealId,
                        principalTable: "meals",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_foods_PendingMealId",
                table: "foods",
                column: "PendingMealId");

            migrationBuilder.CreateIndex(
                name: "IX_food_resolution_events_MealId",
                table: "food_resolution_events",
                column: "MealId");

            migrationBuilder.CreateIndex(
                name: "IX_food_resolution_events_MealItemId",
                table: "food_resolution_events",
                column: "MealItemId");

            migrationBuilder.CreateIndex(
                name: "IX_food_resolution_events_UserId_MealId",
                table: "food_resolution_events",
                columns: new[] { "UserId", "MealId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "food_resolution_events");

            migrationBuilder.DropIndex(
                name: "IX_foods_PendingMealId",
                table: "foods");

            migrationBuilder.DropColumn(
                name: "PendingMealId",
                table: "foods");
        }
    }
}
#pragma warning restore CA1861
