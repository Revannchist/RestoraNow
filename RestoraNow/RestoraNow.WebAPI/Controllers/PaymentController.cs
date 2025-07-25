using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

public class PaymentController : BaseCRUDController<PaymentResponse, PaymentSearchModel, PaymentRequest, PaymentRequest>
{
    public PaymentController(IPaymentService service) : base(service) { }
}
