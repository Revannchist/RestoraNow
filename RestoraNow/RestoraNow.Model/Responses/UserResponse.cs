﻿using System;
using System.Collections.Generic;

namespace RestoraNow.Model.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Username { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public string? PhoneNumber { get; set; }

        public List<string> Roles { get; set; } = new List<string>();
        public string? ImageUrl { get; set; }
    }
}
