using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Base;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.WebAPI.Controllers.Base
{
    [ApiController]
    [Route("api/[controller]")]
    public class BaseController<TModel, TSearch> : ControllerBase
        where TSearch : BaseSearchObject, new()
    {
        protected readonly IService<TModel, TSearch> _service;

        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<TModel>>> Get([FromQuery] TSearch? search)
        {
            return Ok(await _service.GetAsync(search ?? new TSearch()));
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<TModel>> GetById(int id)
        {
            var result = await _service.GetByIdAsync(id);
            if (result == null)
                return NotFound();
            return Ok(result);
        }
    }
}