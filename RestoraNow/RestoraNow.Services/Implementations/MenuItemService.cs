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
    public class MenuItemService
        : BaseCRUDService<MenuItemResponse, MenuItemSearchModel, MenuItem, MenuItemRequest, MenuItemRequest>,
          IMenuItemService
    {
        public MenuItemService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<MenuItem> ApplyFilter(IQueryable<MenuItem> query, MenuItemSearchModel search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(x => x.Name.Contains(search.Name));
            if (search.CategoryId.HasValue)
                query = query.Where(x => x.CategoryId == search.CategoryId.Value);
            if (search.IsAvailable.HasValue)
                query = query.Where(x => x.IsAvailable == search.IsAvailable.Value);
            if (search.IsSpecialOfTheDay.HasValue)
                query = query.Where(x => x.IsSpecialOfTheDay == search.IsSpecialOfTheDay.Value);

            return query;
        }

        protected override IQueryable<MenuItem> AddInclude(IQueryable<MenuItem> query)
        {
            return query
                .Include(x => x.Category)
                .Include(x => x.Images);
        }

        public override async Task<MenuItemResponse> InsertAsync(MenuItemRequest request)
        {
            var categoryExists = await _context.Categories.AnyAsync(c => c.Id == request.CategoryId);
            if (!categoryExists)
                throw new KeyNotFoundException($"Category with ID {request.CategoryId} was not found.");

            var duplicate = await _context.MenuItem
                .AnyAsync(x => x.Name == request.Name && x.CategoryId == request.CategoryId);

            if (duplicate)
                throw new InvalidOperationException("A menu item with the same name already exists in this category.");

            return await base.InsertAsync(request);
        }

        public override async Task<MenuItemResponse?> UpdateAsync(int id, MenuItemRequest request)
        {
            var existing = await _context.MenuItem.FindAsync(id);
            if (existing == null)
                throw new KeyNotFoundException($"Menu item with ID {id} was not found.");

            var categoryExists = await _context.Categories.AnyAsync(c => c.Id == request.CategoryId);
            if (!categoryExists)
                throw new KeyNotFoundException($"Category with ID {request.CategoryId} was not found.");

            var duplicate = await _context.MenuItem
                .AnyAsync(x => x.Id != id && x.Name == request.Name && x.CategoryId == request.CategoryId);

            if (duplicate)
                throw new InvalidOperationException("Another menu item with the same name already exists in this category.");

            return await base.UpdateAsync(id, request);
        }

        public override async Task<MenuItemResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.MenuItem
                .Include(x => x.Category)
                .Include(x => x.Images)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                throw new KeyNotFoundException($"Menu item with ID {id} was not found.");

            return _mapper.Map<MenuItemResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.MenuItem.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Menu item with ID {id} was not found.");

            _context.MenuItem.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
