using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class UserImageController : BaseCRUDController<UserImageResponse, UserImageSearchModel, UserImageRequest>
    {
        public UserImageController(IUserImageService service) : base(service)
        {
        }
    }
}
