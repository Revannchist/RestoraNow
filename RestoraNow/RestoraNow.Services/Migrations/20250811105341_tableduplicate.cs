using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RestoraNow.Services.Migrations
{
    /// <inheritdoc />
    public partial class tableduplicate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Tables_RestaurantId",
                table: "Tables");

            migrationBuilder.CreateIndex(
                name: "IX_Tables_RestaurantId_TableNumber",
                table: "Tables",
                columns: new[] { "RestaurantId", "TableNumber" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Tables_RestaurantId_TableNumber",
                table: "Tables");

            migrationBuilder.CreateIndex(
                name: "IX_Tables_RestaurantId",
                table: "Tables",
                column: "RestaurantId");
        }
    }
}
