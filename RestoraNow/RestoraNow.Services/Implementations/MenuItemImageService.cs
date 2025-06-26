using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using RestoraNow.Model.Responses;
using RestoraNow.Model.Requests;
using RestoraNow.Model.SearchModels;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace RestoraNow.Services.Implementations
{
    public class MenuItemImageService
        : BaseCRUDService<MenuItemImageResponse, MenuItemImageSearchModel, MenuItemImage, MenuItemImageRequest>,
          IMenuItemImageService
    {
        public MenuItemImageService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<MenuItemImage> AddInclude(IQueryable<MenuItemImage> query)
        {
            return query.Include(m => m.MenuItem);
        }

        protected override IQueryable<MenuItemImage> ApplyFilter(IQueryable<MenuItemImage> query, MenuItemImageSearchModel search)
        {
            if (search.MenuItemId.HasValue)
                query = query.Where(i => i.MenuItemId == search.MenuItemId.Value);

            return query;
        }
    }
}
