using System;

namespace RestoraNow.Model.Responses.Order
{
    public class OrderItemResponse
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int MenuItemId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal TotalPrice { get; set; }

        public string? MenuItemName { get; set; }
    }
}