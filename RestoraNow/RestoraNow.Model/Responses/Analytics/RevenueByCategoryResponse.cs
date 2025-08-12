using System;

namespace RestoraNow.Model.Responses.Analytics
{
    public class RevenueByCategoryResponse
    {
        public int CategoryId { get; set; }
        public string CategoryName { get; set; }
        public decimal Revenue { get; set; }
        public double Share { get; set; } // percentage in decimal (0.35 = 35%)
    }
}