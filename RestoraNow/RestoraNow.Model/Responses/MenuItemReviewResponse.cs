using System;

namespace RestoraNow.Model.Responses
{
    public class MenuItemReviewResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }
        public string? UserEmail { get; set; }

        public int MenuItemId { get; set; }
        public string? MenuItemName { get; set; }

        public int Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
