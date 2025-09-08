using System.Net;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using EasyNetQ;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;  // << Base64Url helpers
using Microsoft.IdentityModel.Tokens;
using RestoraNow.Model.Messaging;
using RestoraNow.Services.Entities;
// Avoid conflict with Microsoft.AspNetCore.Identity.Data.RegisterRequest
using RegisterRequest = RestoraNow.Model.Requests.User.RegisterRequest;

namespace RestoraNow.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly UserManager<User> _userManager;
        private readonly IConfiguration _configuration;
        private readonly IBus _bus;
        private readonly ILogger<AuthController> _log;

        public AuthController(
            UserManager<User> userManager,
            IConfiguration configuration,
            IBus bus,
            ILogger<AuthController> log)
        {
            _userManager = userManager;
            _configuration = configuration;
            _bus = bus;
            _log = log;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var user = await _userManager.FindByEmailAsync(request.Email);
            if (user == null || !await _userManager.CheckPasswordAsync(user, request.Password))
                return Unauthorized(new { Message = "Invalid email or password." });

            // Require confirmed email if desired
            //if (!user.EmailConfirmed)
            //    return Unauthorized(new { Message = "Please confirm your email before logging in." });

            var roles = await _userManager.GetRolesAsync(user);
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email!),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };
            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"] ?? "RestoraNow",
                audience: _configuration["Jwt:Audience"] ?? "RestoraNow",
                claims: claims,
                expires: DateTime.UtcNow.AddHours(1),
                signingCredentials: creds
            );

            return Ok(new
            {
                Token = new JwtSecurityTokenHandler().WriteToken(token),
                Expires = token.ValidTo
            });
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var existing = await _userManager.FindByEmailAsync(request.Email);
            if (existing != null)
                return Conflict(new { Message = "An account with this email already exists." });

            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                UserName = request.Email,
                PhoneNumber = request.PhoneNumber,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
                return BadRequest(new { Errors = createResult.Errors.Select(e => e.Description) });

            // Generate + Base64Url-encode the email confirmation token
            var rawToken = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            var tokenEncoded = WebEncoders.Base64UrlEncode(Encoding.UTF8.GetBytes(rawToken));

            // Build activation URL (prefer frontend if provided)
            string? frontendBase = _configuration["Frontend:BaseUrl"];  // e.g. https://app.example.com
            string apiBase = _configuration["Backend:PublicBaseUrl"] ?? $"{Request.Scheme}://{Request.Host}";

            string activateUrl = !string.IsNullOrWhiteSpace(frontendBase)
                ? $"{frontendBase.TrimEnd('/')}/activate?uid={user.Id}&token={tokenEncoded}"
                : $"{apiBase.TrimEnd('/')}/api/auth/confirm-email?uid={user.Id}&token={tokenEncoded}";

            // Publish message for the email worker (non-fatal if broker is down)
            var msg = new UserRegisteredMessage
            {
                UserId = user.Id,
                Email = user.Email!,
                UserName = $"{user.FirstName} {user.LastName}".Trim(),
                ActivateUrl = activateUrl
            };

            try
            {
                await _bus.PubSub.PublishAsync(msg, cancellationToken: ct);
                _log.LogInformation("Published UserRegisteredMessage for {Email}", user.Email);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "Rabbit publish failed for {Email}", user.Email);
                // Do not fail registration just because queueing failed
            }

            return Ok(new { Message = "User registered. Please check your email to activate your account." });
        }

        [HttpGet("confirm-email")]
        [AllowAnonymous]
        public async Task<IActionResult> ConfirmEmail([FromQuery] int uid, [FromQuery] string token)
        {
            var user = await _userManager.FindByIdAsync(uid.ToString());
            if (user == null) return NotFound();

            // Decode the Base64Url token back to the original token string
            string normalToken;
            try
            {
                var decodedBytes = WebEncoders.Base64UrlDecode(token);
                normalToken = Encoding.UTF8.GetString(decodedBytes);
            }
            catch
            {
                return BadRequest(new { Message = "Invalid token format." });
            }

            var result = await _userManager.ConfirmEmailAsync(user, normalToken);
            if (!result.Succeeded)
                return BadRequest(new { Errors = result.Errors.Select(e => e.Description) });

            return Ok(new { Message = "Email confirmed. You can now sign in." });
        }
    }

    public sealed class LoginRequest
    {
        public string Email { get; set; } = default!;
        public string Password { get; set; } = default!;
    }
}
