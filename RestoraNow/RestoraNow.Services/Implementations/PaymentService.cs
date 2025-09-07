using System;
using System.Linq;
using System.Threading.Tasks;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Enums;
using RestoraNow.Model.Requests.Payments;
using RestoraNow.Model.Responses.Payments;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using RestoraNow.Services.Payments;

namespace RestoraNow.Services.Implementations
{
    public class PaymentService
        : BaseCRUDService<PaymentResponse, PaymentSearchModel, Payment, PaymentRequest, PaymentRequest>,
          IPaymentService
    {
        private readonly PayPalGateway _paypal;

        public PaymentService(
            ApplicationDbContext context,
            IMapper mapper,
            PayPalGateway paypal)
            : base(context, mapper)
        {
            _paypal = paypal;
        }

        protected override IQueryable<Payment> ApplyFilter(IQueryable<Payment> query, PaymentSearchModel search)
        {
            if (search.OrderId.HasValue)
                query = query.Where(p => p.OrderId == search.OrderId.Value);

            if (search.Status.HasValue)
                query = query.Where(p => p.Status == search.Status.Value);

            if (search.FromDate.HasValue)
                query = query.Where(p => p.PaidAt >= search.FromDate.Value);

            if (search.ToDate.HasValue)
                query = query.Where(p => p.PaidAt <= search.ToDate.Value);

            return query;
        }

        protected override IQueryable<Payment> AddInclude(IQueryable<Payment> query)
            => query.Include(p => p.Order);

        public override async Task<PaymentResponse> InsertAsync(PaymentRequest request)
        {
            var orderExists = await _context.Orders.AnyAsync(o => o.Id == request.OrderId);
            if (!orderExists)
                throw new KeyNotFoundException($"Order with ID {request.OrderId} not found.");

            return await base.InsertAsync(request);
        }

        public override async Task<PaymentResponse?> UpdateAsync(int id, PaymentRequest request)
        {
            var payment = await _context.Payments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Payment with ID {id} was not found.");

            var orderExists = await _context.Orders.AnyAsync(o => o.Id == request.OrderId);
            if (!orderExists)
                throw new KeyNotFoundException($"Order with ID {request.OrderId} not found.");

            _mapper.Map(request, payment);
            await _context.SaveChangesAsync();

            return _mapper.Map<PaymentResponse>(payment);
        }

        public override async Task<PaymentResponse?> GetByIdAsync(int id)
        {
            var payment = await _context.Payments
                .Include(p => p.Order)
                .FirstOrDefaultAsync(p => p.Id == id)
                ?? throw new KeyNotFoundException($"Payment with ID {id} was not found.");

            return _mapper.Map<PaymentResponse>(payment);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var payment = await _context.Payments.FindAsync(id)
                ?? throw new KeyNotFoundException($"Payment with ID {id} was not found.");

            _context.Payments.Remove(payment);
            await _context.SaveChangesAsync();
            return true;
        }

        // -------- PayPal flow --------

        public async Task<(string ApproveUrl, string ProviderOrderId)> CreatePaypalOrderAsync(
            int orderId, string? currency = null)
        {
            // Ensure order exists
            _ = await _context.Orders.SingleOrDefaultAsync(o => o.Id == orderId)
                ?? throw new KeyNotFoundException($"Order {orderId} not found.");

            // Compute amount from items
            var amount = await _context.OrderItems
                .Where(oi => oi.OrderId == orderId)
                .SumAsync(oi => oi.UnitPrice * oi.Quantity);

            if (amount <= 0)
                throw new InvalidOperationException($"Order {orderId} has zero/negative total.");

            // Decide currency: param -> .env (PayPal__Currency) -> USD
            var usedCurrency = string.IsNullOrWhiteSpace(currency)
                ? (Environment.GetEnvironmentVariable("PayPal__Currency") ?? "USD").Trim().ToUpperInvariant()
                : currency.Trim().ToUpperInvariant();

            (string providerOrderId, string approveUrl) = await _paypal.CreateOrderAsync(
                amount,
                usedCurrency,
                returnUrl: null,          // gateway uses PayPal__ReturnUrl
                cancelUrl: null,          // gateway uses PayPal__CancelUrl
                description: $"RestoraNow Order #{orderId}",
                referenceId: orderId.ToString()
            );

            _context.Payments.Add(new Payment
            {
                OrderId = orderId,
                Amount = amount,
                Method = PaymentMethod.PayPal,
                Status = PaymentStatus.Pending,
                PaidAt = null, // pending → not paid yet
                Currency = usedCurrency,
                Provider = "PayPal",
                ProviderOrderId = providerOrderId
            });

            await _context.SaveChangesAsync();
            return (approveUrl, providerOrderId);
        }

        public async Task<PaymentResponse> CapturePaypalOrderAsync(string providerOrderId)
        {
            // PayPal sends back the "token" on return URL; that's the provider order id
            var payment = await _context.Payments
                .SingleOrDefaultAsync(p => p.Provider == "PayPal" && p.ProviderOrderId == providerOrderId)
                ?? throw new KeyNotFoundException($"Payment with ProviderOrderId '{providerOrderId}' not found.");

            // Idempotency: return early if already captured
            if (!string.IsNullOrEmpty(payment.ProviderCaptureId) && payment.Status == PaymentStatus.Completed)
                return _mapper.Map<PaymentResponse>(payment);

            // Pre-check: ensure the order is actually approved (gives clearer errors)
            var status = await _paypal.GetOrderStatusAsync(providerOrderId);
            if (!string.Equals(status, "APPROVED", StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException($"Order {providerOrderId} not APPROVED (current status: {status}).");

            (string capStatus, string captureId, decimal capturedAmount, string? debugId) =
                await _paypal.CaptureOrderAsync(providerOrderId);

            // Optional: reconcile amount with PayPal
            if (payment.Amount == 0 || payment.Amount != capturedAmount)
                payment.Amount = capturedAmount;

            payment.ProviderCaptureId = captureId;
            payment.PaidAt = capStatus.Equals("COMPLETED", StringComparison.OrdinalIgnoreCase)
                ? DateTime.UtcNow
                : null;
            payment.Status = capStatus.Equals("COMPLETED", StringComparison.OrdinalIgnoreCase)
                ? PaymentStatus.Completed
                : PaymentStatus.Failed;

            await _context.SaveChangesAsync();
            return _mapper.Map<PaymentResponse>(payment);
        }
    }
}
