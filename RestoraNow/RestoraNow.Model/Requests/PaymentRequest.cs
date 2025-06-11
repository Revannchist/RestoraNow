using RestoraNow.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class PaymentRequest
    {
        [Required]
        public int OrderId { get; set; }

        [Required]
        public decimal Amount { get; set; }

        [Required]
        public PaymentMethod Method { get; set; }

        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    }
}
