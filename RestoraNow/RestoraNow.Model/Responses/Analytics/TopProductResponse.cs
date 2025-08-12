using System;

namespace RestoraNow.Model.Responses.Analytics
{
    public class TopProductResponse
    {
        public int MenuItemId { get; set; }
        public string ProductName { get; set; }
        public string CategoryName { get; set; }
        public int SoldQty { get; set; }
        public decimal Revenue { get; set; }
    }
}
