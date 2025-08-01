﻿using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Services.Entities
{
    public class MenuItem
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }

        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }

        public bool IsAvailable { get; set; } = true;

        public bool IsSpecialOfTheDay { get; set; } = false;

        [Required]
        public int CategoryId { get; set; }

        [ForeignKey("CategoryId")]
        public virtual MenuCategory Category { get; set; }

        public ICollection<MenuItemImage> Images { get; set; } = new List<MenuItemImage>();

        public ICollection<OrderItem> OrderItems { get; set; }
    }
}