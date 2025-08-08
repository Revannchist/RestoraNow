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
    public class ReviewService
        : BaseCRUDService<ReviewResponse, ReviewSearchModel, Review, ReviewRequest, ReviewRequest>,
          IReviewService
    {
        public ReviewService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);
            if (search.RestaurantId.HasValue)
                query = query.Where(r => r.RestaurantId == search.RestaurantId.Value);
            if (search.MinRating.HasValue)
                query = query.Where(r => r.Rating >= search.MinRating.Value);
            if (search.MaxRating.HasValue)
                query = query.Where(r => r.Rating <= search.MaxRating.Value);

            return query;
        }

        protected override IQueryable<Review> AddInclude(IQueryable<Review> query)
        {
            return query.Include(r => r.User)
                        .Include(r => r.Restaurant);
        }

        public override async Task<ReviewResponse> InsertAsync(ReviewRequest request)
        {
            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
                throw new KeyNotFoundException($"User with ID {request.UserId} was not found.");

            if (!await _context.Restaurants.AnyAsync(r => r.Id == request.RestaurantId))
                throw new KeyNotFoundException($"Restaurant with ID {request.RestaurantId} was not found.");

            var exists = await _context.Reviews.AnyAsync(r =>
                r.UserId == request.UserId && r.RestaurantId == request.RestaurantId);

            if (exists)
                throw new InvalidOperationException("You have already reviewed this restaurant.");

            return await base.InsertAsync(request);
        }

        public override async Task<ReviewResponse?> UpdateAsync(int id, ReviewRequest request)
        {
            var entity = await _context.Reviews
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                throw new KeyNotFoundException($"Review with ID {id} was not found.");

            if (!await _context.Users.AnyAsync(u => u.Id == request.UserId))
                throw new KeyNotFoundException($"User with ID {request.UserId} was not found.");

            if (!await _context.Restaurants.AnyAsync(r => r.Id == request.RestaurantId))
                throw new KeyNotFoundException($"Restaurant with ID {request.RestaurantId} was not found.");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<ReviewResponse>(entity);
        }

        public override async Task<ReviewResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Reviews
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                throw new KeyNotFoundException($"Review with ID {id} was not found.");

            return _mapper.Map<ReviewResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Reviews.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Review with ID {id} was not found.");

            _context.Reviews.Remove(entity);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
