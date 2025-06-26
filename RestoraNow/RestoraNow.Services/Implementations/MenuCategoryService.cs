using MapsterMapper;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.Services.Implementations
{
    public class MenuCategoryService
        : BaseCRUDService<MenuCategoryResponse, MenuCategorySearchModel, MenuCategory, MenuCategoryRequest>,
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
    }
}
