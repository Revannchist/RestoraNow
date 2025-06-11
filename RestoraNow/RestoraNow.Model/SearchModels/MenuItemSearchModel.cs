using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class MenuItemSearchModel
    {
        public string? Name { get; set; }
        public int? CategoryId { get; set; }
        public bool? IsAvailable { get; set; }
        public bool? IsSpecialOfTheDay { get; set; }
    }
}
