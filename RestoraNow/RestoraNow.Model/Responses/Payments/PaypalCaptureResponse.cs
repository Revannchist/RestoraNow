using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses.Payments
{
    public class PaypalCaptureResponse
    {
        public string CaptureId { get; set; } = null!;
        public string Status { get; set; } = null!;
        public decimal Amount { get; set; }
        public DateTime TransactionDate { get; set; }
    }
}
