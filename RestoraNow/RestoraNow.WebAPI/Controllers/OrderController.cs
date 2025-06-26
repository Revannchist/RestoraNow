using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class OrderController
        : BaseCRUDController<OrderResponse, OrderSearchModel, OrderRequest>
    {
        public OrderController(IOrderService service)
            : base(service)
        {
        }
    }
}
