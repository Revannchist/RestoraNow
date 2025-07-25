using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.Services.Implementations
{
    public class PaymentService
        : BaseCRUDService<PaymentResponse, PaymentSearchModel, Payment, PaymentRequest, PaymentRequest>,
          IPaymentService
    {
        public PaymentService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
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
        {
            return query.Include(p => p.Order);
        }

        public override async Task<PaymentResponse> InsertAsync(PaymentRequest request)
        {
            var orderExists = await _context.Orders.AnyAsync(o => o.Id == request.OrderId);
            if (!orderExists)
                throw new KeyNotFoundException($"Order with ID {request.OrderId} not found.");

            return await base.InsertAsync(request);
        }

        public override async Task<PaymentResponse?> UpdateAsync(int id, PaymentRequest request)
        {
            var payment = await _context.Payments.FindAsync(id);
            if (payment == null)
                throw new KeyNotFoundException($"Payment with ID {id} was not found.");

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
                .FirstOrDefaultAsync(p => p.Id == id);

            if (payment == null)
                throw new KeyNotFoundException($"Payment with ID {id} was not found.");

            return _mapper.Map<PaymentResponse>(payment);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var payment = await _context.Payments.FindAsync(id);
            if (payment == null)
                throw new KeyNotFoundException($"Payment with ID {id} was not found.");

            _context.Payments.Remove(payment);
            await _context.SaveChangesAsync();
            return true;
        }

    }
}
