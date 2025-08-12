using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests.Order
{
    public class OrderCreateRequest
    {
        [Required]
        public int UserId { get; set; }

        public int? ReservationId { get; set; }

        [MinLength(1, ErrorMessage = "At least one MenuItemId must be provided.")]
        public List<int> MenuItemIds { get; set; } = new List<int>();
    }
}