using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests.Mobile.User
{
    public class ChangePasswordRequest
    {
        [Required] public string CurrentPassword { get; set; } = default!;
        [Required, MinLength(6)] public string NewPassword { get; set; } = default!;
    }
}
