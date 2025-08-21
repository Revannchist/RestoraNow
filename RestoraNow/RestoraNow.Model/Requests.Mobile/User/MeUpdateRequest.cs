using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests.Mobile.User
{
    public class MeUpdateRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }
    }
}
