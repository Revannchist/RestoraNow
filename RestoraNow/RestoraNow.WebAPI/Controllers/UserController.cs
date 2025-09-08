using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests.User;
using RestoraNow.Model.Requests.Mobile.User;
using RestoraNow.Model.Responses;
using RestoraNow.Model.Responses.Mobile.User;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/user")]
    [Authorize]
    public class UserController
        : BaseCRUDController<UserResponse, UserSearchModel, UserCreateRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;
        private readonly IUserImageService _userImageService; // ADD

        public UserController(
            IUserService userService,
            IUserImageService userImageService) // ADD
            : base(userService)
        {
            _userService = userService;
            _userImageService = userImageService; // ADD
        }

        // ===== Helpers =====
        private int GetUserId()
        {
            var id = User.FindFirstValue(ClaimTypes.NameIdentifier)
                     ?? User.FindFirstValue("sub");
            if (!int.TryParse(id, out var uid))
                throw new UnauthorizedAccessException("Invalid user id.");
            return uid;
        }

        // ===== /api/user/me =====

        [HttpGet("me")]
        [ProducesResponseType(typeof(MeResponse), StatusCodes.Status200OK)]
        public async Task<ActionResult<MeResponse>> GetMe()
        {
            var me = await _userService.GetMeAsync(GetUserId());
            return Ok(me);
        }

        [HttpPut("me")]
        [ProducesResponseType(typeof(MeResponse), StatusCodes.Status200OK)]
        public async Task<ActionResult<MeResponse>> UpdateMe([FromBody] MeUpdateRequest request)
        {
            var me = await _userService.UpdateMeAsync(GetUserId(), request);
            return Ok(me);
        }

        [HttpPut("me/change-password")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest body)
        {
            await _userService.ChangePasswordAsync(GetUserId(), body.CurrentPassword, body.NewPassword);
            return NoContent();
        }

        [HttpPost("me/begin-change-email")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> BeginChangeEmail([FromBody] BeginChangeEmailRequest body)
        {
            await _userService.BeginChangeEmailAsync(GetUserId(), body.NewEmail, body.CurrentPassword);
            return NoContent();
        }

        // Compatibility shims
        [HttpPatch("me/password")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> PatchPassword([FromBody] ChangePasswordRequest body)
        {
            await _userService.ChangePasswordAsync(GetUserId(), body.CurrentPassword, body.NewPassword);
            return NoContent();
        }

        [HttpPatch("me/email")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> PatchEmail([FromBody] BeginChangeEmailRequest body)
        {
            await _userService.BeginChangeEmailAsync(GetUserId(), body.NewEmail, body.CurrentPassword);
            return NoContent();
        }

        // ===== NEW: image endpoints used by your mobile app =====

        /// <summary>Upsert current user's image by URL or data URI.</summary>
        /// PUT /api/user/me/image
        [HttpPut("me/image")]
        [ProducesResponseType(typeof(MeResponse), StatusCodes.Status200OK)]
        public async Task<ActionResult<MeResponse>> UpsertMyImage([FromBody] MeImageRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Url)) return BadRequest("Url is required.");
            var userId = GetUserId();

            await _userImageService.UpsertByUserIdAsync(userId, req.Url);

            // Return fresh Me with Image included
            var me = await _userService.GetMeAsync(userId);
            return Ok(me);
        }

        /// <summary>Delete current user's image.</summary>
        /// DELETE /api/user/me/image
        [HttpDelete("me/image")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        public async Task<IActionResult> DeleteMyImage()
        {
            var userId = GetUserId();
            await _userImageService.DeleteByUserIdAsync(userId);
            return NoContent();
        }

        // Local request DTOs
        public record ChangePasswordRequest(string CurrentPassword, string NewPassword);
        public record BeginChangeEmailRequest(string NewEmail, string? CurrentPassword);
    }
}
