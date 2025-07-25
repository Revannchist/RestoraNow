using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class FavoriteController
        : BaseCRUDController<FavoriteResponse, FavoriteSearchModel, FavoriteRequest, FavoriteRequest>
    {
        public FavoriteController(IFavoriteService service)
            : base(service) { }
    }
}
