using System;

namespace RestoraNow.Model.Responses.Mobile.User
{
    public class MeResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = default!;
        public string LastName { get; set; } = default!;
        public string Email { get; set; } = default!;
        public string Username { get; set; } = default!;
        public string? PhoneNumber { get; set; }
        public string? ImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastLoginAt { get; set; }
    }
}
