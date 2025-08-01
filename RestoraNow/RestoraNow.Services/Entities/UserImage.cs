using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Services.Entities
{
    public class UserImage
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Url { get; set; }

        public string? Description { get; set; }

        [Required]
        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; }
    }
}