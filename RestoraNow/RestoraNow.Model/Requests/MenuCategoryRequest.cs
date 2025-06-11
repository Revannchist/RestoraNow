using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class MenuCategoryRequest
    {
        public string Name { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
