using RestoraNow.Model.Base;

namespace RestoraNow.Model.SearchModels
{
    public class MenuItemReviewSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? MenuItemId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
    }
}
