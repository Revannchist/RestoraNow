using RestoraNow.Model.Base;
using RestoraNow.Model.Enums;
using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class PaymentSearchModel : BaseSearchObject
    {
        public int? OrderId { get; set; }
        public PaymentStatus? Status { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}
