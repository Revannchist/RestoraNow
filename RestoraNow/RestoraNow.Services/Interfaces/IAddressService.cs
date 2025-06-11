using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Interfaces
{
    public interface IAddressService
    {
        Task<IEnumerable<AddressResponse>> GetAsync(AddressSearchModel search, CancellationToken cancellationToken = default);
        Task<AddressResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
        Task<AddressResponse> InsertAsync(AddressRequest request, CancellationToken cancellationToken = default);
        Task<AddressResponse?> UpdateAsync(int id, AddressRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }

}