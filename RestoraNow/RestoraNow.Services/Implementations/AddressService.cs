using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace RestoraNow.Services.Implementations
{
    public class AddressService
        : BaseCRUDService<AddressResponse, AddressSearchModel, Address, AddressRequest, AddressRequest>,
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

        public override async Task<AddressResponse> InsertAsync(AddressRequest request)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new InvalidOperationException($"User with ID {request.UserId} does not exist.");

            return await base.InsertAsync(request);
        }

        public override async Task<AddressResponse?> UpdateAsync(int id, AddressRequest request)
        {
            var address = await _context.Address.FindAsync(id);
            if (address == null)
                throw new KeyNotFoundException($"Address with ID {id} was not found.");

            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new InvalidOperationException($"User with ID {request.UserId} does not exist.");

            // Map and update
            _mapper.Map(request, address);
            await _context.SaveChangesAsync();

            return _mapper.Map<AddressResponse>(address);
        }

        public override async Task<AddressResponse?> GetByIdAsync(int id)
        {
            var address = await _context.Address.FindAsync(id);

            if (address == null)
                throw new KeyNotFoundException($"Address with ID {id} was not found.");

            return _mapper.Map<AddressResponse>(address);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var address = await _context.Address.FindAsync(id);

            if (address == null)
                throw new KeyNotFoundException($"Address with ID {id} was not found.");

            _context.Address.Remove(address);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}
