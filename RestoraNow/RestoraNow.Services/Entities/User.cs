using Microsoft.AspNetCore.Identity;

namespace RestoraNow.Services.Entities
{
    public class User : IdentityUser<int> // Use <int> if you're using int as PK
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? LastLoginAt { get; set; }

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<Order> Orders { get; set; } = new List<Order>();
        public UserImage? Image { get; set; }
        public ICollection<Address> Addresses { get; set; } = new List<Address>();

    }
}