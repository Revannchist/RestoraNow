using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.Interfaces
{
    public interface IMenuItemService
        : ICRUDService<MenuItemResponse, MenuItemSearchModel, MenuItemRequest>
    {
    }
}
