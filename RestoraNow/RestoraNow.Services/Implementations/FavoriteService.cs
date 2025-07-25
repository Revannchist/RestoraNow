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
    public class FavoriteService
        : BaseCRUDService<FavoriteResponse, FavoriteSearchModel, Favorite, FavoriteRequest, FavoriteRequest>,
          IFavoriteService
    {
        public FavoriteService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Favorite> ApplyFilter(IQueryable<Favorite> query, FavoriteSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(f => f.UserId == search.UserId.Value);

            if (search.MenuItemId.HasValue)
                query = query.Where(f => f.MenuItemId == search.MenuItemId.Value);

            return query;
        }

        protected override IQueryable<Favorite> AddInclude(IQueryable<Favorite> query)
        {
            return query
                .Include(f => f.User)
                .Include(f => f.MenuItem);
        }

        public override async Task<FavoriteResponse> InsertAsync(FavoriteRequest request)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            var menuItemExists = await _context.MenuItem.AnyAsync(m => m.Id == request.MenuItemId);
            if (!menuItemExists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} not found.");

            var alreadyExists = await _context.Favorite.AnyAsync(f =>
                f.UserId == request.UserId && f.MenuItemId == request.MenuItemId);

            if (alreadyExists)
                throw new InvalidOperationException("This menu item is already in favorites.");

            var entity = _mapper.Map<Favorite>(request);
            _context.Favorite.Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<FavoriteResponse>(entity);
        }

        public override async Task<FavoriteResponse?> UpdateAsync(int id, FavoriteRequest request)
        {
            var entity = await _context.Favorite.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Favorite with ID {id} not found.");

            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            var menuItemExists = await _context.MenuItem.AnyAsync(m => m.Id == request.MenuItemId);
            if (!menuItemExists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} not found.");

            var duplicate = await _context.Favorite.AnyAsync(f =>
                f.Id != id && f.UserId == request.UserId && f.MenuItemId == request.MenuItemId);
            if (duplicate)
                throw new InvalidOperationException("Another favorite with this user and menu item already exists.");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<FavoriteResponse>(entity);
        }

        public override async Task<FavoriteResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Favorite
                .Include(f => f.User)
                .Include(f => f.MenuItem)
                .FirstOrDefaultAsync(f => f.Id == id);

            if (entity == null)
                throw new KeyNotFoundException($"Favorite with ID {id} not found.");

            return _mapper.Map<FavoriteResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Favorite.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Favorite with ID {id} not found.");

            _context.Favorite.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

    }
}
