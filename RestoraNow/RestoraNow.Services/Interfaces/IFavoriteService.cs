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
    public interface IFavoriteService
    {
        Task<IEnumerable<FavoriteResponse>> GetAsync(FavoriteSearchModel search, CancellationToken cancellationToken = default);
        Task<FavoriteResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
        Task<FavoriteResponse> InsertAsync(FavoriteRequest request, CancellationToken cancellationToken = default);
        Task<FavoriteResponse?> UpdateAsync(int id, FavoriteRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
