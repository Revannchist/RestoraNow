using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class TableCreateRequest
    {
        [Required]
        public int TableNumber { get; set; }

        [Required]
        public int Capacity { get; set; }

        [MaxLength(50)]
        public string? Location { get; set; }

        public bool IsAvailable { get; set; } = true;

        [MaxLength(500)]
        public string? Notes { get; set; }

        [Required]
        public int RestaurantId { get; set; }
    }
}
