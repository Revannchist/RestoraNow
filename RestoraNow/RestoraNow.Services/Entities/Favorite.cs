using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Entities
{
    public class Favorite
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; }

        public int MenuItemId { get; set; }
        public MenuItem MenuItem { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

}
