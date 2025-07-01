using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class TableResponse
    {
        public int Id { get; set; }
        public int TableNumber { get; set; }
        public int Capacity { get; set; }
        public string? Location { get; set; }
        public bool IsAvailable { get; set; }
        public string? Notes { get; set; }
        public int RestaurantId { get; set; }
        public string? RestaurantName { get; set; }
    }
}
