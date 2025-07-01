using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class UserController : BaseCRUDController<UserResponse, UserSearchModel, UserRequest>
    {
        public UserController(IUserService service) : base(service)
        {
        }
    }
}
