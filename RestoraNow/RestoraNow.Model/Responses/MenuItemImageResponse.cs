using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class MenuItemImageResponse
    {
        public int Id { get; set; }
        public string Url { get; set; } = null!;
        public string? Description { get; set; }

        public int MenuItemId { get; set; }
        public string? MenuItemName { get; set; }
    }
}
