using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Requests
{
    public class UserRoleRequest
    {
        public int UserId { get; set; }
        public int RoleId { get; set; }
    }
}
