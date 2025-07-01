using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class TableRequest
    {
        public int TableNumber { get; set; }
        public int Capacity { get; set; }
        public string? Location { get; set; }
        public bool IsAvailable { get; set; } = true;
        public string? Notes { get; set; }
        public int RestaurantId { get; set; }
    }
}
