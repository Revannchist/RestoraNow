using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Entities
{
    public class MenuItemImage
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Url { get; set; }

        public string? Description { get; set; }

        [Required]
        public int MenuItemId { get; set; }

        [ForeignKey("MenuItemId")]
        public MenuItem MenuItem { get; set; }
    }
}
