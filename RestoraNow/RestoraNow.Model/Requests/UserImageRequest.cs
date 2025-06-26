using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class UserImageRequest
    {
        public string Url { get; set; } = null!;
        public string? Description { get; set; }
        public int UserId { get; set; }
    }
}
