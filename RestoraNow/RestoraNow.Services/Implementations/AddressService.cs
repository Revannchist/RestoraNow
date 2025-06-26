using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using MapsterMapper;

namespace RestoraNow.Services.Implementations
{
    public class AddressService
        : BaseCRUDService<AddressResponse, AddressSearchModel, Address, AddressRequest>,
          IAddressService
    {
        public AddressService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Address> ApplyFilter(IQueryable<Address> query, AddressSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(a => a.UserId == search.UserId.Value);

            if (!string.IsNullOrWhiteSpace(search.City))
                query = query.Where(a => a.City.Contains(search.City));

            return query;
        }
    }
}
