using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace RestoraNow.Services.Entities
{

    [Index(nameof(RestaurantId), nameof(TableNumber), IsUnique = true)]
    public class Table
    {
        public int Id { get; set; }

        [Required]
        public int TableNumber { get; set; }

        [Required]
        public int Capacity { get; set; }

        [MaxLength(50)]
        public string Location { get; set; }

        public bool IsAvailable { get; set; } = true;

        [MaxLength(500)]
        public string? Notes { get; set; }

        public int RestaurantId { get; set; }

        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; }

        public ICollection<Reservation> Reservations { get; set; }
    }
}