using RestoraNow.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class ReservationRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        public int TableId { get; set; }

        [Required]
        public DateTime ReservationDate { get; set; }

        [Required]
        public TimeSpan ReservationTime { get; set; }

        [Required]
        public int GuestCount { get; set; }

        public string? SpecialRequests { get; set; }

        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    }
}
