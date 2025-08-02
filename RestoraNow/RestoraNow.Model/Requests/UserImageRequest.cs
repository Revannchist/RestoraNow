using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class UserImageRequest
    {
        [Required(ErrorMessage = "Image is required.")]
        //[Url(ErrorMessage = "Invalid URL format.")]
        public string Url { get; set; } = null!;

        [MaxLength(100, ErrorMessage = "Description cannot exceed 100 characters.")]
        public string? Description { get; set; }

        [Required(ErrorMessage = "User ID is required.")]
        //[Range(1, int.MaxValue, ErrorMessage = "User ID must be a positive number.")]
        public int UserId { get; set; }
    }
}
