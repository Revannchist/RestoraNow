using RestoraNow.Model.Base;
using System;

namespace RestoraNow.Model.SearchModels
{
    public class AnalyticsSearchModel : BaseSearchObject
    {
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }

        // "day" | "week" | "month"
        public string? GroupBy { get; set; } = "day";

        public int? Take { get; set; } = 5;
    }
}