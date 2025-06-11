using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class OrderItemSearchModel
    {
        public int? OrderId { get; set; }
        public int? MenuItemId { get; set; }
    }
}
