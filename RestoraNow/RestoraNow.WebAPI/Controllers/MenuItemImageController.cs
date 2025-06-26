using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    namespace RestoraNow.WebAPI.Controllers
    {
        public class MenuItemImageController
            : BaseCRUDController<MenuItemImageResponse, MenuItemImageSearchModel, MenuItemImageRequest>
        {
            public MenuItemImageController(IMenuItemImageService service)
                : base(service)
            {
            }
        }
    }
}
