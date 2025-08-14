using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class UserSearchModel : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? Username { get; set; }
        public bool? IsActive { get; set; }

        public string? SortBy { get; set; }
        public bool Ascending { get; set; } = true;
    }
}
