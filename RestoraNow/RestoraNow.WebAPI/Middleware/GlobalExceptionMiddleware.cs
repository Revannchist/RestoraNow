using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace RestoraNow.WebAPI.Middleware
{
    public class GlobalExceptionMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionMiddleware> _logger;

        public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (ValidationException ex)
            {
                // Let [ApiController] handle it as 400 Bad Request
                throw;
            }

            catch (KeyNotFoundException ex)
            {
                _logger.LogWarning(ex, "Not Found");
                await WriteErrorResponse(context, 404, ex.Message);
            }
            catch (ArgumentException ex)
            {
                _logger.LogWarning(ex, "Bad input argument");
                await WriteErrorResponse(context, 400, ex.Message);
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogWarning(ex, "Bad Request");
                await WriteErrorResponse(context, 400, ex.Message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Internal Server Error");
                await WriteErrorResponse(context, 500, "An unexpected error occurred.");
            }
        }

        private async Task WriteErrorResponse(HttpContext context, int statusCode, string message)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = statusCode;
            await context.Response.WriteAsync(JsonSerializer.Serialize(new { message }));
        }
    }

}
