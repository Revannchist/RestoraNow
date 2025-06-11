using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class MenuCategoryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }
}
