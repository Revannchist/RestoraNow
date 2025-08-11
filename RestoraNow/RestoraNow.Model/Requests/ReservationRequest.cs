using RestoraNow.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class ReservationRequest
    {
        [Required]
        //[Range(1, int.MaxValue, ErrorMessage = "UserId must be a positive number.")]
        public int UserId { get; set; }

        [Required]
        //[Range(1, int.MaxValue, ErrorMessage = "TableId must be a positive number.")]
        public int TableId { get; set; }

        [Required(ErrorMessage = "Reservation date is required.")]
        [DataType(DataType.Date)]
        public DateTime ReservationDate { get; set; }

        [Required(ErrorMessage = "Reservation time is required.")]
        public TimeSpan ReservationTime { get; set; }

        [Required]
        [Range(1, 20, ErrorMessage = "Guest count must be between 1 and 20.")]
        public int GuestCount { get; set; }

        [MaxLength(500)]
        public string? SpecialRequests { get; set; }

        public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    }
}