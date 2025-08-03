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
    public class RestaurantService
        : BaseCRUDService<RestaurantResponse, RestaurantSearchModel, Restaurant, RestaurantRequest, RestaurantUpdateRequest>,
          IRestaurantService
    {
        public RestaurantService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Restaurant> ApplyFilter(IQueryable<Restaurant> query, RestaurantSearchModel search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(r => r.Name.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(r => r.IsActive == search.IsActive.Value);

            return query;
        }

        public override async Task<RestaurantResponse> InsertAsync(RestaurantRequest request)
        {
            var duplicate = await _context.Restaurants
                .AnyAsync(r => r.Name == request.Name);

            if (duplicate)
                throw new InvalidOperationException("A restaurant with the same name already exists.");

            return await base.InsertAsync(request);
        }

        public override async Task<RestaurantResponse?> UpdateAsync(int id, RestaurantUpdateRequest request)
        {
            var entity = await _context.Restaurants.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Restaurant with ID {id} was not found.");

            var duplicate = await _context.Restaurants
                .AnyAsync(r => r.Id != id && r.Name == request.Name);

            if (duplicate)
                throw new InvalidOperationException("Another restaurant with the same name already exists.");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<RestaurantResponse>(entity);
        }

        public override async Task<RestaurantResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Restaurants.FindAsync(id);

            if (entity == null)
                throw new KeyNotFoundException($"Restaurant with ID {id} was not found.");

            return _mapper.Map<RestaurantResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Restaurants.FindAsync(id);

            if (entity == null)
                throw new KeyNotFoundException($"Restaurant with ID {id} was not found.");

            _context.Restaurants.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
