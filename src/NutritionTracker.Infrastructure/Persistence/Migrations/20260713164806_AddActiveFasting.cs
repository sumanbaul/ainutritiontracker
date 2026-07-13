using System;
using Microsoft.EntityFrameworkCore.Migrations;

#pragma warning disable CA1861 // EF-generated migration metadata uses inline column arrays.

#nullable disable

namespace NutritionTracker.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddActiveFasting : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "active_fasts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    StartedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TargetDurationMinutes = table.Column<int>(type: "integer", nullable: false),
                    PlannedEndAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    StartOperationId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    EndOperationId = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    CompletedFastingWindowId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Version = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_active_fasts", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_active_fasts_UserId_StartOperationId",
                table: "active_fasts",
                columns: new[] { "UserId", "StartOperationId" },
                unique: true,
                filter: "\"StartOperationId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_active_fasts_UserId_Status",
                table: "active_fasts",
                columns: new[] { "UserId", "Status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "active_fasts");
        }
    }
}
#pragma warning restore CA1861
