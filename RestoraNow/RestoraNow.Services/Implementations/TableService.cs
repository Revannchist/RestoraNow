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
    public class TableService
        : BaseCRUDService<TableResponse, TableSearchModel, Table, TableRequest, TableRequest>,
          ITableService
    {
        public TableService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Table> ApplyFilter(IQueryable<Table> query, TableSearchModel search)
        {
            //if (search.RestaurantId.HasValue)
            //    query = query.Where(t => t.RestaurantId == search.RestaurantId.Value);

            if (search.Capacity.HasValue)
                query = query.Where(t => t.Capacity >= search.Capacity.Value);

            if (search.IsAvailable.HasValue)
                query = query.Where(t => t.IsAvailable == search.IsAvailable.Value);

            if (search.TableNumber.HasValue)
                query = query.Where(t => t.TableNumber == search.TableNumber.Value);

            return query;
        }

        protected override IQueryable<Table> AddInclude(IQueryable<Table> query)
        {
            return query.Include(t => t.Restaurant);
        }

        public override async Task<TableResponse> InsertAsync(TableRequest request)
        {
            var restaurantExists = await _context.Restaurants.AnyAsync(r => r.Id == request.RestaurantId);
            if (!restaurantExists)
                throw new KeyNotFoundException($"Restaurant with ID {request.RestaurantId} not found.");

            var exists = await _context.Tables.AnyAsync(t =>
                t.RestaurantId == request.RestaurantId && t.TableNumber == request.TableNumber);

            if (exists)
                throw new InvalidOperationException("A table with the same number already exists in this restaurant.");

            return await base.InsertAsync(request);
        }

        public override async Task<TableResponse?> UpdateAsync(int id, TableRequest request)
        {
            var entity = await _context.Tables.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Table with ID {id} was not found.");

            var restaurantExists = await _context.Restaurants.AnyAsync(r => r.Id == request.RestaurantId);
            if (!restaurantExists)
                throw new KeyNotFoundException($"Restaurant with ID {request.RestaurantId} not found.");

            var duplicate = await _context.Tables.AnyAsync(t =>
                t.Id != id && t.RestaurantId == request.RestaurantId && t.TableNumber == request.TableNumber);

            if (duplicate)
                throw new InvalidOperationException("Another table with the same number already exists in this restaurant.");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<TableResponse>(entity);
        }

        public override async Task<TableResponse?> GetByIdAsync(int id)
        {
            var table = await _context.Tables
                .Include(t => t.Restaurant)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (table == null)
                throw new KeyNotFoundException($"Table with ID {id} was not found.");

            return _mapper.Map<TableResponse>(table);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Tables.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Table with ID {id} was not found.");

            _context.Tables.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
