namespace RestoraNow.WebAPI.Controllers
{
    using Microsoft.AspNetCore.Mvc;
    using RestoraNow.Model.Requests;
    using RestoraNow.Model.Responses;
    using RestoraNow.Model.SearchModels;
    using RestoraNow.Services.Interfaces;
    using RestoraNow.WebAPI.Controllers.Base;

    [ApiController]
    [Route("api/[controller]")]
    public class AddressController : BaseCRUDController<AddressResponse, AddressSearchModel, AddressRequest>
    {
        public AddressController(IAddressService addressService) : base(addressService)
        {
        }
    }
}