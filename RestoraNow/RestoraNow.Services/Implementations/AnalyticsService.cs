using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Base;
using RestoraNow.Model.Enums;
using RestoraNow.Model.Responses.Analytics;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Data;
using RestoraNow.Services.Interfaces;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System.Globalization;


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
            var from = s.From!.Value;
            var to = s.To!.Value;

            // 1) Base: per-order revenue + CreatedAt (single grouping, easy to translate)
            var baseQ =
                _db.OrderItems.AsNoTracking()
                   .Where(oi => oi.Order.Status == OrderStatus.Completed
                                && oi.Order.CreatedAt >= from
                                && oi.Order.CreatedAt <= to)
                   .GroupBy(oi => new { oi.OrderId, oi.Order.CreatedAt })
                   .Select(g => new
                   {
                       g.Key.CreatedAt,
                       Revenue = g.Sum(x => x.UnitPrice * x.Quantity)
                   });

            // 2) Grouping
            if (s.GroupBy == "month")
            {
                // Group on month index in SQL, then convert to Period client-side
                var monthRows = await baseQ
                    .GroupBy(x => EF.Functions.DateDiffMonth(DateTime.UnixEpoch, x.CreatedAt))
                    .Select(g => new { MonthIndex = g.Key, Revenue = g.Sum(x => x.Revenue) })
                    .OrderBy(x => x.MonthIndex)
                    .ToListAsync();

                return monthRows.Select(x =>
                {
                    var dt = DateTime.UnixEpoch.AddMonths(x.MonthIndex);
                    return new RevenueByPeriodResponse
                    {
                        Period = new DateTime(dt.Year, dt.Month, 1),
                        Revenue = x.Revenue
                    };
                });
            }

            if (s.GroupBy == "week")
            {
                var weekRows = await baseQ
                    .GroupBy(x => EF.Functions.DateDiffWeek(DateTime.UnixEpoch, x.CreatedAt))
                    .Select(g => new { WeekIndex = g.Key, Revenue = g.Sum(x => x.Revenue) })
                    .OrderBy(x => x.WeekIndex)
                    .ToListAsync();

                return weekRows.Select(x => new RevenueByPeriodResponse
                {
                    Period = DateTime.UnixEpoch.AddDays(x.WeekIndex * 7),
                    Revenue = x.Revenue
                });
            }

            // default: day
            return await baseQ
                .GroupBy(x => x.CreatedAt.Date)
                .Select(g => new RevenueByPeriodResponse
                {
                    Period = g.Key,
                    Revenue = g.Sum(x => x.Revenue)
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

        public async Task<byte[]> GenerateReportPdfAsync(AnalyticsSearchModel s)
        {
            Normalize(s);

            var summary = await GetSummaryAsync(s);
            var byPeriod = (await GetRevenueByPeriodAsync(s)).OrderBy(x => x.Period).ToList();
            var byCat = (await GetRevenueByCategoryAsync(s)).OrderByDescending(x => x.Revenue).ToList();
            var top = (await GetTopProductsAsync(s)).ToList();

            var culture = CultureInfo.CurrentCulture;

            var doc = Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(32);
                    page.DefaultTextStyle(x => x.FontSize(11));

                    // Header
                    page.Header().Column(col =>
                    {
                        col.Item().Text("RestoraNow – Analytics Report").SemiBold().FontSize(16);
                        col.Item().Text($"Period: {s.From:yyyy-MM-dd} → {s.To:yyyy-MM-dd}");
                        col.Item().Text($"Generated: {DateTime.Now:g}");
                    });

                    // Content
                    page.Content().Column(col =>
                    {
                        // SUMMARY
                        col.Item().PaddingBottom(4).Text("Summary").Bold().FontSize(13);
                        col.Item().Table(t =>
                        {
                            t.ColumnsDefinition(c =>
                            {
                                c.RelativeColumn();
                                c.ConstantColumn(160);
                            });

                            t.Header(h =>
                            {
                                h.Cell().PaddingVertical(4).Text("Metric").SemiBold();
                                h.Cell().PaddingVertical(4).AlignRight().Text("Value").SemiBold();
                            });

                            void Row(string k, string v)
                            {
                                t.Cell().PaddingVertical(2).Text(k);
                                t.Cell().PaddingVertical(2).AlignRight().Text(v);
                            }

                            Row("Total revenue", summary.TotalRevenue.ToString("C", culture));
                            Row("Reservations", summary.Reservations.ToString(culture));
                            Row("Average rating", summary.AvgRating.ToString("0.00", culture));
                            Row("New users", summary.NewUsers.ToString(culture));
                        });

                        // REVENUE BY PERIOD
                        col.Item().PaddingTop(12).Text("Revenue by period").Bold().FontSize(13);
                        col.Item().Table(t =>
                        {
                            t.ColumnsDefinition(c =>
                            {
                                c.RelativeColumn();   // Period
                                c.ConstantColumn(130); // Revenue
                            });

                            t.Header(h =>
                            {
                                h.Cell().PaddingVertical(4).Text("Period").SemiBold();
                                h.Cell().PaddingVertical(4).AlignRight().Text("Revenue").SemiBold();
                            });

                            foreach (var x in byPeriod)
                            {
                                t.Cell().PaddingVertical(2).Text(x.Period.ToString("yyyy-MM-dd", culture));
                                t.Cell().PaddingVertical(2).AlignRight().Text(x.Revenue.ToString("C", culture));
                            }
                        });

                        // REVENUE BY CATEGORY
                        col.Item().PaddingTop(12).Text("Revenue by category").Bold().FontSize(13);
                        col.Item().Table(t =>
                        {
                            t.ColumnsDefinition(c =>
                            {
                                c.RelativeColumn();     // Category
                                c.ConstantColumn(100);  // Share
                                c.ConstantColumn(130);  // Revenue
                            });

                            t.Header(h =>
                            {
                                h.Cell().PaddingVertical(4).Text("Category").SemiBold();
                                h.Cell().PaddingVertical(4).AlignRight().Text("Share").SemiBold();
                                h.Cell().PaddingVertical(4).AlignRight().Text("Revenue").SemiBold();
                            });

                            foreach (var c in byCat)
                            {
                                t.Cell().PaddingVertical(2).Text(c.CategoryName);
                                t.Cell().PaddingVertical(2).AlignRight().Text((c.Share * 100).ToString("0.0") + " %");
                                t.Cell().PaddingVertical(2).AlignRight().Text(c.Revenue.ToString("C", culture));
                            }
                        });

                        // TOP PRODUCTS
                        col.Item().PaddingTop(12).Text("Top products").Bold().FontSize(13);
                        col.Item().Table(t =>
                        {
                            t.ColumnsDefinition(c =>
                            {
                                c.RelativeColumn();      // Product
                                c.RelativeColumn(0.7f);  // Category
                                c.ConstantColumn(70);    // Qty
                                c.ConstantColumn(120);   // Revenue
                            });

                            t.Header(h =>
                            {
                                h.Cell().PaddingVertical(4).Text("Product").SemiBold();
                                h.Cell().PaddingVertical(4).Text("Category").SemiBold();
                                h.Cell().PaddingVertical(4).AlignRight().Text("Qty").SemiBold();
                                h.Cell().PaddingVertical(4).AlignRight().Text("Revenue").SemiBold();
                            });

                            foreach (var p in top)
                            {
                                t.Cell().PaddingVertical(2).Text(p.ProductName);
                                t.Cell().PaddingVertical(2).Text(p.CategoryName);
                                t.Cell().PaddingVertical(2).AlignRight().Text(p.SoldQty.ToString(culture));
                                t.Cell().PaddingVertical(2).AlignRight().Text(p.Revenue.ToString("C", culture));
                            }
                        });
                    });

                    // Footer
                    page.Footer().AlignCenter().Text(txt =>
                    {
                        txt.Span("Page ");
                        txt.CurrentPageNumber();
                        txt.Span(" / ");
                        txt.TotalPages();
                    });
                });
            });

            return doc.GeneratePdf();
        }

    }
}