using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses.Payments
{
    public class PaypalOrderResponse
    {
        public string ProviderOrderId { get; set; } = null!;
        public string ApprovalUrl { get; set; } = null!;
        public string Status { get; set; } = "CREATED";
    }
}
