using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RestoraNow.Services.Migrations
{
    /// <inheritdoc />
    public partial class newdb2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_BaseEntities_ApplicationUsers_UserId",
                table: "BaseEntities");

            migrationBuilder.DropForeignKey(
                name: "FK_BaseEntities_BaseEntities_TableId",
                table: "BaseEntities");

            migrationBuilder.DropForeignKey(
                name: "FK_BaseEntities_BaseEntities_TableId1",
                table: "BaseEntities");

            migrationBuilder.DropPrimaryKey(
                name: "PK_BaseEntities",
                table: "BaseEntities");

            migrationBuilder.DropIndex(
                name: "IX_BaseEntities_TableId",
                table: "BaseEntities");

            migrationBuilder.DropIndex(
                name: "IX_BaseEntities_TableId1",
                table: "BaseEntities");

            migrationBuilder.DropIndex(
                name: "IX_BaseEntities_UserId",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "ConfirmedAt",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "Discriminator",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "GuestCount",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "IsDeleted",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "ReservationDate",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "ReservationTime",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "SpecialRequests",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "TableId",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "TableId1",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "BaseEntities");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "BaseEntities");

            migrationBuilder.RenameTable(
                name: "BaseEntities",
                newName: "Tables");

            migrationBuilder.AlterColumn<int>(
                name: "TableNumber",
                table: "Tables",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Notes",
                table: "Tables",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(500)",
                oldMaxLength: 500,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Location",
                table: "Tables",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50,
                oldNullable: true);

            migrationBuilder.AlterColumn<bool>(
                name: "IsAvailable",
                table: "Tables",
                type: "bit",
                nullable: false,
                defaultValue: false,
                oldClrType: typeof(bool),
                oldType: "bit",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "Capacity",
                table: "Tables",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Tables",
                table: "Tables",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "Reservations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    TableId = table.Column<int>(type: "int", nullable: false),
                    ReservationDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ReservationTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    GuestCount = table.Column<int>(type: "int", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    SpecialRequests = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ConfirmedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reservations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reservations_ApplicationUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "ApplicationUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reservations_Tables_TableId",
                        column: x => x.TableId,
                        principalTable: "Tables",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_TableId",
                table: "Reservations",
                column: "TableId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_UserId",
                table: "Reservations",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Reservations");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Tables",
                table: "Tables");

            migrationBuilder.RenameTable(
                name: "Tables",
                newName: "BaseEntities");

            migrationBuilder.AlterColumn<int>(
                name: "TableNumber",
                table: "BaseEntities",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<string>(
                name: "Notes",
                table: "BaseEntities",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(500)",
                oldMaxLength: 500);

            migrationBuilder.AlterColumn<string>(
                name: "Location",
                table: "BaseEntities",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<bool>(
                name: "IsAvailable",
                table: "BaseEntities",
                type: "bit",
                nullable: true,
                oldClrType: typeof(bool),
                oldType: "bit");

            migrationBuilder.AlterColumn<int>(
                name: "Capacity",
                table: "BaseEntities",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<DateTime>(
                name: "ConfirmedAt",
                table: "BaseEntities",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "BaseEntities",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Discriminator",
                table: "BaseEntities",
                type: "nvarchar(13)",
                maxLength: 13,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "GuestCount",
                table: "BaseEntities",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "BaseEntities",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReservationDate",
                table: "BaseEntities",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<TimeSpan>(
                name: "ReservationTime",
                table: "BaseEntities",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SpecialRequests",
                table: "BaseEntities",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "BaseEntities",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TableId",
                table: "BaseEntities",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TableId1",
                table: "BaseEntities",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "BaseEntities",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UserId",
                table: "BaseEntities",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_BaseEntities",
                table: "BaseEntities",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_BaseEntities_TableId",
                table: "BaseEntities",
                column: "TableId");

            migrationBuilder.CreateIndex(
                name: "IX_BaseEntities_TableId1",
                table: "BaseEntities",
                column: "TableId1");

            migrationBuilder.CreateIndex(
                name: "IX_BaseEntities_UserId",
                table: "BaseEntities",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_BaseEntities_ApplicationUsers_UserId",
                table: "BaseEntities",
                column: "UserId",
                principalTable: "ApplicationUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_BaseEntities_BaseEntities_TableId",
                table: "BaseEntities",
                column: "TableId",
                principalTable: "BaseEntities",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_BaseEntities_BaseEntities_TableId1",
                table: "BaseEntities",
                column: "TableId1",
                principalTable: "BaseEntities",
                principalColumn: "Id");
        }
    }
}
