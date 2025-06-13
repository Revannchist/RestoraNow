using System;
using System.Collections.Generic;
using System.Text;
using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class AddressSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? City { get; set; }
    }

}
