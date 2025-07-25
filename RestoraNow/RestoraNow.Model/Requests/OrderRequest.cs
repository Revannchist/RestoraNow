using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class OrderRequest
    {
        [Required]
        //[Range(1, int.MaxValue, ErrorMessage = "UserId must be a positive number.")]
        public int UserId { get; set; }

        //[Range(1, int.MaxValue, ErrorMessage = "ReservationId must be a positive number if provided.")]
        public int? ReservationId { get; set; }

        [MinLength(1, ErrorMessage = "At least one MenuItemId must be provided.")]
        public List<int> MenuItemIds { get; set; } = new List<int>();
    }
}