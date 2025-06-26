using MapsterMapper;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Implementations
{
    public class RestaurantService
        : BaseCRUDService<RestaurantResponse, RestaurantSearchModel, Restaurant, RestaurantRequest>,
          IRestaurantService
    {
        public RestaurantService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Restaurant> ApplyFilter(IQueryable<Restaurant> query, RestaurantSearchModel search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(r => r.Name.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(r => r.IsActive == search.IsActive.Value);

            return query;
        }
    }
}
