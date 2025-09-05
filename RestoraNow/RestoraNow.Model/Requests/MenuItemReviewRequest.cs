using System;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class MenuItemReviewRequest
    {
        [Required]
        public int UserId { get; set; }

        [Required]
        public int MenuItemId { get; set; }

        [Required(ErrorMessage = "Rating is required.")]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
        public int Rating { get; set; }

        [MaxLength(1000, ErrorMessage = "Comment cannot exceed 1000 characters.")]
        public string? Comment { get; set; }
    }
}