using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using System;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Implementations
{
    public class TableService
        : BaseCRUDService<TableResponse, TableSearchModel, Table, TableCreateRequest>,
          ITableService
    {
        public TableService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Table> ApplyFilter(IQueryable<Table> query, TableSearchModel search)
        {
            if (search.RestaurantId.HasValue)
                query = query.Where(t => t.Restaurant.Id == search.RestaurantId.Value);
            if (search.Capacity.HasValue)
                query = query.Where(t => t.Capacity >= search.Capacity.Value);
            if (search.IsAvailable.HasValue)
                query = query.Where(t => t.IsAvailable == search.IsAvailable.Value);

            return query;
        }

        protected override IQueryable<Table> AddInclude(IQueryable<Table> query)
        {
            return query.Include(t => t.Restaurant);
        }
    }
}
