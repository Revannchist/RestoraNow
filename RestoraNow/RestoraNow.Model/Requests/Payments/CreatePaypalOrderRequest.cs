using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests.Payments
{
    public class CreatePaypalOrderRequest
    {
        public int OrderId { get; set; }
        public string? Currency { get; set; }
    }
}
