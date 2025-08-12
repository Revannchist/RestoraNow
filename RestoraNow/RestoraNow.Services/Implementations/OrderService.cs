using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Enums;
using RestoraNow.Model.Requests.Order;
using RestoraNow.Model.Responses.Order;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.Services.Implementations
{
    public class OrderService
        : BaseCRUDService<OrderResponse, OrderSearchModel, Order, OrderCreateRequest, OrderUpdateRequest>,
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
            return query
                .Include(o => o.OrderItems).ThenInclude(oi => oi.MenuItem)
                .Include(o => o.User)
                .Include(o => o.Reservation)
                .Include(o => o.Payment);
        }

        public override async Task<OrderResponse> InsertAsync(OrderCreateRequest request)
        {
            await ValidateUserAndReservationAsync(request.UserId, request.ReservationId);

            if (request.MenuItemIds == null || !request.MenuItemIds.Any())
                throw new InvalidOperationException("At least one menu item must be selected.");

            // quantity per menuItemId (duplicates => qty)
            var qtyById = request.MenuItemIds
                .GroupBy(id => id)
                .ToDictionary(g => g.Key, g => g.Count());

            var ids = qtyById.Keys.ToList();
            var menuRows = await _context.MenuItem
                .Where(m => ids.Contains(m.Id))
                .Select(m => new { m.Id, m.Price })
                .ToListAsync();

            if (menuRows.Count != ids.Count)
            {
                var found = menuRows.Select(x => x.Id).ToHashSet();
                var missing = ids.Where(i => !found.Contains(i));
                throw new KeyNotFoundException($"Menu items not found: {string.Join(", ", missing)}");
            }

            var order = new Order
            {
                UserId = request.UserId,
                ReservationId = request.ReservationId,
                CreatedAt = DateTime.UtcNow,
                // Status stays default (Pending)
                OrderItems = new List<OrderItem>()
            };

            foreach (var row in menuRows)
            {
                order.OrderItems.Add(new OrderItem
                {
                    MenuItemId = row.Id,
                    Quantity = qtyById[row.Id],
                    UnitPrice = row.Price
                });
            }

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            var saved = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.MenuItem)
                .Include(o => o.User)
                .Include(o => o.Reservation)
                .Include(o => o.Payment)
                .AsNoTracking()
                .FirstAsync(o => o.Id == order.Id);

            return _mapper.Map<OrderResponse>(saved);
        }

        public override async Task<OrderResponse?> UpdateAsync(int id, OrderUpdateRequest request)
        {
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null)
                throw new KeyNotFoundException($"Order with ID {id} not found.");

            await ValidateUserAndReservationAsync(request.UserId, request.ReservationId);

            if (request.MenuItemIds == null || !request.MenuItemIds.Any())
                throw new InvalidOperationException("At least one menu item must be selected.");

            order.UserId = request.UserId;
            order.ReservationId = request.ReservationId;
            order.Status = request.Status; // <-- apply status from update DTO

            var qtyById = request.MenuItemIds
                .GroupBy(i => i)
                .ToDictionary(g => g.Key, g => g.Count());

            var ids = qtyById.Keys.ToList();
            var menuRows = await _context.MenuItem
                .Where(m => ids.Contains(m.Id))
                .Select(m => new { m.Id, m.Price })
                .ToListAsync();

            if (menuRows.Count != ids.Count)
            {
                var found = menuRows.Select(x => x.Id).ToHashSet();
                var missing = ids.Where(i => !found.Contains(i));
                throw new KeyNotFoundException($"Menu items not found: {string.Join(", ", missing)}");
            }

            // Replace items
            _context.OrderItems.RemoveRange(order.OrderItems);
            order.OrderItems.Clear();

            foreach (var row in menuRows)
            {
                order.OrderItems.Add(new OrderItem
                {
                    OrderId = order.Id,
                    MenuItemId = row.Id,
                    Quantity = qtyById[row.Id],
                    UnitPrice = row.Price
                });
            }

            await _context.SaveChangesAsync();

            var saved = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.MenuItem)
                .Include(o => o.User)
                .Include(o => o.Reservation)
                .Include(o => o.Payment)
                .AsNoTracking()
                .FirstAsync(o => o.Id == order.Id);

            return _mapper.Map<OrderResponse>(saved);
        }

        public override async Task<OrderResponse?> GetByIdAsync(int id)
        {
            var order = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.MenuItem)
                .Include(o => o.User)
                .Include(o => o.Reservation)
                .Include(o => o.Payment)
                .AsNoTracking()
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

        // ---------- Helpers ----------
        private async Task ValidateUserAndReservationAsync(int userId, int? reservationId)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {userId} not found.");

            if (reservationId.HasValue)
            {
                var reservationExists = await _context.Reservations
                    .AnyAsync(r => r.Id == reservationId.Value);
                if (!reservationExists)
                    throw new KeyNotFoundException($"Reservation with ID {reservationId} not found.");
            }
        }
    }
}