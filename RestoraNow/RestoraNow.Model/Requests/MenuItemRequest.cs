using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class MenuItemRequest
    {
        public string Name { get; set; }
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public bool IsAvailable { get; set; } = true;
        public bool IsSpecialOfTheDay { get; set; } = false;
        public int CategoryId { get; set; }
    }
}
