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
    public interface IMenuCategoryService
    {
        Task<IEnumerable<MenuCategoryResponse>> GetAsync(MenuCategorySearchModel search, CancellationToken cancellationToken = default);
        Task<MenuCategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
        Task<MenuCategoryResponse> InsertAsync(MenuCategoryRequest request, CancellationToken cancellationToken = default);
        Task<MenuCategoryResponse?> UpdateAsync(int id, MenuCategoryRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
