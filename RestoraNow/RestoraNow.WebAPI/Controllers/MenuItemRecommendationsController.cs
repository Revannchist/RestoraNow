using System.Collections.Generic;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Responses;
using RestoraNow.Services.Recommendations;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/MenuItem")]
    public class MenuItemRecommendationsController : ControllerBase
    {
        // GET: /api/MenuItem/recommendations?take=10
        [HttpGet("recommendations")]
        public async Task<ActionResult<IEnumerable<MenuItemResponse>>> GetRecommendations(
            [FromServices] IMenuRecommendationService recommender,
            [FromQuery] int take = 10,
            CancellationToken ct = default)
        {
            var claimVal = User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(claimVal, out var userId))
                return Unauthorized();

            var recItems = await recommender.RecommendAsync(userId, take, ct);
            return Ok(recItems);
        }
    }
}
