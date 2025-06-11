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
    public class FavoriteService : IFavoriteService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public FavoriteService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<FavoriteResponse>> GetAsync(FavoriteSearchModel search, CancellationToken cancellationToken = default)
        {
            IQueryable<Favorite> query = _context.Favorite
                .AsNoTracking()
                .Include(f => f.User)
                .Include(f => f.MenuItem);

            if (search.UserId.HasValue)
                query = query.Where(f => f.UserId == search.UserId.Value);

            if (search.MenuItemId.HasValue)
                query = query.Where(f => f.MenuItemId == search.MenuItemId.Value);

            var favorites = await query.ToListAsync(cancellationToken);
            return favorites.Select(f => new FavoriteResponse
            {
                Id = f.Id,
                UserId = f.UserId,
                UserName = f.User?.Username,
                MenuItemId = f.MenuItemId,
                MenuItemName = f.MenuItem?.Name,
                CreatedAt = f.CreatedAt
            });
        }

        public async Task<FavoriteResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var favorite = await _context.Favorite
                .Include(f => f.User)
                .Include(f => f.MenuItem)
                .AsNoTracking()
                .FirstOrDefaultAsync(f => f.Id == id, cancellationToken);

            if (favorite == null)
                return null;

            return new FavoriteResponse
            {
                Id = favorite.Id,
                UserId = favorite.UserId,
                UserName = favorite.User?.Username,
                MenuItemId = favorite.MenuItemId,
                MenuItemName = favorite.MenuItem?.Name,
                CreatedAt = favorite.CreatedAt
            };
        }

        public async Task<FavoriteResponse> InsertAsync(FavoriteRequest request, CancellationToken cancellationToken = default)
        {
            var favorite = _mapper.Map<Favorite>(request);
            _context.Favorite.Add(favorite);
            await _context.SaveChangesAsync(cancellationToken);

            favorite = await _context.Favorite
                .Include(f => f.User)
                .Include(f => f.MenuItem)
                .FirstOrDefaultAsync(f => f.Id == favorite.Id, cancellationToken);

            return _mapper.Map<FavoriteResponse>(favorite!);
        }

        public async Task<FavoriteResponse?> UpdateAsync(int id, FavoriteRequest request, CancellationToken cancellationToken = default)
        {
            var favorite = await _context.Favorite.FindAsync(new object[] { id }, cancellationToken);
            if (favorite == null)
                return null;

            _mapper.Map(request, favorite);
            await _context.SaveChangesAsync(cancellationToken);

            favorite = await _context.Favorite
                .Include(f => f.User)
                .Include(f => f.MenuItem)
                .FirstOrDefaultAsync(f => f.Id == id, cancellationToken);

            return _mapper.Map<FavoriteResponse>(favorite!);
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var favorite = await _context.Favorite.FindAsync(new object[] { id }, cancellationToken);
            if (favorite == null)
                return false;

            _context.Favorite.Remove(favorite);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}
