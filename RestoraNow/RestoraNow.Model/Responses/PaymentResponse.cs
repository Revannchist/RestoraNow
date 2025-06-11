using RestoraNow.Model.Enums;
using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class PaymentResponse
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public decimal Amount { get; set; }
        public PaymentMethod Method { get; set; }
        public PaymentStatus Status { get; set; }
        public DateTime PaidAt { get; set; }
    }
}
