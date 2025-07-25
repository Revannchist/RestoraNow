using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class OrderItemRequest
    {
        [Required]
        //[Range(1, int.MaxValue, ErrorMessage = "OrderId must be a positive integer.")]
        public int OrderId { get; set; }

        [Required]
        //[Range(1, int.MaxValue, ErrorMessage = "MenuItemId must be a positive integer.")]
        public int MenuItemId { get; set; }

        [Required]
        //[Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1.")]
        public int Quantity { get; set; }

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "UnitPrice must be greater than 0.")]
        public decimal UnitPrice { get; set; }
    }
}
