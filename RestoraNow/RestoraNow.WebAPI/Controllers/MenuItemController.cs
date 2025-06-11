using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MenuItemController : ControllerBase
    {
        private readonly IMenuItemService _service;

        public MenuItemController(IMenuItemService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetAsync([FromQuery] MenuItemSearchModel search, CancellationToken cancellationToken)
        {
            var result = await _service.GetAsync(search, cancellationToken);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            var result = await _service.GetByIdAsync(id, cancellationToken);
            return result == null ? NotFound() : Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> InsertAsync([FromBody] MenuItemRequest request, CancellationToken cancellationToken)
        {
            var result = await _service.InsertAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetByIdAsync), new { id = result.Id }, result);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateAsync(int id, [FromBody] MenuItemRequest request, CancellationToken cancellationToken)
        {
            var result = await _service.UpdateAsync(id, request, cancellationToken);
            return result == null ? NotFound() : Ok(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAsync(int id, CancellationToken cancellationToken)
        {
            var deleted = await _service.DeleteAsync(id, cancellationToken);
            return deleted ? NoContent() : NotFound();
        }
    }
}
