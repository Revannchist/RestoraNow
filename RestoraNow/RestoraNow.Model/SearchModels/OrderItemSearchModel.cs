﻿using RestoraNow.Model.Base;
using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class OrderItemSearchModel : BaseSearchObject
    {
        public int? OrderId { get; set; }
        public int? MenuItemId { get; set; }
    }
}
