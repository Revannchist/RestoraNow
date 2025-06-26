using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class MenuCategorySearchModel : BaseSearchObject
    {
        public string? Name { get; set; }
        public bool? IsActive { get; set; }
    }
}
