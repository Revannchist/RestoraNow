using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Base;
using RestoraNow.Services.Data;
using RestoraNow.Services.Interfaces.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
namespace RestoraNow.Services.BaseServices
{
    public abstract class BaseCRUDService<TModel, TSearch, TEntity, TCreateUpdate> :
        BaseService<TModel, TSearch, TEntity>, ICRUDService<TModel, TSearch, TCreateUpdate> where TSearch : BaseSearchObject where TEntity : class, new()
    {
        protected BaseCRUDService(ApplicationDbContext context, IMapper mapper) : base(context, mapper) { }

        public virtual async Task<TModel> InsertAsync(TCreateUpdate request)
        {
            var entity = _mapper.Map<TEntity>(request);
            _context.Set<TEntity>().Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<TModel>(entity);
        }

        public virtual async Task<TModel?> UpdateAsync(int id, TCreateUpdate request)
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

        //protected virtual IQueryable<TEntity> AddInclude(IQueryable<TEntity> query)
        //{
        //    return query;
        //}

    }
}