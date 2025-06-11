using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class FavoriteRequest
    {
        public int UserId { get; set; }
        public int MenuItemId { get; set; }
    }
}
