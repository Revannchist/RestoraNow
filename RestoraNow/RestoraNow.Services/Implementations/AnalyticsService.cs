using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Base;
using RestoraNow.Model.Enums;
using RestoraNow.Model.Responses.Analytics;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Data;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.Services.Implementations
{
    public class AnalyticsService : IAnalyticsService
    {
        private readonly ApplicationDbContext _db;
        public AnalyticsService(ApplicationDbContext db) => _db = db;

        private static void Normalize(AnalyticsSearchModel s)
        {
            if (s.From == null || s.To == null)
            {
                var to = DateTime.UtcNow;
                s.From ??= to.AddDays(-6).Date; // last 7 days
                s.To ??= to;
            }
            if (s.GroupBy != "day" && s.GroupBy != "week" && s.GroupBy != "month")
                s.GroupBy = "day";
            if (s.Take is null or <= 0) s.Take = 5;
        }

        public async Task<PagedResult<SummaryResponse>> GetAsync(AnalyticsSearchModel search)
        {
            Normalize(search);
            var item = await GetSummaryAsync(search);
            return new PagedResult<SummaryResponse> { Items = new() { item }, TotalCount = 1 };
        }

        public Task<SummaryResponse?> GetByIdAsync(int id)
            => Task.FromResult<SummaryResponse?>(null);

        public async Task<SummaryResponse> GetSummaryAsync(AnalyticsSearchModel s)
        {
            Normalize(s);
            var fromDate = s.From!.Value; // UTC
            var toDate = s.To!.Value;   // UTC

            // Revenue from OrderItems
            var revenue = await _db.OrderItems.AsNoTracking()
                .Where(oi => oi.Order.Status == OrderStatus.Completed
                             && oi.Order.CreatedAt >= fromDate
                             && oi.Order.CreatedAt <= toDate)
                .SumAsync(oi => (decimal?)(oi.UnitPrice * oi.Quantity)) ?? 0m;

            // Reservations: compare date and time separately (translates fully to SQL)
            var fromD = fromDate.Date;
            var toD = toDate.Date;
            var fromT = fromDate.TimeOfDay;
            var toT = toDate.TimeOfDay;

            var reservations = await _db.Reservations.AsNoTracking().CountAsync(r =>
                // Whole days strictly inside the range
                (r.ReservationDate > fromD && r.ReservationDate < toD)
                // Start boundary day: same date, time >= from time
                || (r.ReservationDate == fromD && r.ReservationTime >= fromT)
                // End boundary day: same date, time <= to time
                || (r.ReservationDate == toD && r.ReservationTime <= toT)
                // Single-day window (from == to): both date and time within [fromT, toT]
                || (fromD == toD && r.ReservationDate == fromD
                    && r.ReservationTime >= fromT && r.ReservationTime <= toT)
            );

            var avgRating = await _db.Reviews.AsNoTracking()
                .Where(x => x.CreatedAt >= fromDate && x.CreatedAt <= toDate)
                .AverageAsync(x => (double?)x.Rating) ?? 0.0;

            var newUsers = await _db.Users.AsNoTracking()
                .CountAsync(u => u.CreatedAt >= fromDate && u.CreatedAt <= toDate);

            return new SummaryResponse
            {
                TotalRevenue = revenue,
                Reservations = reservations,
                AvgRating = Math.Round(avgRating, 2),
                NewUsers = newUsers
            };
        }

        public async Task<IEnumerable<RevenueByPeriodResponse>> GetRevenueByPeriodAsync(AnalyticsSearchModel s)
        {
            Normalize(s);
            var fromDate = s.From!.Value;
            var toDate = s.To!.Value;

            var paid = _db.Orders.AsNoTracking()
                .Where(o => o.Status == OrderStatus.Completed
                            && o.CreatedAt >= fromDate
                            && o.CreatedAt <= toDate)
                .Select(o => new { o.CreatedAt, o.Id });

            var orderRevenues = _db.OrderItems.AsNoTracking()
                .Where(oi => oi.Order.Status == OrderStatus.Completed
                             && oi.Order.CreatedAt >= fromDate
                             && oi.Order.CreatedAt <= toDate)
                .GroupBy(oi => oi.OrderId)
                .Select(g => new { OrderId = g.Key, Revenue = g.Sum(x => x.UnitPrice * x.Quantity) });

            var joined = from o in paid
                         join rev in orderRevenues on o.Id equals rev.OrderId
                         select new { o.CreatedAt, rev.Revenue };

            if (s.GroupBy == "month")
            {
                return await joined
                    .GroupBy(x => new { x.CreatedAt.Year, x.CreatedAt.Month })
                    .Select(g => new RevenueByPeriodResponse
                    {
                        Period = new DateTime(g.Key.Year, g.Key.Month, 1),
                        Revenue = g.Sum(x => (decimal)x.Revenue)
                    })
                    .OrderBy(x => x.Period)
                    .ToListAsync();
            }

            if (s.GroupBy == "week")
            {
                return await joined
                    .GroupBy(x => EF.Functions.DateDiffWeek(DateTime.UnixEpoch, x.CreatedAt))
                    .Select(g => new RevenueByPeriodResponse
                    {
                        Period = DateTime.UnixEpoch.AddDays(g.Key * 7),
                        Revenue = g.Sum(x => (decimal)x.Revenue)
                    })
                    .OrderBy(x => x.Period)
                    .ToListAsync();
            }

            return await joined
                .GroupBy(x => x.CreatedAt.Date)
                .Select(g => new RevenueByPeriodResponse
                {
                    Period = g.Key,
                    Revenue = g.Sum(x => (decimal)x.Revenue)
                })
                .OrderBy(x => x.Period)
                .ToListAsync();
        }

        public async Task<IEnumerable<RevenueByCategoryResponse>> GetRevenueByCategoryAsync(AnalyticsSearchModel s)
        {
            Normalize(s);
            var fromDate = s.From!.Value;
            var toDate = s.To!.Value;

            var q = from oi in _db.OrderItems.AsNoTracking()
                    join o in _db.Orders.AsNoTracking() on oi.OrderId equals o.Id
                    join mi in _db.MenuItem.AsNoTracking() on oi.MenuItemId equals mi.Id
                    join mc in _db.Categories.AsNoTracking() on mi.CategoryId equals mc.Id
                    where o.Status == OrderStatus.Completed
                          && o.CreatedAt >= fromDate
                          && o.CreatedAt <= toDate
                    select new { mc.Id, mc.Name, Rev = oi.UnitPrice * oi.Quantity };

            var grouped = await q.GroupBy(x => new { x.Id, x.Name })
                                 .Select(g => new { g.Key.Id, g.Key.Name, Revenue = g.Sum(x => x.Rev) })
                                 .ToListAsync();

            var total = grouped.Sum(x => x.Revenue);
            return grouped.Select(x => new RevenueByCategoryResponse
            {
                CategoryId = x.Id,
                CategoryName = x.Name,
                Revenue = x.Revenue,
                Share = total == 0 ? 0 : (double)(x.Revenue / total)
            });
        }

        public async Task<IEnumerable<TopProductResponse>> GetTopProductsAsync(AnalyticsSearchModel s)
        {
            Normalize(s);
            var from = s.From!.Value;
            var to = s.To!.Value;
            var take = s.Take!.Value;

            return await _db.OrderItems.AsNoTracking()
                .Where(oi => oi.Order.CreatedAt >= from && oi.Order.CreatedAt <= to && oi.Order.Status == OrderStatus.Completed)
                .GroupBy(oi => new { oi.MenuItemId, oi.MenuItem.Name, Category = oi.MenuItem.Category.Name })
                .Select(g => new TopProductResponse
                {
                    MenuItemId = g.Key.MenuItemId,
                    ProductName = g.Key.Name,
                    CategoryName = g.Key.Category,
                    SoldQty = g.Sum(x => x.Quantity),
                    Revenue = g.Sum(x => x.UnitPrice * x.Quantity)
                })
                .OrderByDescending(x => x.Revenue)
                .ThenByDescending(x => x.SoldQty)
                .Take(take)
                .ToListAsync();
        }
    }
}