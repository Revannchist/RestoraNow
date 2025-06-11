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
    public interface IOrderService
    {
        Task<IEnumerable<OrderResponse>> GetAsync(OrderSearchModel search, CancellationToken cancellationToken = default);
        Task<OrderResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
        Task<OrderResponse> InsertAsync(OrderRequest request, CancellationToken cancellationToken = default);
        Task<OrderResponse?> UpdateAsync(int id, OrderRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
