using Microsoft.AspNetCore.Authorization;
using RestoraNow.Model.Requests.Restaurant;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    [Authorize]
    public class RestaurantController
        : BaseCRUDController<RestaurantResponse, RestaurantSearchModel, RestaurantRequest, RestaurantUpdateRequest>
    {
        public RestaurantController(IRestaurantService service)
            : base(service)
        {
        }
    }
}