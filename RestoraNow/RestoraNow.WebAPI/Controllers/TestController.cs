using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RestoraNow.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TestController : ControllerBase
    {
        [HttpGet("public")]
        public IActionResult Public()
        {
            return Ok("Public access granted.");
        }

        [HttpGet("admin-only")]
        [Authorize(Roles = "Admin")]
        public IActionResult AdminOnly()
        {
            return Ok("Admin access granted.");
        }

        [HttpGet("manager-only")]
        [Authorize(Roles = "Manager")]
        public IActionResult ManagerOnly()
        {
            return Ok("Manager access granted.");
        }

        [HttpGet("staff-only")]
        [Authorize(Roles = "Staff")]
        public IActionResult StaffOnly()
        {
            return Ok("Staff access granted.");
        }

        [HttpGet("customer-only")]
        [Authorize(Roles = "Customer")]
        public IActionResult CustomerOnly()
        {
            return Ok("Customer access granted.");
        }
    }
}
