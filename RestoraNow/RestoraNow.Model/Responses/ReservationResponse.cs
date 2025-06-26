using RestoraNow.Model.Enums;
using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }

        public int TableId { get; set; }
        public string? TableName { get; set; }

        public DateTime ReservationDate { get; set; }
        public TimeSpan ReservationTime { get; set; }
        public int GuestCount { get; set; }

        public ReservationStatus Status { get; set; }
        public string? SpecialRequests { get; set; }
        public DateTime? ConfirmedAt { get; set; }
    }
}
