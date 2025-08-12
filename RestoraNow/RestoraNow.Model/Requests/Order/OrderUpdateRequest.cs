using RestoraNow.Model.Enums;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests.Order
{
    public class OrderUpdateRequest
    {
        [Required]
        public int UserId { get; set; }

        public int? ReservationId { get; set; }

        // Same semantics as create: duplicates represent quantity
        [MinLength(1, ErrorMessage = "At least one MenuItemId must be provided.")]
        public List<int> MenuItemIds { get; set; } = new List<int>();

        [Required]
        public OrderStatus Status { get; set; }
    }
}
