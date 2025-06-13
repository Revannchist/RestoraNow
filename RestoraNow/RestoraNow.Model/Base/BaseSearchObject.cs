using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Base
{
    public class BaseSearchObject
    {
        public bool IncludeTotalCount { get; set; } = true;
        public bool RetrieveAll { get; set; } = false;
        public int? Page { get; set; }
        public int? PageSize { get; set; }
    }

}
