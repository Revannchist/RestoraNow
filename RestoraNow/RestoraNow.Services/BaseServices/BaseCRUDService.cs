using MapsterMapper;
using RestoraNow.Model.Base;
using RestoraNow.Services.Data;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.BaseServices
{
    public abstract class BaseCRUDService<TModel, TSearch, TEntity, TInsert, TUpdate>
        : BaseService<TModel, TSearch, TEntity>, ICRUDService<TModel, TSearch, TInsert, TUpdate>
        where TSearch : BaseSearchObject
        where TEntity : class, new()
    {
        protected BaseCRUDService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public virtual async Task<TModel> InsertAsync(TInsert request)
        {
            var entity = _mapper.Map<TEntity>(request);
            _context.Set<TEntity>().Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<TModel>(entity);
        }

        public virtual async Task<TModel?> UpdateAsync(int id, TUpdate request)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return default;

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<TModel>(entity);
        }

        public virtual async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return false;

            _context.Set<TEntity>().Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}