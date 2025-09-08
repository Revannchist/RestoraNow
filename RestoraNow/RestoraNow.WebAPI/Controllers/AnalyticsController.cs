using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Responses.Analytics;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces;
using RestoraNow.WebAPI.Controllers.Base;

namespace RestoraNow.WebAPI.Controllers
{
    [Authorize(Policy = "StaffOnly")]
    public class AnalyticsController
        : BaseController<SummaryResponse, AnalyticsSearchModel>
    {
        private readonly IAnalyticsService _analytics;

        public AnalyticsController(IAnalyticsService analytics)
            : base(analytics)
        {
            _analytics = analytics;
        }

        [HttpGet("summary")]
        public async Task<ActionResult<SummaryResponse>> Summary([FromQuery] AnalyticsSearchModel search)
            => Ok(await _analytics.GetSummaryAsync(search));

        [HttpGet("revenue/by-period")]
        public async Task<ActionResult<IEnumerable<RevenueByPeriodResponse>>> RevenueByPeriod([FromQuery] AnalyticsSearchModel search)
            => Ok(await _analytics.GetRevenueByPeriodAsync(search));

        [HttpGet("revenue/by-category")]
        public async Task<ActionResult<IEnumerable<RevenueByCategoryResponse>>> RevenueByCategory([FromQuery] AnalyticsSearchModel search)
            => Ok(await _analytics.GetRevenueByCategoryAsync(search));

        [HttpGet("top-products")]
        public async Task<ActionResult<IEnumerable<TopProductResponse>>> TopProducts([FromQuery] AnalyticsSearchModel search)
            => Ok(await _analytics.GetTopProductsAsync(search));

        [HttpGet("report.pdf")]
        [Produces("application/pdf")]
        public async Task<IActionResult> DownloadReport([FromQuery] AnalyticsSearchModel search)
        {
            var pdf = await _analytics.GenerateReportPdfAsync(search);
            var fileName = $"analytics-{DateTime.UtcNow:yyyyMMdd-HHmm}.pdf";
            return File(pdf, "application/pdf", fileName);
        }

    }
}
