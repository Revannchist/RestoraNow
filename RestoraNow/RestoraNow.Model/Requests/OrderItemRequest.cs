using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class OrderItemRequest
    {
        public int OrderId { get; set; }
        public int MenuItemId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
    }
}
