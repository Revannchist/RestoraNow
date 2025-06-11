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
    public class MenuItemService : IMenuItemService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public MenuItemService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<MenuItemResponse>> GetAsync(MenuItemSearchModel search, CancellationToken cancellationToken = default)
        {
            var query = _context.MenuItem
                .Include(m => m.Category)
                .AsNoTracking();

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(m => m.Name.Contains(search.Name));

            if (search.CategoryId.HasValue)
                query = query.Where(m => m.CategoryId == search.CategoryId.Value);

            if (search.IsAvailable.HasValue)
                query = query.Where(m => m.IsAvailable == search.IsAvailable.Value);

            if (search.IsSpecialOfTheDay.HasValue)
                query = query.Where(m => m.IsSpecialOfTheDay == search.IsSpecialOfTheDay.Value);

            var items = await query.ToListAsync(cancellationToken);
            return items.Select(item => new MenuItemResponse
            {
                Id = item.Id,
                Name = item.Name,
                Description = item.Description,
                Price = item.Price,
                IsAvailable = item.IsAvailable,
                IsSpecialOfTheDay = item.IsSpecialOfTheDay,
                CategoryId = item.CategoryId,
                CategoryName = item.Category.Name
            });
        }

        public async Task<MenuItemResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var item = await _context.MenuItem
                .Include(m => m.Category)
                .AsNoTracking()
                .FirstOrDefaultAsync(m => m.Id == id, cancellationToken);

            return item == null ? null : new MenuItemResponse
            {
                Id = item.Id,
                Name = item.Name,
                Description = item.Description,
                Price = item.Price,
                IsAvailable = item.IsAvailable,
                IsSpecialOfTheDay = item.IsSpecialOfTheDay,
                CategoryId = item.CategoryId,
                CategoryName = item.Category.Name
            };
        }

        public async Task<MenuItemResponse> InsertAsync(MenuItemRequest request, CancellationToken cancellationToken = default)
        {
            var item = _mapper.Map<MenuItem>(request);
            _context.MenuItem.Add(item);
            await _context.SaveChangesAsync(cancellationToken);

            var categoryName = (await _context.Categories.FindAsync(request.CategoryId))?.Name ?? "";

            return new MenuItemResponse
            {
                Id = item.Id,
                Name = item.Name,
                Description = item.Description,
                Price = item.Price,
                IsAvailable = item.IsAvailable,
                IsSpecialOfTheDay = item.IsSpecialOfTheDay,
                CategoryId = item.CategoryId,
                CategoryName = categoryName
            };
        }

        public async Task<MenuItemResponse?> UpdateAsync(int id, MenuItemRequest request, CancellationToken cancellationToken = default)
        {
            var item = await _context.MenuItem.FindAsync(new object[] { id }, cancellationToken);
            if (item == null)
                return null;

            _mapper.Map(request, item);
            await _context.SaveChangesAsync(cancellationToken);

            var categoryName = (await _context.Categories.FindAsync(request.CategoryId))?.Name ?? "";

            return new MenuItemResponse
            {
                Id = item.Id,
                Name = item.Name,
                Description = item.Description,
                Price = item.Price,
                IsAvailable = item.IsAvailable,
                IsSpecialOfTheDay = item.IsSpecialOfTheDay,
                CategoryId = item.CategoryId,
                CategoryName = categoryName
            };
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var item = await _context.MenuItem.FindAsync(new object[] { id }, cancellationToken);
            if (item == null)
                return false;

            _context.MenuItem.Remove(item);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}
