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
    public class OrderService : IOrderService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public OrderService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<OrderResponse>> GetAsync(OrderSearchModel search, CancellationToken cancellationToken = default)
        {
            IQueryable<Order> query = _context.Orders
                .Include(o => o.OrderItems)
                .Include(o => o.Payment)
                .Include(o => o.User)
                .Include(o => o.Reservation)
                .AsNoTracking();

            if (search.UserId.HasValue)
                query = query.Where(o => o.UserId == search.UserId);

            if (search.Status.HasValue)
                query = query.Where(o => o.Status == search.Status.Value);

            if (search.FromDate.HasValue)
                query = query.Where(o => o.CreatedAt >= search.FromDate.Value);

            if (search.ToDate.HasValue)
                query = query.Where(o => o.CreatedAt <= search.ToDate.Value);

            var orders = await query.ToListAsync(cancellationToken);
            return _mapper.Map<IEnumerable<OrderResponse>>(orders);
        }

        public async Task<OrderResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .Include(o => o.Payment)
                .Include(o => o.User)
                .Include(o => o.Reservation)
                .AsNoTracking()
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            return order == null ? null : _mapper.Map<OrderResponse>(order);
        }

        public async Task<OrderResponse> InsertAsync(OrderRequest request, CancellationToken cancellationToken = default)
        {
            var order = _mapper.Map<Order>(request);
            order.CreatedAt = DateTime.UtcNow;

            _context.Orders.Add(order);
            await _context.SaveChangesAsync(cancellationToken);

            return _mapper.Map<OrderResponse>(order);
        }

        public async Task<OrderResponse?> UpdateAsync(int id, OrderRequest request, CancellationToken cancellationToken = default)
        {
            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if (order == null)
                return null;

            _mapper.Map(request, order);
            await _context.SaveChangesAsync(cancellationToken);

            return _mapper.Map<OrderResponse>(order);
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var order = await _context.Orders.FindAsync(new object[] { id }, cancellationToken);
            if (order == null)
                return false;

            _context.Orders.Remove(order);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}
