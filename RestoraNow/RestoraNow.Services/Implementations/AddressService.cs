using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using MapsterMapper;
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
        private readonly IMapper _mapper;

        public AddressService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<AddressResponse>> GetAsync(AddressSearchModel search, CancellationToken cancellationToken = default)
        {
            // Base query
            IQueryable<Address> query = _context.Address.AsNoTracking();

            // Filtering (example)
            if (search.UserId.HasValue)
                query = query.Where(a => a.UserId == search.UserId.Value);
            if (!string.IsNullOrWhiteSpace(search.City))
                query = query.Where(a => a.City.Contains(search.City));

            var addresses = await query.ToListAsync(cancellationToken);
            return _mapper.Map<IEnumerable<AddressResponse>>(addresses);
        }

        public async Task<AddressResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var address = await _context.Address
                .AsNoTracking()
                .FirstOrDefaultAsync(a => a.Id == id, cancellationToken);

            return address == null ? null : _mapper.Map<AddressResponse>(address);
        }

        public async Task<AddressResponse> InsertAsync(AddressRequest request, CancellationToken cancellationToken = default)
        {
            var address = _mapper.Map<Address>(request);

            _context.Address.Add(address);
            await _context.SaveChangesAsync(cancellationToken);

            return _mapper.Map<AddressResponse>(address);
        }

        public async Task<AddressResponse?> UpdateAsync(int id, AddressRequest request, CancellationToken cancellationToken = default)
        {
            var address = await _context.Address.FindAsync(new object[] { id }, cancellationToken);
            if (address == null)
                return null;

            _mapper.Map(request, address);
            await _context.SaveChangesAsync(cancellationToken);

            return _mapper.Map<AddressResponse>(address);
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var address = await _context.Address.FindAsync(new object[] { id }, cancellationToken);
            if (address == null)
                return false;

            _context.Address.Remove(address);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}