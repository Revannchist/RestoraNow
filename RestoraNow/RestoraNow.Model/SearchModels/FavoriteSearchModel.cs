﻿using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class FavoriteSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? MenuItemId { get; set; }
    }
}
