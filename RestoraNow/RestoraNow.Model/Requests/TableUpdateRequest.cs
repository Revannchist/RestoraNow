using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class TableUpdateRequest
    {
        public int? TableNumber { get; set; }

        public int? Capacity { get; set; }

        [MaxLength(50)]
        public string? Location { get; set; }

        public bool? IsAvailable { get; set; }

        [MaxLength(500)]
        public string? Notes { get; set; }

        public int? RestaurantId { get; set; }
    }
}
