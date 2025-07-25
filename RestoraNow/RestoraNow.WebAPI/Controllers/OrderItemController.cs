using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
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
