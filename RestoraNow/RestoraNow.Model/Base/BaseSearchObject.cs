using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Base
{
    public class BaseSearchObject
    {
        public int Page { get; set; } = 1; // Defaults to page 1
        public int PageSize { get; set; } = 10; // Default page size
        public bool IncludeTotalCount { get; set; } = true;
        public bool RetrieveAll { get; set; } = false;
    }

}
