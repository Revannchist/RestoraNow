using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using MapsterMapper;

namespace RestoraNow.Services.Implementations
{
    public class OrderItemService : IOrderItemService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public OrderItemService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<OrderItemResponse>> GetAsync(OrderItemSearchModel search, CancellationToken cancellationToken = default)
        {
            IQueryable<OrderItem> query = _context.OrderItems.AsNoTracking();

            if (search.OrderId.HasValue)
                query = query.Where(x => x.OrderId == search.OrderId.Value);
            if (search.MenuItemId.HasValue)
                query = query.Where(x => x.MenuItemId == search.MenuItemId.Value);

            var result = await query.ToListAsync(cancellationToken);
            return _mapper.Map<IEnumerable<OrderItemResponse>>(result);
        }

        public async Task<OrderItemResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.OrderItems.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
            return entity == null ? null : _mapper.Map<OrderItemResponse>(entity);
        }

        public async Task<OrderItemResponse> InsertAsync(OrderItemRequest request, CancellationToken cancellationToken = default)
        {
            var entity = _mapper.Map<OrderItem>(request);

            _context.OrderItems.Add(entity);
            await _context.SaveChangesAsync(cancellationToken);

            return _mapper.Map<OrderItemResponse>(entity);
        }

        public async Task<OrderItemResponse?> UpdateAsync(int id, OrderItemRequest request, CancellationToken cancellationToken = default)
        {
            var entity = await _context.OrderItems.FindAsync(new object[] { id }, cancellationToken);
            if (entity == null)
                return null;

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync(cancellationToken);

            return _mapper.Map<OrderItemResponse>(entity);
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var entity = await _context.OrderItems.FindAsync(new object[] { id }, cancellationToken);
            if (entity == null)
                return false;

            _context.OrderItems.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);

            return true;
        }
    }
}
