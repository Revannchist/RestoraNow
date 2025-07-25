using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

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

        [MaxLength(50, ErrorMessage = "Location cannot exceed 50 characters.")]
        public string? Location { get; set; }

        public bool IsAvailable { get; set; } = true;

        [MaxLength(500, ErrorMessage = "Notes cannot exceed 500 characters.")]
        public string? Notes { get; set; }

        [Required(ErrorMessage = "Restaurant ID is required.")]
        //[Range(1, int.MaxValue, ErrorMessage = "Restaurant ID must be a positive number.")]
        public int RestaurantId { get; set; }
    }
}
