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
        : BaseCRUDService<OrderItemResponse, OrderItemSearchModel, OrderItem, OrderItemRequest, OrderItemRequest>,
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

        public override async Task<OrderItemResponse> InsertAsync(OrderItemRequest request)
        {
            var orderExists = await _context.Orders.AnyAsync(o => o.Id == request.OrderId);
            if (!orderExists)
                throw new KeyNotFoundException($"Order with ID {request.OrderId} was not found.");

            var menuItemExists = await _context.MenuItem.AnyAsync(m => m.Id == request.MenuItemId);
            if (!menuItemExists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} was not found.");

            return await base.InsertAsync(request);
        }

        public override async Task<OrderItemResponse?> UpdateAsync(int id, OrderItemRequest request)
        {
            var orderItem = await _context.OrderItems.FindAsync(id);
            if (orderItem == null)
                throw new KeyNotFoundException($"Order item with ID {id} was not found.");

            var orderExists = await _context.Orders.AnyAsync(o => o.Id == request.OrderId);
            if (!orderExists)
                throw new KeyNotFoundException($"Order with ID {request.OrderId} was not found.");

            var menuItemExists = await _context.MenuItem.AnyAsync(m => m.Id == request.MenuItemId);
            if (!menuItemExists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} was not found.");

            _mapper.Map(request, orderItem);
            await _context.SaveChangesAsync();

            return _mapper.Map<OrderItemResponse>(orderItem);
        }

        public override async Task<OrderItemResponse?> GetByIdAsync(int id)
        {
            var orderItem = await _context.OrderItems
                .Include(o => o.Order)
                .Include(o => o.MenuItem)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (orderItem == null)
                throw new KeyNotFoundException($"Order item with ID {id} was not found.");

            return _mapper.Map<OrderItemResponse>(orderItem);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var orderItem = await _context.OrderItems.FindAsync(id);

            if (orderItem == null)
                throw new KeyNotFoundException($"Order item with ID {id} was not found.");

            _context.OrderItems.Remove(orderItem);
            await _context.SaveChangesAsync();

            return true;
        }

    }
}
