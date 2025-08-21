using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests.Mobile.User
{
    public class ChangeEmailRequest
    {
        [Required, EmailAddress] public string NewEmail { get; set; } = default!;
        public string? CurrentPassword { get; set; } // reauth
    }
}
