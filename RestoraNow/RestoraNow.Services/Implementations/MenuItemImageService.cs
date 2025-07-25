using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;

namespace RestoraNow.Services.Implementations
{
    public class MenuItemImageService
        : BaseCRUDService<MenuItemImageResponse, MenuItemImageSearchModel, MenuItemImage, MenuItemImageRequest, MenuItemImageRequest>,
          IMenuItemImageService
    {
        public MenuItemImageService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<MenuItemImage> AddInclude(IQueryable<MenuItemImage> query)
        {
            return query.Include(m => m.MenuItem);
        }

        protected override IQueryable<MenuItemImage> ApplyFilter(IQueryable<MenuItemImage> query, MenuItemImageSearchModel search)
        {
            if (search.MenuItemId.HasValue)
                query = query.Where(i => i.MenuItemId == search.MenuItemId.Value);

            return query;
        }

        public override async Task<MenuItemImageResponse> InsertAsync(MenuItemImageRequest request)
        {
            var menuItemExists = await _context.MenuItem.AnyAsync(m => m.Id == request.MenuItemId);
            if (!menuItemExists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} not found.");

            return await base.InsertAsync(request);
        }

        public override async Task<MenuItemImageResponse?> UpdateAsync(int id, MenuItemImageRequest request)
        {
            var image = await _context.MenuItemImages.FindAsync(id);
            if (image == null)
                throw new KeyNotFoundException($"Menu item image with ID {id} was not found.");

            var menuItemExists = await _context.MenuItem.AnyAsync(m => m.Id == request.MenuItemId);
            if (!menuItemExists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} not found.");

            _mapper.Map(request, image);
            await _context.SaveChangesAsync();

            return _mapper.Map<MenuItemImageResponse>(image);
        }

        public override async Task<MenuItemImageResponse?> GetByIdAsync(int id)
        {
            var image = await _context.MenuItemImages.FindAsync(id);
            if (image == null)
                throw new KeyNotFoundException($"Menu item image with ID {id} was not found.");

            return _mapper.Map<MenuItemImageResponse>(image);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var image = await _context.MenuItemImages.FindAsync(id);
            if (image == null)
                throw new KeyNotFoundException($"Menu item image with ID {id} was not found.");

            _context.MenuItemImages.Remove(image);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
