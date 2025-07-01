using RestoraNow.Model.Base;
using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class TableSearchModel : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public int? Capacity { get; set; }
        public bool? IsAvailable { get; set; }
    }
}
