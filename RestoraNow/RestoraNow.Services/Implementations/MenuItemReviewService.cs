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
    public class MenuItemReviewService
        : BaseCRUDService<MenuItemReviewResponse, MenuItemReviewSearchModel, MenuItemReview, MenuItemReviewRequest, MenuItemReviewRequest>,
          IMenuItemReviewService
    {
        public MenuItemReviewService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<MenuItemReview> ApplyFilter(IQueryable<MenuItemReview> query, MenuItemReviewSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(x => x.UserId == search.UserId.Value);

            if (search.MenuItemId.HasValue)
                query = query.Where(x => x.MenuItemId == search.MenuItemId.Value);

            if (search.MinRating.HasValue)
                query = query.Where(x => x.Rating >= search.MinRating.Value);

            if (search.MaxRating.HasValue)
                query = query.Where(x => x.Rating <= search.MaxRating.Value);

            return query;
        }

        protected override IQueryable<MenuItemReview> AddInclude(IQueryable<MenuItemReview> query)
        {
            return query
                .Include(x => x.User)
                .Include(x => x.MenuItem);
        }

        /// <summary>
        /// Upsert behavior: if the user already reviewed this menu item, update that review instead of failing.
        /// </summary>
        public override async Task<MenuItemReviewResponse> InsertAsync(MenuItemReviewRequest request)
        {
            // Validate FK existence (optional but friendly)
            var menuItemExists = await _context.MenuItem.AnyAsync(mi => mi.Id == request.MenuItemId);
            if (!menuItemExists)
                throw new KeyNotFoundException($"Menu item with ID {request.MenuItemId} was not found.");

            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} was not found.");

            // Upsert: one review per (UserId, MenuItemId)
            var existing = await _context.MenuItemReview
                .FirstOrDefaultAsync(r => r.UserId == request.UserId && r.MenuItemId == request.MenuItemId);

            if (existing != null)
            {
                existing.Rating = request.Rating;
                existing.Comment = request.Comment;
                // (Keep CreatedAt as original; or add UpdatedAt column if you want)
                await _context.SaveChangesAsync();

                // Re-load with includes for mapping extras
                await _context.Entry(existing).Reference(r => r.User).LoadAsync();
                await _context.Entry(existing).Reference(r => r.MenuItem).LoadAsync();
                return _mapper.Map<MenuItemReviewResponse>(existing);
            }

            // Otherwise, normal insert
            return await base.InsertAsync(request);
        }

        public override async Task<MenuItemReviewResponse?> UpdateAsync(int id, MenuItemReviewRequest request)
        {
            var entity = await _context.MenuItemReview.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Review with ID {id} was not found.");

            // Option 1 (recommended): allow updating only rating/comment (not UserId/MenuItemId)
            entity.Rating = request.Rating;
            entity.Comment = request.Comment;

            await _context.SaveChangesAsync();

            // Load includes for response
            await _context.Entry(entity).Reference(r => r.User).LoadAsync();
            await _context.Entry(entity).Reference(r => r.MenuItem).LoadAsync();
            return _mapper.Map<MenuItemReviewResponse>(entity);
        }
    }
}
