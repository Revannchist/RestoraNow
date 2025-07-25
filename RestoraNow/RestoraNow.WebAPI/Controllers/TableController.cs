using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    public class TableController : BaseCRUDController<TableResponse, TableSearchModel, TableRequest, TableRequest>
    {
        public TableController(ITableService service) : base(service)
        {
        }
    }
}
