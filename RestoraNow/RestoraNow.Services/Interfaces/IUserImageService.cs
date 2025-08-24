using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.Interfaces
{
    public interface IUserImageService : ICRUDService<UserImageResponse, UserImageSearchModel, UserImageRequest, UserImageRequest>
    {
        Task<UserImageResponse> UpsertByUserIdAsync(int userId, string url);
        Task<bool> DeleteByUserIdAsync(int userId);
    }
}
