using System;
using System.Collections.Generic;
using System.Text;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class AddressRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        public string Street { get; set; }

        public string City { get; set; }

        public string ZipCode { get; set; }

        public string Country { get; set; }

        public bool IsDefault { get; set; }
    }

}
