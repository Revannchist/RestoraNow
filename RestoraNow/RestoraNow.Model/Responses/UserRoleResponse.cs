using System;
using System.Collections.Generic;
using System.Text;

namespace RestoraNow.Model.Responses
{
    public class UserRoleResponse
    {
        public int UserId { get; set; }
        public string? Username { get; set; }

        public int RoleId { get; set; }
        public string? RoleName { get; set; }
    }
}
