using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RestoraNow.Services.Migrations
{
    /// <inheritdoc />
    public partial class newupdate2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MenuItemImages_MenuItemId",
                table: "MenuItemImages");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "MenuItem");

            migrationBuilder.CreateIndex(
                name: "IX_MenuItemImages_MenuItemId",
                table: "MenuItemImages",
                column: "MenuItemId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_MenuItemImages_MenuItemId",
                table: "MenuItemImages");

            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "MenuItem",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_MenuItemImages_MenuItemId",
                table: "MenuItemImages",
                column: "MenuItemId");
        }
    }
}
