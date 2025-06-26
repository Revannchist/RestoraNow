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
    public class MenuItemService
        : BaseCRUDService<MenuItemResponse, MenuItemSearchModel, MenuItem, MenuItemRequest>,
          IMenuItemService
    {
        public MenuItemService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<MenuItem> ApplyFilter(IQueryable<MenuItem> query, MenuItemSearchModel search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(x => x.Name.Contains(search.Name));
            if (search.CategoryId.HasValue)
                query = query.Where(x => x.CategoryId == search.CategoryId.Value);
            if (search.IsAvailable.HasValue)
                query = query.Where(x => x.IsAvailable == search.IsAvailable.Value);
            if (search.IsSpecialOfTheDay.HasValue)
                query = query.Where(x => x.IsSpecialOfTheDay == search.IsSpecialOfTheDay.Value);

            return query;
        }

        protected override IQueryable<MenuItem> AddInclude(IQueryable<MenuItem> query)
        {
            return query
                .Include(x => x.Category)
                .Include(x => x.Images);
        }
    }
}
