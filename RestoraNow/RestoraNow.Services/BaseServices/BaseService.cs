using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Base;
using RestoraNow.Services.Data;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.BaseServices
{
    public abstract class BaseService<TModel, TSearch, TEntity> : IService<TModel, TSearch>
        where TSearch : BaseSearchObject
        where TEntity : class
    {
        protected readonly ApplicationDbContext _context;
        protected readonly IMapper _mapper;

        protected BaseService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        protected virtual IQueryable<TEntity> AddInclude(IQueryable<TEntity> query)
        {
            return query;
        }

        public virtual async Task<PagedResult<TModel>> GetAsync(TSearch search)
        {
            IQueryable<TEntity> query = _context.Set<TEntity>().AsNoTracking();

            query = AddInclude(query);

            query = ApplyFilter(query, search);
            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }
            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                    query = query.Skip(search.Page.Value * search.PageSize ?? 10);
                if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }
            var list = await query.ToListAsync();
            var mappedList = _mapper.Map<List<TModel>>(list);
            return new PagedResult<TModel> { Items = mappedList, TotalCount = totalCount };
        }

        public virtual async Task<TModel?> GetByIdAsync(int id)
        {
            IQueryable<TEntity> query = _context.Set<TEntity>().AsNoTracking(); // Add AsNoTracking()
            query = AddInclude(query);
            var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);
            return entity == null ? default : _mapper.Map<TModel>(entity);
        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            return query;
        }
    }
}