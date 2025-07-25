using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Model.Requests
{
    public class MenuCategoryRequest
    {
        [Required]
        [StringLength(100, MinimumLength = 2)]
        public string Name { get; set; }

        [StringLength(255)]
        public string? Description { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
