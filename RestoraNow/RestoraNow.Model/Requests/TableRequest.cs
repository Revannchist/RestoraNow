using System;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class TableRequest
    {
        [Required(ErrorMessage = "Table number is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Table number must be a positive number.")]
        public int TableNumber { get; set; }

        [Required(ErrorMessage = "Capacity is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Capacity must be at least 1.")]
        public int Capacity { get; set; }

        [Required(ErrorMessage ="Location is required")]
        [MaxLength(20, ErrorMessage = "Location cannot exceed 20 characters.")]
        public string? Location { get; set; }

        public bool IsAvailable { get; set; } = true;

        [MaxLength(100, ErrorMessage = "Notes cannot exceed 100 characters.")]
        public string? Notes { get; set; }

        [Required(ErrorMessage = "Restaurant ID is required.")]
        //[Range(1, int.MaxValue, ErrorMessage = "Restaurant ID must be a positive number.")]
        public int RestaurantId { get; set; }
    }
}