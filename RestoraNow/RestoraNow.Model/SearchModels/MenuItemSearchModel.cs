using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class MenuItemSearchModel : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CategoryId { get; set; }
        public bool? IsAvailable { get; set; }
        public bool? IsSpecialOfTheDay { get; set; }
    }
}
