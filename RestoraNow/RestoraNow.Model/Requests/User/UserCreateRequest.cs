using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests.User
{
    public class UserCreateRequest
    {
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = default!;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = default!;

        [Required]
        [EmailAddress(ErrorMessage = "Please enter a valid email.")]
        [MaxLength(100)]
        public string Email { get; set; } = default!;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = default!;

        [Phone]
        [MaxLength(30)]
        public string? PhoneNumber { get; set; } = default!;

        public bool IsActive { get; set; } = true;

        public IEnumerable<string>? Roles { get; set; } = new List<string>();
    }
}
