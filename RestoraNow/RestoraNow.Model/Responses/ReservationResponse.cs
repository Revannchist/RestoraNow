using RestoraNow.Model.Enums;
using System;

namespace RestoraNow.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }

        public int TableId { get; set; }
        public string? TableNumber { get; set; }

        public DateTime ReservationDate { get; set; }

        //[JsonConverter(typeof(JsonTimeSpanConverter))]
        public TimeSpan ReservationTime { get; set; }
        public int GuestCount { get; set; }

        public ReservationStatus Status { get; set; }
        public string? SpecialRequests { get; set; }
        public DateTime? ConfirmedAt { get; set; }
    }
}