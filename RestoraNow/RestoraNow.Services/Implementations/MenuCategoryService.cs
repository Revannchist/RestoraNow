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
    public class MenuCategoryService : IMenuCategoryService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public MenuCategoryService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<MenuCategoryResponse>> GetAsync(MenuCategorySearchModel search, CancellationToken cancellationToken = default)
        {
            var query = _context.Categories.AsNoTracking();

            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(c => c.Name.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(c => c.IsActive == search.IsActive.Value);

            var categories = await query.ToListAsync(cancellationToken);
            return _mapper.Map<IEnumerable<MenuCategoryResponse>>(categories);
        }

        public async Task<MenuCategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var category = await _context.Categories.AsNoTracking().FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
            return category == null ? null : _mapper.Map<MenuCategoryResponse>(category);
        }

        public async Task<MenuCategoryResponse> InsertAsync(MenuCategoryRequest request, CancellationToken cancellationToken = default)
        {
            var category = _mapper.Map<MenuCategory>(request);
            _context.Categories.Add(category);
            await _context.SaveChangesAsync(cancellationToken);
            return _mapper.Map<MenuCategoryResponse>(category);
        }

        public async Task<MenuCategoryResponse?> UpdateAsync(int id, MenuCategoryRequest request, CancellationToken cancellationToken = default)
        {
            var category = await _context.Categories.FindAsync(new object[] { id }, cancellationToken);
            if (category == null)
                return null;

            _mapper.Map(request, category);
            await _context.SaveChangesAsync(cancellationToken);
            return _mapper.Map<MenuCategoryResponse>(category);
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var category = await _context.Categories.FindAsync(new object[] { id }, cancellationToken);
            if (category == null)
                return false;

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}
