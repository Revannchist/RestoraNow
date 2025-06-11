using System;
using System.Collections.Generic;
using System.Text;
using RestoraNow.Model.Enums;

namespace RestoraNow.Model.SearchModels
{
    public class OrderSearchModel
    {
        public int? UserId { get; set; }
        public OrderStatus? Status { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}
