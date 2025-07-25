using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.Interfaces
{
    public interface IOrderItemService : ICRUDService<OrderItemResponse, OrderItemSearchModel, OrderItemRequest, OrderItemRequest>
    {
    }
}
