using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutritionTracker.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddFoodNutritionFoundation : Migration
    {
        private static readonly string[] AliasIndexColumns = ["FoodId", "NormalizedAlias"];
        private static readonly string[] ConversionIndexColumns = ["FoodId", "ServingUnitId"];
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "foods",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CanonicalName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    NormalizedName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Category = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    Cuisine = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    PreparationMethod = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    FoodState = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    CaloriesPer100Grams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    ProteinGramsPer100Grams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    CarbohydrateGramsPer100Grams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    FatGramsPer100Grams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    FibreGramsPer100Grams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    SugarGramsPer100Grams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: true),
                    SodiumMilligramsPer100Grams = table.Column<decimal>(type: "numeric(10,3)", precision: 10, scale: 3, nullable: true),
                    DataSource = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    SourceReference = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    SourceVersion = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    IsVerified = table.Column<bool>(type: "boolean", nullable: false),
                    IsUserCreated = table.Column<bool>(type: "boolean", nullable: false),
                    OwnerUserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_foods", x => x.Id);
                    table.CheckConstraint("CK_foods_nutrients_nonnegative", "\"CaloriesPer100Grams\" >= 0 AND \"ProteinGramsPer100Grams\" BETWEEN 0 AND 100 AND \"CarbohydrateGramsPer100Grams\" BETWEEN 0 AND 100 AND \"FatGramsPer100Grams\" BETWEEN 0 AND 100 AND \"FibreGramsPer100Grams\" BETWEEN 0 AND 100");
                });

            migrationBuilder.CreateTable(
                name: "serving_units",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Code = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Symbol = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: true),
                    UnitType = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    IsMetric = table.Column<bool>(type: "boolean", nullable: false),
                    IsCountBased = table.Column<bool>(type: "boolean", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_serving_units", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "food_aliases",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FoodId = table.Column<Guid>(type: "uuid", nullable: false),
                    Alias = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    NormalizedAlias = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    LanguageCode = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: true),
                    Region = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    Transliteration = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    AliasType = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    Priority = table.Column<int>(type: "integer", nullable: false),
                    IsPrimary = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_food_aliases", x => x.Id);
                    table.ForeignKey(
                        name: "FK_food_aliases_foods_FoodId",
                        column: x => x.FoodId,
                        principalTable: "foods",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "food_serving_conversions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FoodId = table.Column<Guid>(type: "uuid", nullable: false),
                    ServingUnitId = table.Column<Guid>(type: "uuid", nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    EquivalentGrams = table.Column<decimal>(type: "numeric(9,3)", precision: 9, scale: 3, nullable: false),
                    Source = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    SourceReference = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Confidence = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_food_serving_conversions", x => x.Id);
                    table.CheckConstraint("CK_food_serving_conversions_positive", "\"Quantity\" > 0 AND \"EquivalentGrams\" > 0");
                    table.ForeignKey(
                        name: "FK_food_serving_conversions_foods_FoodId",
                        column: x => x.FoodId,
                        principalTable: "foods",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_food_serving_conversions_serving_units_ServingUnitId",
                        column: x => x.ServingUnitId,
                        principalTable: "serving_units",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_food_aliases_FoodId_NormalizedAlias",
                table: "food_aliases",
                columns: AliasIndexColumns,
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_food_aliases_NormalizedAlias",
                table: "food_aliases",
                column: "NormalizedAlias");

            migrationBuilder.CreateIndex(
                name: "IX_food_serving_conversions_FoodId_ServingUnitId",
                table: "food_serving_conversions",
                columns: ConversionIndexColumns,
                unique: true,
                filter: "\"IsDefault\" = TRUE");

            migrationBuilder.CreateIndex(
                name: "IX_food_serving_conversions_ServingUnitId",
                table: "food_serving_conversions",
                column: "ServingUnitId");

            migrationBuilder.CreateIndex(
                name: "IX_foods_Category",
                table: "foods",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_foods_Cuisine",
                table: "foods",
                column: "Cuisine");

            migrationBuilder.CreateIndex(
                name: "IX_foods_IsActive",
                table: "foods",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_foods_IsVerified",
                table: "foods",
                column: "IsVerified");

            migrationBuilder.CreateIndex(
                name: "IX_foods_NormalizedName",
                table: "foods",
                column: "NormalizedName");

            migrationBuilder.CreateIndex(
                name: "IX_foods_OwnerUserId",
                table: "foods",
                column: "OwnerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_serving_units_Code",
                table: "serving_units",
                column: "Code",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "food_aliases");

            migrationBuilder.DropTable(
                name: "food_serving_conversions");

            migrationBuilder.DropTable(
                name: "foods");

            migrationBuilder.DropTable(
                name: "serving_units");
        }
    }
}
