using RestoraNow.Model.Requests.Payments;
using RestoraNow.Model.Responses.Payments;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.Interfaces
{
    public interface IPaymentService
        : ICRUDService<PaymentResponse, PaymentSearchModel, PaymentRequest, PaymentRequest>
    {
        Task<(string ApproveUrl, string ProviderOrderId)> CreatePaypalOrderAsync(int orderId, string? currency = null);
        Task<PaymentResponse> CapturePaypalOrderAsync(string providerOrderId);
    }
}
