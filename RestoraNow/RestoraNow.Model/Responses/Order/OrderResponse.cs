using System;
using System.Collections.Generic;

namespace RestoraNow.Model.Responses.Order
{
    public class OrderResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Status { get; set; }
        public List<OrderItemResponse> OrderItems { get; set; }

        public string? UserName { get; set; }
        public decimal Total { get; set; }
    }

}