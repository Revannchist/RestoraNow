using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrderItemController : ControllerBase
    {
        private readonly IOrderItemService _service;

        public OrderItemController(IOrderItemService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IEnumerable<OrderItemResponse>> GetAsync([FromQuery] OrderItemSearchModel search, CancellationToken cancellationToken)
        {
            return await _service.GetAsync(search, cancellationToken);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<OrderItemResponse>> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            var item = await _service.GetByIdAsync(id, cancellationToken);
            if (item == null)
                return NotFound();
            return Ok(item);
        }

        [HttpPost]
        public async Task<ActionResult<OrderItemResponse>> InsertAsync(OrderItemRequest request, CancellationToken cancellationToken)
        {
            var created = await _service.InsertAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetByIdAsync), new { id = created.Id }, created);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<OrderItemResponse>> UpdateAsync(int id, OrderItemRequest request, CancellationToken cancellationToken)
        {
            var updated = await _service.UpdateAsync(id, request, cancellationToken);
            if (updated == null)
                return NotFound();
            return Ok(updated);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAsync(int id, CancellationToken cancellationToken)
        {
            var deleted = await _service.DeleteAsync(id, cancellationToken);
            return deleted ? NoContent() : NotFound();
        }
    }
}
