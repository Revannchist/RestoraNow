using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests.Order;
using RestoraNow.Model.Responses.Order;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    [Authorize]
    public class OrderController
        : BaseCRUDController<OrderResponse, OrderSearchModel, OrderCreateRequest, OrderUpdateRequest>
    {
        public OrderController(IOrderService service)
            : base(service)
        {
        }
    }
}