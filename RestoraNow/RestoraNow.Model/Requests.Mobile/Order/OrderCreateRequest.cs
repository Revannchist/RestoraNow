using System.Collections.Generic;

namespace RestoraNow.Model.Requests.Mobile.Order
{
    public class OrderCreateRequest
    {
        public int UserId { get; set; }

        public int? ReservationId { get; set; }

        public List<int> MenuItemIds { get; set; } = new List<int>();
    }
}