using System.ComponentModel.DataAnnotations;

namespace RestoraNow.Services.Entities
{
    public class MenuCategory
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; }

        [MaxLength(500)]
        public string Description { get; set; }
        public bool IsActive { get; set; } = true;

        public ICollection<MenuItem> MenuItems { get; set; }
    }
}