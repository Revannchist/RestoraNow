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
        : BaseCRUDService<OrderResponse, OrderSearchModel, Order, OrderRequest, OrderRequest>,
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

        public override async Task<OrderResponse> InsertAsync(OrderRequest request)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            if (request.ReservationId.HasValue)
            {
                var reservationExists = await _context.Reservations.AnyAsync(r => r.Id == request.ReservationId);
                if (!reservationExists)
                    throw new KeyNotFoundException($"Reservation with ID {request.ReservationId} not found.");
            }

            if (request.MenuItemIds == null || !request.MenuItemIds.Any())
                throw new InvalidOperationException("At least one menu item must be selected.");

            foreach (var itemId in request.MenuItemIds)
            {
                var exists = await _context.MenuItem.AnyAsync(m => m.Id == itemId);
                if (!exists)
                    throw new KeyNotFoundException($"Menu item with ID {itemId} not found.");
            }

            return await base.InsertAsync(request);
        }

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderRequest request)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                throw new KeyNotFoundException($"Order with ID {id} not found.");

            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            if (request.ReservationId.HasValue)
            {
                var reservationExists = await _context.Reservations.AnyAsync(r => r.Id == request.ReservationId);
                if (!reservationExists)
                    throw new KeyNotFoundException($"Reservation with ID {request.ReservationId} not found.");
            }

            foreach (var itemId in request.MenuItemIds)
            {
                var exists = await _context.MenuItem.AnyAsync(m => m.Id == itemId);
                if (!exists)
                    throw new KeyNotFoundException($"Menu item with ID {itemId} not found.");
            }

            _mapper.Map(request, order);
            await _context.SaveChangesAsync();

            return _mapper.Map<OrderResponse>(order);
        }

        public override async Task<OrderResponse?> GetByIdAsync(int id)
        {
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .Include(o => o.User)
                .Include(o => o.Reservation)
                .Include(o => o.Payment)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
                throw new KeyNotFoundException($"Order with ID {id} was not found.");

            return _mapper.Map<OrderResponse>(order);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null)
                throw new KeyNotFoundException($"Order with ID {id} was not found.");

            _context.Orders.Remove(order);
            await _context.SaveChangesAsync();
            return true;
        }

    }
}
