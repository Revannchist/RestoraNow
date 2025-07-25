using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class AddressRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Street { get; set; }

        [MaxLength(50)]
        public string City { get; set; }

        [MaxLength(10)]
        public string ZipCode { get; set; }

        [MaxLength(50)]
        public string Country { get; set; }

        public bool IsDefault { get; set; }
    }

}
