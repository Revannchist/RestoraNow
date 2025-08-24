using RestoraNow.Model.Requests.Mobile.User;
using RestoraNow.Model.Requests.User;
using RestoraNow.Model.Responses;
using RestoraNow.Model.Responses.Mobile.User;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.Interfaces
{
    public interface IUserService : ICRUDService<UserResponse, UserSearchModel, UserCreateRequest, UserUpdateRequest>
    {
        Task<MeResponse> GetMeAsync(int userId);
        Task<MeResponse> UpdateMeAsync(int userId, MeUpdateRequest request);
        Task ChangePasswordAsync(int userId, string currentPassword, string newPassword);
        Task BeginChangeEmailAsync(int userId, string newEmail, string? currentPassword);
    }
}
