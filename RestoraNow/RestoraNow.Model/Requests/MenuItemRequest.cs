using System;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class MenuItemRequest
    {
        [Required]
        [MaxLength(20)]
        public string Name { get; set; }

        public string? Description { get; set; }

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0.")]
        public decimal Price { get; set; }

        public bool IsAvailable { get; set; } = true;

        public bool IsSpecialOfTheDay { get; set; } = false;

        [Required]
        public int CategoryId { get; set; }
    }
}
