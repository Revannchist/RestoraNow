using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
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
    public class AddressService : IAddressService
    {
        private readonly ApplicationDbContext _context;

        public AddressService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<AddressResponse>> GetAsync(AddressSearchModel search)
        {
            // Base query
            IQueryable<Address> query = _context.Address.AsNoTracking();

            // Filtering (example)
            if (search.UserId.HasValue)
                query = query.Where(a => a.UserId == search.UserId.Value);

            if (!string.IsNullOrWhiteSpace(search.City))
                query = query.Where(a => a.City.Contains(search.City));

            var addresses = await query.ToListAsync();

            return addresses.Select(MapToResponse);
        }

        public async Task<AddressResponse?> GetByIdAsync(int id)
        {
            var address = await _context.Address
                .AsNoTracking()
                .FirstOrDefaultAsync(a => a.Id == id);

            return address == null ? null : MapToResponse(address);
        }

        public async Task<AddressResponse> InsertAsync(AddressRequest request)
        {
            var address = new Address
            {
                UserId = request.UserId,
                Street = request.Street,
                City = request.City,
                ZipCode = request.ZipCode,
                Country = request.Country,
                IsDefault = request.IsDefault
            };

            _context.Address.Add(address);
            await _context.SaveChangesAsync();

            return MapToResponse(address);
        }

        public async Task<AddressResponse?> UpdateAsync(int id, AddressRequest request)
        {
            var address = await _context.Address.FindAsync(id);

            if (address == null)
                return null;

            address.UserId = request.UserId;
            address.Street = request.Street;
            address.City = request.City;
            address.ZipCode = request.ZipCode;
            address.Country = request.Country;
            address.IsDefault = request.IsDefault;

            await _context.SaveChangesAsync();

            return MapToResponse(address);
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var address = await _context.Address.FindAsync(id);

            if (address == null)
                return false;

            _context.Address.Remove(address);
            await _context.SaveChangesAsync();

            return true;
        }

        // Helper: Map entity to response DTO
        private AddressResponse MapToResponse(Address address) => new AddressResponse
        {
            Id = address.Id,
            UserId = address.UserId,
            Street = address.Street,
            City = address.City,
            ZipCode = address.ZipCode,
            Country = address.Country,
            IsDefault = address.IsDefault
        };
    }

}
