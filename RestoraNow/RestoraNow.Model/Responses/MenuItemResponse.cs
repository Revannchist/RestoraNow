using System.Collections.Generic;

namespace RestoraNow.Model.Responses
{
    public class MenuItemResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public bool IsAvailable { get; set; }
        public bool IsSpecialOfTheDay { get; set; }
        public int CategoryId { get; set; }
        public string CategoryName { get; set; }

        public List<string> ImageUrls { get; set; } = new List<string>();
    }
}
