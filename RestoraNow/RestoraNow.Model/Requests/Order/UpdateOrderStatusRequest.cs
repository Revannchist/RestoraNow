using RestoraNow.Model.Enums;

namespace RestoraNow.Model.Requests.Order
{
    public class UpdateOrderStatusRequest
    {
        public OrderStatus Status { get; set; }
    }
}
