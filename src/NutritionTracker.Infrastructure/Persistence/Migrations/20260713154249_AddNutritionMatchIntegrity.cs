using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NutritionTracker.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddNutritionMatchIntegrity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "HasIncompleteNutrition",
                table: "meals",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<decimal>(
                name: "ProteinGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3);

            migrationBuilder.AlterColumn<decimal>(
                name: "FibreGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3);

            migrationBuilder.AlterColumn<decimal>(
                name: "FatGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3);

            migrationBuilder.AlterColumn<decimal>(
                name: "CarbohydrateGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3);

            migrationBuilder.AlterColumn<decimal>(
                name: "Calories",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3);

            migrationBuilder.AddColumn<string>(
                name: "NutritionMatchState",
                table: "meal_items",
                type: "character varying(24)",
                maxLength: 24,
                nullable: false,
                defaultValue: "");

            migrationBuilder.Sql("UPDATE meal_items SET \"NutritionMatchState\" = CASE WHEN \"FoodId\" IS NULL THEN 'Unresolved' ELSE 'MatchedApproximate' END;");
            migrationBuilder.Sql("UPDATE meals SET \"HasIncompleteNutrition\" = EXISTS (SELECT 1 FROM meal_items WHERE meal_items.\"MealId\" = meals.\"Id\" AND meal_items.\"FoodId\" IS NULL);");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HasIncompleteNutrition",
                table: "meals");

            migrationBuilder.DropColumn(
                name: "NutritionMatchState",
                table: "meal_items");

            migrationBuilder.AlterColumn<decimal>(
                name: "ProteinGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3,
                oldNullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "FibreGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3,
                oldNullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "FatGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3,
                oldNullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "CarbohydrateGrams",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3,
                oldNullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "Calories",
                table: "meal_items",
                type: "numeric(9,3)",
                precision: 9,
                scale: 3,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(9,3)",
                oldPrecision: 9,
                oldScale: 3,
                oldNullable: true);
        }
    }
}
