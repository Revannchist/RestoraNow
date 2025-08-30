using System.Security.Claims;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
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
        private readonly IHttpContextAccessor _http;

        public OrderService(ApplicationDbContext context, IMapper mapper, IHttpContextAccessor http)
            : base(context, mapper)
        {
            _http = http;
        }

        // ---------- Queries ----------

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

        protected override IQueryable<Order> AddInclude(IQueryable<Order> query) => WithOrderGraph(query);

        private IQueryable<Order> WithOrderGraph(IQueryable<Order> q) =>
            q.Include(o => o.OrderItems).ThenInclude(oi => oi.MenuItem)
             .Include(o => o.User)
             .Include(o => o.Reservation)
             .Include(o => o.Payment);

        // ---------- CRUD ----------

        public override async Task<OrderResponse> InsertAsync(OrderCreateRequest request)
        {
            await ValidateUserAndReservationAsync(request.UserId, request.ReservationId);

            if (request.MenuItemIds == null || !request.MenuItemIds.Any())
                throw new InvalidOperationException("At least one menu item must be selected.");

            var qtyById = BuildQtyMap(request.MenuItemIds);

            var menuRows = await LoadPricedAndAvailableMenuItemsAsync(qtyById.Keys);
            EnsureAllRequestedItemsExist(qtyById.Keys, menuRows.Select(m => m.Id));

            var order = new Order
            {
                UserId = request.UserId,
                ReservationId = request.ReservationId,
                CreatedAt = DateTime.UtcNow,
                Status = OrderStatus.Pending,
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

            var saved = await WithOrderGraph(_context.Orders.AsNoTracking())
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

            // Status transition policy (still enforced)
            if (!IsValidTransition(order.Status, request.Status))
                throw new InvalidOperationException($"Invalid status transition {order.Status} → {request.Status}.");

            // Determine if items are actually changing
            var hasList = request.MenuItemIds != null;
            var itemsChanging = hasList && !MenuMatches(order.OrderItems, request.MenuItemIds!);

            // ---- ITEM EDIT RULES ----
            // Only enforce "Pending only" when items are changing.
            if (itemsChanging)
            {
                if (request.MenuItemIds!.Count == 0)
                    throw new InvalidOperationException("At least one menu item must be selected for update.");

                var isAdmin = _http.HttpContext?.User?.IsInRole("Admin") == true;

                var canEditItems =
                    order.Status == OrderStatus.Pending ||
                    (order.Status == OrderStatus.Preparing && isAdmin); // admin override for Preparing

                if (!canEditItems)
                    throw new InvalidOperationException("Only pending orders can be edited.");
            }

            // Apply scalar fields
            order.UserId = request.UserId;
            order.ReservationId = request.ReservationId;
            order.Status = request.Status;

            // Replace items ONLY if they actually changed
            if (itemsChanging)
            {
                var qtyById = BuildQtyMap(request.MenuItemIds!);
                var menuRows = await LoadPricedAndAvailableMenuItemsAsync(qtyById.Keys);
                EnsureAllRequestedItemsExist(qtyById.Keys, menuRows.Select(m => m.Id));

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
            }

            await _context.SaveChangesAsync();

            var saved = await WithOrderGraph(_context.Orders.AsNoTracking())
                .FirstAsync(o => o.Id == order.Id);

            return _mapper.Map<OrderResponse>(saved);
        }

        public override async Task<OrderResponse?> GetByIdAsync(int id)
        {
            var order = await WithOrderGraph(_context.Orders.AsNoTracking())
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

        private static Dictionary<int, int> BuildQtyMap(IEnumerable<int> ids) =>
            ids.GroupBy(i => i).ToDictionary(g => g.Key, g => Math.Max(1, g.Count()));

        private static bool MenuMatches(ICollection<OrderItem> current, IEnumerable<int> requestedIds)
        {
            var req = BuildQtyMap(requestedIds);
            var cur = current
                .GroupBy(i => i.MenuItemId)
                .ToDictionary(g => g.Key, g => g.Sum(x => x.Quantity));

            if (req.Count != cur.Count) return false;
            foreach (var kv in req)
                if (!cur.TryGetValue(kv.Key, out var q) || q != kv.Value)
                    return false;

            return true;
        }

        private async Task<List<(int Id, decimal Price)>> LoadPricedAndAvailableMenuItemsAsync(IEnumerable<int> ids)
        {
            var idSet = ids.ToList();
            return await _context.MenuItem
                .Where(m => idSet.Contains(m.Id) && m.IsAvailable)
                .Select(m => new ValueTuple<int, decimal>(m.Id, m.Price))
                .ToListAsync();
        }

        private static void EnsureAllRequestedItemsExist(IEnumerable<int> requested, IEnumerable<int> found)
        {
            var foundSet = found.ToHashSet();
            var missing = requested.Where(i => !foundSet.Contains(i)).ToList();
            if (missing.Count > 0)
                throw new KeyNotFoundException($"Menu items invalid/unavailable: {string.Join(", ", missing)}");
        }

        private async Task ValidateUserAndReservationAsync(int userId, int? reservationId)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == userId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {userId} not found.");

            if (reservationId.HasValue)
            {
                var reservationExists = await _context.Reservations
                    .AnyAsync(r => r.Id == reservationId.Value /* && r.UserId == userId */);
                if (!reservationExists)
                    throw new KeyNotFoundException($"Reservation with ID {reservationId} not found.");
            }
        }

        // Allow only sensible movements; always allow Cancelled
        private static bool IsValidTransition(OrderStatus from, OrderStatus to) =>
            (from, to) switch
            {
                (OrderStatus.Pending, OrderStatus.Preparing) => true,
                (OrderStatus.Preparing, OrderStatus.Ready) => true,
                (OrderStatus.Ready, OrderStatus.Completed) => true,
                (_, OrderStatus.Cancelled) => true,
                var x when x.from == x.to => true,
                _ => false
            };
    }
}
