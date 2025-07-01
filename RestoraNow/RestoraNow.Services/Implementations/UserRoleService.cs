using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Implementations
{
    public class UserRoleService : BaseCRUDService<UserRoleResponse, UserRoleSearchModel, UserRole, UserRoleRequest>, IUserRoleService
    {
        public UserRoleService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<UserRole> ApplyFilter(IQueryable<UserRole> query, UserRoleSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(x => x.UserId == search.UserId.Value);

            if (search.RoleId.HasValue)
                query = query.Where(x => x.RoleId == search.RoleId.Value);

            return query;
        }

        protected override IQueryable<UserRole> AddInclude(IQueryable<UserRole> query)
        {
            return query.Include(x => x.User)
                        .Include(x => x.Role);
        }
    }
}
