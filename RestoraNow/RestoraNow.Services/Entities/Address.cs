using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Services.Entities
{
    public class Address
    {
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }
        public User User { get; set; }

        [Required]
        public string Street { get; set; }

        public string City { get; set; }

        public string ZipCode { get; set; }

        public string Country { get; set; }

        public bool IsDefault { get; set; }
    }

}
