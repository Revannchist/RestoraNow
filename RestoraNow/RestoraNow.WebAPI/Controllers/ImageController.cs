using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ImageController : ControllerBase
    {
        private readonly IImageService _imageService;

        public ImageController(IImageService imageService)
        {
            _imageService = imageService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ImageResponse>>> Get([FromQuery] ImageSearchModel search, CancellationToken cancellationToken)
        {
            var images = await _imageService.GetAsync(search, cancellationToken);
            return Ok(images);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ImageResponse>> GetById(int id, CancellationToken cancellationToken)
        {
            var image = await _imageService.GetByIdAsync(id, cancellationToken);
            if (image == null)
                return NotFound();

            return Ok(image);
        }

        [HttpPost]
        public async Task<ActionResult<ImageResponse>> Post([FromBody] ImageRequest request, CancellationToken cancellationToken)
        {
            var created = await _imageService.InsertAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<ImageResponse>> Put(int id, [FromBody] ImageRequest request, CancellationToken cancellationToken)
        {
            var updated = await _imageService.UpdateAsync(id, request, cancellationToken);
            if (updated == null)
                return NotFound();

            return Ok(updated);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
        {
            var deleted = await _imageService.DeleteAsync(id, cancellationToken);
            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}
