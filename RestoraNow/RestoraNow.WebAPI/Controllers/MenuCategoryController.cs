using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MenuCategoryController : ControllerBase
    {
        private readonly IMenuCategoryService _service;

        public MenuCategoryController(IMenuCategoryService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetAsync([FromQuery] MenuCategorySearchModel search, CancellationToken cancellationToken)
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
        public async Task<IActionResult> InsertAsync([FromBody] MenuCategoryRequest request, CancellationToken cancellationToken)
        {
            var result = await _service.InsertAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetByIdAsync), new { id = result.Id }, result);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateAsync(int id, [FromBody] MenuCategoryRequest request, CancellationToken cancellationToken)
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
