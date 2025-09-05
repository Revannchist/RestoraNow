using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace RestoraNow.Services.Entities
{
    [Index(nameof(UserId), nameof(MenuItemId), IsUnique = true)]
    public class MenuItemReview
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; }

        [Required]
        public int MenuItemId { get; set; }

        [ForeignKey(nameof(MenuItemId))]
        public MenuItem MenuItem { get; set; }

        [Required]
        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
