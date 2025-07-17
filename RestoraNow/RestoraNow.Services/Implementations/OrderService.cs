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
    public class OrderService
        : BaseCRUDService<OrderResponse, OrderSearchModel, Order, OrderRequest>,
          IOrderService
    {
        public OrderService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Order> ApplyFilter(IQueryable<Order> query, OrderSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(o => o.UserId == search.UserId);

            if (search.Status.HasValue)
                query = query.Where(o => o.Status == search.Status);

            if (search.FromDate.HasValue)
                query = query.Where(o => o.CreatedAt >= search.FromDate);

            if (search.ToDate.HasValue)
                query = query.Where(o => o.CreatedAt <= search.ToDate);

            return query;
        }

        protected override IQueryable<Order> AddInclude(IQueryable<Order> query)
        {
            return query.Include(o => o.OrderItems)
                        .Include(o => o.User)
                        .Include(o => o.Reservation)
                        .Include(o => o.Payment);
        }
    }
}
