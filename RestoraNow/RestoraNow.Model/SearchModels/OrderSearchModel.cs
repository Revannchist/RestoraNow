using System;
using RestoraNow.Model.Base;
using RestoraNow.Model.Enums;

namespace RestoraNow.Model.SearchModels
{
    public class OrderSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }
        public OrderStatus? Status { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}
