using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FavoriteController : ControllerBase
    {
        private readonly IFavoriteService _favoriteService;

        public FavoriteController(IFavoriteService favoriteService)
        {
            _favoriteService = favoriteService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<FavoriteResponse>>> Get([FromQuery] FavoriteSearchModel search, CancellationToken cancellationToken)
        {
            var favorites = await _favoriteService.GetAsync(search, cancellationToken);
            return Ok(favorites);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<FavoriteResponse>> GetById(int id, CancellationToken cancellationToken)
        {
            var favorite = await _favoriteService.GetByIdAsync(id, cancellationToken);
            if (favorite == null)
                return NotFound();

            return Ok(favorite);
        }

        [HttpPost]
        public async Task<ActionResult<FavoriteResponse>> Post([FromBody] FavoriteRequest request, CancellationToken cancellationToken)
        {
            var created = await _favoriteService.InsertAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<FavoriteResponse>> Put(int id, [FromBody] FavoriteRequest request, CancellationToken cancellationToken)
        {
            var updated = await _favoriteService.UpdateAsync(id, request, cancellationToken);
            if (updated == null)
                return NotFound();

            return Ok(updated);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
        {
            var deleted = await _favoriteService.DeleteAsync(id, cancellationToken);
            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}
