using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests.Restaurant
{
    public class RestaurantUpdateRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; }

        [MaxLength(200)]
        public string? Address { get; set; }

        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        [EmailAddress]
        [MaxLength(100)]
        public string? Email { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }

    }
}
