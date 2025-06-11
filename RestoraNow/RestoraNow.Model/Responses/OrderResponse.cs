using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class OrderResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Status { get; set; }
        public List<OrderItemResponse> OrderItems { get; set; }
    }

    //public class OrderItemResponse
    //{
    //    public int MenuItemId { get; set; }
    //    public string MenuItemName { get; set; }
    //    public decimal MenuItemPrice { get; set; }
    //}
}
