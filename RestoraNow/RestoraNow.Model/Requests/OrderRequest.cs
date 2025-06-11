using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class OrderRequest
    {
        public int UserId { get; set; }
        public int? ReservationId { get; set; }
        public List<int> MenuItemIds { get; set; } = new List<int>();
    }
}
