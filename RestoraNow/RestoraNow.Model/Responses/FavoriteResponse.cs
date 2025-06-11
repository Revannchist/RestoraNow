using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class FavoriteResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }
        public int MenuItemId { get; set; }
        public string? MenuItemName { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
