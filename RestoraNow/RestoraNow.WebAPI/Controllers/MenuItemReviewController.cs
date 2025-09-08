using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    [Authorize]
    public class MenuItemReviewController
        : BaseCRUDController<MenuItemReviewResponse, MenuItemReviewSearchModel, MenuItemReviewRequest, MenuItemReviewRequest>
    {
        public MenuItemReviewController(IMenuItemReviewService service)
            : base(service)
        {
        }
    }
}
