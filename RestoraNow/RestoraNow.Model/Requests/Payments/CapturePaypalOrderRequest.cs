using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests.Payments
{
    public class CapturePaypalOrderRequest
    {
        public string ProviderOrderId { get; set; } = null!;
    }
}
