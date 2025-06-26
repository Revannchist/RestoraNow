using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class UserImageResponse
    {
        public int Id { get; set; }
        public string Url { get; set; } = null!;
        public string? Description { get; set; }
        public int UserId { get; set; }
        public string? Username { get; set; }
    }
}
