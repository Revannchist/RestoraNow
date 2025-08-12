using System;

namespace RestoraNow.Model.Responses.Analytics
{
    public class RevenueByPeriodResponse
    {
        public DateTime Period { get; set; } // Day, Week start, or Month start depending on grouping
        public decimal Revenue { get; set; }
    }
}
