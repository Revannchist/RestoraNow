using RestoraNow.Model.Base;
using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.SearchModels
{
    public class UserRoleSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? RoleId { get; set; }
    }
}
