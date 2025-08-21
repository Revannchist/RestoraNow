using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests.Mobile.User;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.Responses.Mobile.User;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;
using System.Security.Claims;
using RestoraNow.Model.Requests.User;

namespace RestoraNow.WebAPI.Controllers
{
    [ApiController]
    [Route("api/user")]
    [Authorize]
    public class UserController : BaseCRUDController<UserResponse, UserSearchModel, UserCreateRequest, UserUpdateRequest>
    {
        private readonly IUserService _userService;
        private readonly IUserImageService _userImageService;

        public UserController(
            IUserService userService,
            IUserImageService userImageService) : base(userService)
        {
            _userService = userService;
            _userImageService = userImageService;
        }

        [HttpGet("me")]
        public async Task<ActionResult<MeResponse>> GetMe()
            => Ok(await _userService.GetMeAsync(GetCurrentUserId()));

        [HttpPut("me")]
        public async Task<ActionResult<MeResponse>> UpdateMe([FromBody] MeUpdateRequest req)
            => Ok(await _userService.UpdateMeAsync(GetCurrentUserId(), req));

        [HttpPatch("me/password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest req)
        {
            await _userService.ChangePasswordAsync(GetCurrentUserId(), req.CurrentPassword, req.NewPassword);
            return NoContent();
        }

        [HttpPatch("me/email")]
        public async Task<IActionResult> ChangeEmail([FromBody] ChangeEmailRequest req)
        {
            await _userService.BeginChangeEmailAsync(GetCurrentUserId(), req.NewEmail, req.CurrentPassword);
            return NoContent();
        }

        [HttpPut("me/image")]
        public async Task<ActionResult<MeResponse>> UpsertMyImage([FromBody] MeImageRequest req)
        {
            var userId = GetCurrentUserId();

            await _userImageService.InsertAsync(new UserImageRequest
            {
                UserId = userId,
                Url = req.Url,
            });

            var me = await _userService.GetMeAsync(userId);
            return Ok(me);
        }

        [HttpDelete("me/image")]
        public async Task<IActionResult> DeleteMyImage()
        {
            var userId = GetCurrentUserId();

            var result = await _userImageService.GetAsync(new UserImageSearchModel
            {
                UserId = userId,
                RetrieveAll = true
            });

            var img = result.Items.FirstOrDefault();
            if (img == null) return NoContent();

            await _userImageService.DeleteAsync(img.Id);
            return NoContent();
        }

        private int GetCurrentUserId()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                throw new UnauthorizedAccessException("User is not authenticated.");
            return int.Parse(userId);
        }
    }
}
