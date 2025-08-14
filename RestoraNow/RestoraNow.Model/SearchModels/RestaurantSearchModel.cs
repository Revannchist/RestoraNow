using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class RestaurantSearchModel : BaseSearchObject
    {
        public string? Name { get; set; }
        public bool? IsActive { get; set; }
    }
}