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
    public class FavoriteService
        : BaseCRUDService<FavoriteResponse, FavoriteSearchModel, Favorite, FavoriteRequest>,
          IFavoriteService
    {
        public FavoriteService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Favorite> ApplyFilter(IQueryable<Favorite> query, FavoriteSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(f => f.UserId == search.UserId.Value);

            if (search.MenuItemId.HasValue)
                query = query.Where(f => f.MenuItemId == search.MenuItemId.Value);

            return query;
        }

        protected override IQueryable<Favorite> AddInclude(IQueryable<Favorite> query)
        {
            return query
                .Include(f => f.User)
                .Include(f => f.MenuItem);
        }

    }
}
