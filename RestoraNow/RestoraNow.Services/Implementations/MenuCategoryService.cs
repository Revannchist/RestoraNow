using MapsterMapper;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace RestoraNow.Services.Implementations
{
    public class MenuCategoryService
        : BaseCRUDService<MenuCategoryResponse, MenuCategorySearchModel, MenuCategory, MenuCategoryRequest, MenuCategoryRequest>,
          IMenuCategoryService
    {
        public MenuCategoryService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<MenuCategory> ApplyFilter(IQueryable<MenuCategory> query, MenuCategorySearchModel search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(mc => mc.Name.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(mc => mc.IsActive == search.IsActive.Value);

            return query;
        }

        public override async Task<MenuCategoryResponse> InsertAsync(MenuCategoryRequest request)
        {
            var exists = await _context.Categories
                .AnyAsync(mc => mc.Name == request.Name);

            if (exists)
                throw new InvalidOperationException("A menu category with the same name already exists.");

            return await base.InsertAsync(request);
        }

        public override async Task<MenuCategoryResponse?> UpdateAsync(int id, MenuCategoryRequest request)
        {
            var existing = await _context.Categories.FindAsync(id);
            if (existing == null)
                throw new KeyNotFoundException($"Menu category with ID {id} was not found.");

            var duplicate = await _context.Categories
                .AnyAsync(mc => mc.Id != id && mc.Name == request.Name);

            if (duplicate)
                throw new InvalidOperationException("Another menu category with the same name already exists.");

            return await base.UpdateAsync(id, request);
        }

        public override async Task<MenuCategoryResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Categories.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Menu category with ID {id} was not found.");

            return _mapper.Map<MenuCategoryResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Categories.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"Menu category with ID {id} was not found.");

            _context.Categories.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }

    }
}
