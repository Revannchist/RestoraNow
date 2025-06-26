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

        //public override async Task<OrderResponse> InsertAsync(OrderRequest request)
        //{
        //    // Step 1: Create base Order
        //    var order = new Order
        //    {
        //        UserId = request.UserId,
        //        ReservationId = request.ReservationId,
        //        CreatedAt = DateTime.UtcNow,
        //        Status = Model.Enums.OrderStatus.Pending,
        //        OrderItems = new List<OrderItem>()
        //    };

        //    // Step 2: Get menu items from DB
        //    var menuItems = await _context.MenuItem
        //        .Where(mi => request.MenuItemIds.Contains(mi.Id))
        //        .ToListAsync();

        //    // Step 3: Build OrderItems
        //    foreach (var menuItem in menuItems)
        //    {
        //        order.OrderItems.Add(new OrderItem
        //        {
        //            MenuItemId = menuItem.Id,
        //            Quantity = 1, // default 1 — can be extended in future
        //            UnitPrice = menuItem.Price
        //        });
        //    }

        //    // Step 4: Save Order + OrderItems
        //    _context.Orders.Add(order);
        //    await _context.SaveChangesAsync();

        //    // Step 5: Map to response
        //    return _mapper.Map<OrderResponse>(order);
        //}

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
