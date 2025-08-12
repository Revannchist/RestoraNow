using RestoraNow.Model.Requests.Order;
using RestoraNow.Model.Responses.Order;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class OrderItemController
        : BaseCRUDController<OrderItemResponse, OrderItemSearchModel, OrderItemRequest, OrderItemRequest>
    {
        public OrderItemController(IOrderItemService service)
            : base(service)
        {
        }
    }
}
