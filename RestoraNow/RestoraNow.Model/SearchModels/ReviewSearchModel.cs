using RestoraNow.Model.Base;
using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class ReviewSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? RestaurantId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
    }
}
