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
    public class OrderItemService
        : BaseCRUDService<OrderItemResponse, OrderItemSearchModel, OrderItem, OrderItemRequest>,
          IOrderItemService
    {
        public OrderItemService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<OrderItem> ApplyFilter(IQueryable<OrderItem> query, OrderItemSearchModel search)
        {
            if (search.OrderId.HasValue)
                query = query.Where(oi => oi.OrderId == search.OrderId);
            if (search.MenuItemId.HasValue)
                query = query.Where(oi => oi.MenuItemId == search.MenuItemId);

            return query;
        }

        protected override IQueryable<OrderItem> AddInclude(IQueryable<OrderItem> query)
        {
            return query.Include(o => o.MenuItem).Include(o => o.Order);
        }
    }
}
