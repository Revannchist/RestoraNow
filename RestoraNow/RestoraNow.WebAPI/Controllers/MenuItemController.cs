using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class MenuItemController
        : BaseCRUDController<MenuItemResponse, MenuItemSearchModel, MenuItemRequest, MenuItemRequest>
    {
        public MenuItemController(IMenuItemService service)
            : base(service)
        {
        }
    }
}
