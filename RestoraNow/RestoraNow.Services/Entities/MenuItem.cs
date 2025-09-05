using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace RestoraNow.Services.Entities
{
    public class MenuItem
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Name { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }

        [Required, Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }

        public bool IsAvailable { get; set; } = true;
        public bool IsSpecialOfTheDay { get; set; } = false;

        [Required]
        public int CategoryId { get; set; }

        [ForeignKey(nameof(CategoryId))]
        public virtual MenuCategory Category { get; set; }

        public virtual MenuItemImage? Image { get; set; }

        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();

        // multiple reviews; one per user enforced via unique index in DB
        public virtual ICollection<MenuItemReview> Reviews { get; set; } = new List<MenuItemReview>();
    }
}
