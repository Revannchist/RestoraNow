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
        Task<IEnumerable<AddressResponse>> GetAsync(AddressSearchModel search);
        Task<AddressResponse?> GetByIdAsync(int id);
        Task<AddressResponse> InsertAsync(AddressRequest request);
        Task<AddressResponse?> UpdateAsync(int id, AddressRequest request);
        Task<bool> DeleteAsync(int id);
    }

}
