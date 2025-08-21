using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace RestoraNow.Model.Requests.Mobile.User
{
    public class MeImageRequest
    {
        [Required] public string Url { get; set; } = default!;
    }
}
