using System.Collections.Generic;

namespace RestoraNow.Model.Requests.User
{
    public class UserUpdateRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public bool? IsActive { get; set; }
        public IEnumerable<string>? Roles { get; set; }
        public string? Password { get; set; }
    }
}
