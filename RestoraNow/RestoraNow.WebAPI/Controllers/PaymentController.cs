using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Requests.Payments;
using RestoraNow.Model.Responses.Payments;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;

    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PaymentController
        : BaseCRUDController<PaymentResponse, PaymentSearchModel, PaymentRequest, PaymentRequest>
    {
        private readonly IPaymentService _payments;
        private readonly ILogger<PaymentController> _logger;

        public PaymentController(IPaymentService service, ILogger<PaymentController> logger) : base(service)
        {
            _payments = service;
            _logger = logger;
        }

        // 1) Create PayPal order and return approval URL
        [HttpPost("paypal/create/{orderId:int}")]
        public async Task<IActionResult> CreatePaypalOrder(int orderId, [FromQuery] string? currency = null)
        {
            try
            {
                var (approveUrl, providerOrderId) = await _payments.CreatePaypalOrderAsync(orderId, currency);
                return Ok(new { approveUrl, providerOrderId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Create PayPal order failed for OrderId={OrderId}", orderId);
                return StatusCode(500, new { message = "create_paypal_order_failed", error = ex.Message });
            }
        }

        // 2) Capture PayPal order (token == providerOrderId)
        [HttpPost("paypal/capture")]
        public async Task<ActionResult<PaymentResponse>> CapturePaypalOrder([FromQuery] string token)
        {
            try
            {
                var resp = await _payments.CapturePaypalOrderAsync(token);
                return Ok(resp);
            }
            catch (ArgumentException ex) // bad input, order not found, etc.
            {
                _logger.LogWarning(ex, "Bad capture request token={Token}", token);
                return BadRequest(new { message = "invalid_capture_request", error = ex.Message });
            }
            catch (HttpRequestException ex) // bubble up PayPal errors as 4xx/5xx detail
            {
                _logger.LogError(ex, "PayPal HTTP error during capture token={Token}", token);
                return StatusCode(502, new { message = "paypal_capture_http_error", error = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled error during capture token={Token}", token);
                return StatusCode(500, new { message = "exception_during_capture", error = ex.Message });
            }
        }
    }
