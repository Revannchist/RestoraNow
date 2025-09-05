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
            // Not strictly required unless your Response exposes MenuItem fields.
            return query.Include(m => m.MenuItem);
        }

        protected override IQueryable<MenuItemImage> ApplyFilter(IQueryable<MenuItemImage> query, MenuItemImageSearchModel search)
        {
            if (search.MenuItemId.HasValue)
                query = query.Where(i => i.MenuItemId == search.MenuItemId.Value);

            return query;
        }

        // ✅ Upsert behavior: one image per MenuItem
        public override async Task<MenuItemImageResponse> InsertAsync(MenuItemImageRequest request)
        {
            var exists = await _context.MenuItem.AnyAsync(m => m.Id == request.MenuItemId);
            if (!exists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} not found.");

            var existingImage = await _context.MenuItemImages
                .FirstOrDefaultAsync(i => i.MenuItemId == request.MenuItemId);

            if (existingImage != null)
            {
                // Update the existing record (upsert)
                existingImage.Url = request.Url;
                existingImage.Description = request.Description;
                await _context.SaveChangesAsync();
                return _mapper.Map<MenuItemImageResponse>(existingImage);
            }

            // No image yet → create new
            return await base.InsertAsync(request);
        }

        public override async Task<MenuItemImageResponse?> UpdateAsync(int id, MenuItemImageRequest request)
        {
            var image = await _context.MenuItemImages.FindAsync(id);
            if (image == null)
                throw new KeyNotFoundException($"Menu item image with ID {id} was not found.");

            // Guard: if moving to another MenuItem, ensure that MenuItem doesn't already have an image
            if (image.MenuItemId != request.MenuItemId)
            {
                var targetHasImage = await _context.MenuItemImages
                    .AnyAsync(i => i.MenuItemId == request.MenuItemId && i.Id != id);
                if (targetHasImage)
                    throw new InvalidOperationException("That menu item already has an image.");
            }

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
