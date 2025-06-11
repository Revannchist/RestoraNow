using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly IOrderService _orderService;

        public OrderController(IOrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] OrderSearchModel search, CancellationToken cancellationToken)
        {
            var result = await _orderService.GetAsync(search, cancellationToken);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken)
        {
            var result = await _orderService.GetByIdAsync(id, cancellationToken);
            return result == null ? NotFound() : Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> Insert([FromBody] OrderRequest request, CancellationToken cancellationToken)
        {
            var result = await _orderService.InsertAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] OrderRequest request, CancellationToken cancellationToken)
        {
            var result = await _orderService.UpdateAsync(id, request, cancellationToken);
            return result == null ? NotFound() : Ok(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
        {
            var success = await _orderService.DeleteAsync(id, cancellationToken);
            return success ? NoContent() : NotFound();
        }
    }
}
