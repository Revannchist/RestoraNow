using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class UserRoleController : BaseCRUDController<UserRoleResponse, UserRoleSearchModel, UserRoleRequest>
    {
        public UserRoleController(IUserRoleService service) : base(service)
        {
        }
    }
}
