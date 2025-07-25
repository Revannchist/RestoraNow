using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests.User
{
    public class UserCreateRequest
    {
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; }

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; }

        [Required]
        [EmailAddress]
        [MaxLength(100)]
        public string Email { get; set; }

        [Required]
        [MinLength(6)]
        public string Password { get; set; }

        [Required]
        [Phone]
        [MaxLength(30)]
        public string PhoneNumber { get; set; }

        public bool IsActive { get; set; } = true;

        public IEnumerable<string>? Roles { get; set; } = new List<string>();
    }
}
