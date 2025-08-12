using System;

namespace RestoraNow.Model.Responses.Analytics
{
    public class SummaryResponse
    {
        public decimal TotalRevenue { get; set; }
        public int Reservations { get; set; }
        public double AvgRating { get; set; }
        public int NewUsers { get; set; }
    }
}