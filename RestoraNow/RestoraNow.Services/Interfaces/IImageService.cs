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
    public interface IImageService
    {
        Task<IEnumerable<ImageResponse>> GetAsync(ImageSearchModel search, CancellationToken cancellationToken = default);
        Task<ImageResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
        Task<ImageResponse> InsertAsync(ImageRequest request, CancellationToken cancellationToken = default);
        Task<ImageResponse?> UpdateAsync(int id, ImageRequest request, CancellationToken cancellationToken = default);
        Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
    }
}
