using RestoraNow.Model.Responses.Analytics;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.Services.Interfaces
{
    public interface IAnalyticsService : IService<SummaryResponse, AnalyticsSearchModel>
    {
        Task<SummaryResponse> GetSummaryAsync(AnalyticsSearchModel s);
        Task<IEnumerable<RevenueByPeriodResponse>> GetRevenueByPeriodAsync(AnalyticsSearchModel s);
        Task<IEnumerable<RevenueByCategoryResponse>> GetRevenueByCategoryAsync(AnalyticsSearchModel s);
        Task<IEnumerable<TopProductResponse>> GetTopProductsAsync(AnalyticsSearchModel s);
    }
}