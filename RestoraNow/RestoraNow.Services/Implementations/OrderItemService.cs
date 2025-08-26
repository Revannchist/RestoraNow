using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests.Order;
using RestoraNow.Model.Responses.Order;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.Services.Implementations
{
    public class OrderItemService
        : BaseCRUDService<OrderItemResponse, OrderItemSearchModel, OrderItem, OrderItemRequest, OrderItemRequest>,
          IOrderItemService
    {
        public OrderItemService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper) { }

        protected override IQueryable<OrderItem> ApplyFilter(IQueryable<OrderItem> query, OrderItemSearchModel search)
        {
            if (search.OrderId.HasValue)
                query = query.Where(oi => oi.OrderId == search.OrderId);
            if (search.MenuItemId.HasValue)
                query = query.Where(oi => oi.MenuItemId == search.MenuItemId);

            return query;
        }

        protected override IQueryable<OrderItem> AddInclude(IQueryable<OrderItem> query) =>
            query.Include(o => o.MenuItem).Include(o => o.Order);

        public override async Task<OrderItemResponse> InsertAsync(OrderItemRequest request)
        {
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.Id == request.OrderId);

            if (order == null)
                throw new KeyNotFoundException($"Order with ID {request.OrderId} was not found.");

            if (order.Status != Model.Enums.OrderStatus.Pending)
                throw new InvalidOperationException("Items can only be added to pending orders.");

            var menu = await _context.MenuItem
                .Where(m => m.Id == request.MenuItemId && m.IsAvailable)
                .Select(m => new { m.Id, m.Price })
                .FirstOrDefaultAsync();

            if (menu == null)
                throw new KeyNotFoundException("Menu item invalid or unavailable.");

            var qty = request.Quantity <= 0 ? 1 : request.Quantity;

            var entity = new OrderItem
            {
                OrderId = request.OrderId,
                MenuItemId = request.MenuItemId,
                Quantity = qty,
                UnitPrice = menu.Price // ignore client UnitPrice
            };

            _context.OrderItems.Add(entity);
            await _context.SaveChangesAsync();

            var saved = await _context.OrderItems
                .Include(oi => oi.MenuItem)
                .Include(oi => oi.Order)
                .AsNoTracking()
                .FirstAsync(oi => oi.Id == entity.Id);

            return _mapper.Map<OrderItemResponse>(saved);
        }

        public override async Task<OrderItemResponse?> UpdateAsync(int id, OrderItemRequest request)
        {
            var orderItem = await _context.OrderItems
                .Include(oi => oi.Order)
                .FirstOrDefaultAsync(oi => oi.Id == id);

            if (orderItem == null)
                throw new KeyNotFoundException($"Order item with ID {id} was not found.");

            if (orderItem.Order.Status != Model.Enums.OrderStatus.Pending)
                throw new InvalidOperationException("Items can only be edited on pending orders.");

            // If MenuItemId changes, re-validate & re-price
            if (orderItem.MenuItemId != request.MenuItemId)
            {
                var menu = await _context.MenuItem
                    .Where(m => m.Id == request.MenuItemId && m.IsAvailable)
                    .Select(m => new { m.Id, m.Price })
                    .FirstOrDefaultAsync();

                if (menu == null)
                    throw new KeyNotFoundException("Menu item invalid or unavailable.");

                orderItem.MenuItemId = request.MenuItemId;
                orderItem.UnitPrice = menu.Price;
            }

            orderItem.Quantity = request.Quantity <= 0 ? 1 : request.Quantity;

            await _context.SaveChangesAsync();

            var saved = await _context.OrderItems
                .Include(oi => oi.MenuItem)
                .Include(oi => oi.Order)
                .AsNoTracking()
                .FirstAsync(oi => oi.Id == orderItem.Id);

            return _mapper.Map<OrderItemResponse>(saved);
        }

        public override async Task<OrderItemResponse?> GetByIdAsync(int id)
        {
            var orderItem = await _context.OrderItems
                .Include(o => o.Order)
                .Include(o => o.MenuItem)
                .AsNoTracking()
                .FirstOrDefaultAsync(o => o.Id == id);

            if (orderItem == null)
                throw new KeyNotFoundException($"Order item with ID {id} was not found.");

            return _mapper.Map<OrderItemResponse>(orderItem);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var orderItem = await _context.OrderItems
                .Include(oi => oi.Order)
                .FirstOrDefaultAsync(oi => oi.Id == id);

            if (orderItem == null)
                throw new KeyNotFoundException($"Order item with ID {id} was not found.");

            if (orderItem.Order.Status != Model.Enums.OrderStatus.Pending)
                throw new InvalidOperationException("Items can only be removed from pending orders.");

            _context.OrderItems.Remove(orderItem);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
