using RestoraNow.Model.Requests.Order;
using RestoraNow.Model.Responses.Order;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.Interfaces
{
    public interface IOrderItemService : ICRUDService<OrderItemResponse, OrderItemSearchModel, OrderItemRequest, OrderItemRequest>
    {
    }
}
