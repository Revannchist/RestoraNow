using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class TableSearchModel : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public int? Capacity { get; set; }
        public bool? IsAvailable { get; set; }
    }
}
