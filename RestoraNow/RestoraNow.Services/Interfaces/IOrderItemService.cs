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
    public interface IOrderItemService
    {
        Task<IEnumerable<OrderItemResponse>> GetAsync(OrderItemSearchModel search, CancellationToken cancellationToken = default);
        Task<OrderItemResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
        Task<OrderItemResponse> InsertAsync(OrderItemRequest request, CancellationToken cancellationToken = default);
        Task<OrderItemResponse?> UpdateAsync(int id, OrderItemRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
