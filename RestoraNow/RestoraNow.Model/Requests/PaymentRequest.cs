using RestoraNow.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class PaymentRequest
    {
        [Required]
        //[Range(1, int.MaxValue, ErrorMessage = "OrderId must be a positive number.")]
        public int OrderId { get; set; }

        [Required]
        //[Range(0.01, double.MaxValue, ErrorMessage = "Amount must be greater than zero.")]
        public decimal Amount { get; set; }

        [Required(ErrorMessage = "Payment method is required.")]
        public PaymentMethod Method { get; set; }

        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    }
}
