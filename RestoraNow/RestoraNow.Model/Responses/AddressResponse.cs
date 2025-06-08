using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class AddressResponse
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public string Street { get; set; }

        public string City { get; set; }

        public string ZipCode { get; set; }

        public string Country { get; set; }

        public bool IsDefault { get; set; }
    }

}
