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
    public interface IMenuItemService
    {
        Task<IEnumerable<MenuItemResponse>> GetAsync(MenuItemSearchModel search, CancellationToken cancellationToken = default);
        Task<MenuItemResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
        Task<MenuItemResponse> InsertAsync(MenuItemRequest request, CancellationToken cancellationToken = default);
        Task<MenuItemResponse?> UpdateAsync(int id, MenuItemRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
