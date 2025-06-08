using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class AddressSearchModel
    {
        public int? UserId { get; set; }

        public string City { get; set; }

        public string Country { get; set; }

        public bool? IsDefault { get; set; }
    }

}
