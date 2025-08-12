using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class OrderItemSearchModel : BaseSearchObject
    {
        public int? OrderId { get; set; }
        public int? MenuItemId { get; set; }
    }
}