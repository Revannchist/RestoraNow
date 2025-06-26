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
        : BaseCRUDService<PaymentResponse, PaymentSearchModel, Payment, PaymentRequest>,
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
    }
}
