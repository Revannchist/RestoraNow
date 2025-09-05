using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;

namespace RestoraNow.Services.Recommendations
{
    /// <summary>
    /// Content-based recommender for MenuItems using ML.NET text featurization.
    /// Builds a feature vector per MenuItem from (Name, CategoryName, Description),
    /// builds a user profile from Orders (+quantity) and Reviews (+rating),
    /// and ranks available items by cosine similarity to the profile.
    /// Cold-start: specials -> top-rated -> any available.
    /// </summary>
    public class MenuRecommendationService : IMenuRecommendationService
    {
        private static readonly object _sync = new();
        private static MLContext _ml;
        private static Dictionary<int, float[]> _itemVectors; // MenuItemId -> vector

        private readonly ApplicationDbContext _db;

        public MenuRecommendationService(ApplicationDbContext db)
        {
            _db = db;
            BuildModelIfNeeded();
        }

        public async Task<IReadOnlyList<MenuItem>> RecommendAsync(
            int userId,
            int take = 10,
            CancellationToken ct = default)
        {
            if (_itemVectors == null || _itemVectors.Count == 0)
                return await ColdStartAsync(take, ct);

            if (userId <= 0)
                return await ColdStartAsync(take, ct);

            // ---- Gather interactions (weights) ----
            var weights = new Dictionary<int, float>();

            // Reviews
            var myReviews = await _db.Set<MenuItemReview>()
                .Where(r => r.UserId == userId)
                .Select(r => new { r.MenuItemId, r.Rating })
                .ToListAsync(ct);

            foreach (var r in myReviews)
            {
                if (_itemVectors.ContainsKey(r.MenuItemId))
                {
                    var w = Math.Clamp(r.Rating, 1, 5) / 5f; // 0.2 .. 1.0
                    weights[r.MenuItemId] = weights.GetValueOrDefault(r.MenuItemId) + 2f * w;
                }
            }

            // Orders (adjust to your schema if needed)
            var myOrderItems = await _db.Set<OrderItem>()
                .Where(oi => oi.Order.UserId == userId)
                .Select(oi => new { oi.MenuItemId, oi.Quantity })
                .ToListAsync(ct);

            foreach (var oi in myOrderItems)
            {
                if (_itemVectors.ContainsKey(oi.MenuItemId))
                {
                    var w = Math.Max(1f, oi.Quantity);
                    weights[oi.MenuItemId] = weights.GetValueOrDefault(oi.MenuItemId) + w;
                }
            }

            if (weights.Count == 0)
                return await ColdStartAsync(take, ct);

            // ---- Profile and scoring ----
            var profile = WeightedAverage(weights);

            var exclude = weights.Keys.ToHashSet();
            var candidateIds = await _db.Set<MenuItem>()
                .Where(m => m.IsAvailable)
                .Select(m => m.Id)
                .ToListAsync(ct);

            var scored = new List<(int Id, float Score)>(candidateIds.Count);
            foreach (var id in candidateIds)
            {
                if (exclude.Contains(id)) continue;
                if (!_itemVectors.TryGetValue(id, out var v)) continue;
                scored.Add((id, Cosine(profile, v)));
            }

            var topIds = scored
                .OrderByDescending(t => t.Score)
                .Take(take)
                .Select(t => t.Id)
                .ToList();

            if (topIds.Count == 0)
                return await ColdStartAsync(take, ct);

            var items = await _db.Set<MenuItem>()
                .Where(m => topIds.Contains(m.Id))
                .ToListAsync(ct);

            // Preserve ranking
            return topIds.Select(id => items.First(m => m.Id == id)).ToList();
        }

        // ---------------- model build ----------------
        private void BuildModelIfNeeded()
        {
            if (_itemVectors != null) return;

            lock (_sync)
            {
                if (_itemVectors != null) return;

                _ml = new MLContext(seed: 1);

                var rows = LoadItemRows();
                if (rows.Count == 0)
                {
                    _itemVectors = new Dictionary<int, float[]>();
                    return;
                }

                var data = _ml.Data.LoadFromEnumerable(rows);

                var pipeline =
                    _ml.Transforms.Text.FeaturizeText("NameFeats", nameof(ItemRow.Name))
                    .Append(_ml.Transforms.Text.FeaturizeText("CatFeats", nameof(ItemRow.Category)))
                    .Append(_ml.Transforms.Text.FeaturizeText("DescFeats", nameof(ItemRow.Description)))
                    .Append(_ml.Transforms.Concatenate("Features", "NameFeats", "CatFeats", "DescFeats"))
                    .Append(_ml.Transforms.NormalizeLpNorm("Features"));

                var model = pipeline.Fit(data);
                var transformed = model.Transform(data);

                var vectors = _ml.Data.CreateEnumerable<VectorRow>(transformed, reuseRowObject: false);
                _itemVectors = vectors.ToDictionary(v => v.MenuItemId, v => v.Features);
            }
        }

        private List<ItemRow> LoadItemRows()
            => _db.Set<MenuItem>()
                  .Include(m => m.Category)
                  .AsNoTracking()
                  .Select(m => new ItemRow
                  {
                      MenuItemId = m.Id,
                      Name = m.Name ?? "",
                      Category = (m.Category != null ? m.Category.Name : (m.Name ?? "")),
                      Description = m.Description ?? ""
                  })
                  .ToList();

        private async Task<List<MenuItem>> ColdStartAsync(int take, CancellationToken ct)
        {
            var specials = await _db.Set<MenuItem>()
                .Where(m => m.IsAvailable && m.IsSpecialOfTheDay)
                .OrderBy(m => m.Name)
                .Take(take)
                .ToListAsync(ct);
            if (specials.Count >= take) return specials;

            var missing = take - specials.Count;

            var topRated = await _db.Set<MenuItemReview>()
                .GroupBy(r => r.MenuItemId)
                .Select(g => new { MenuItemId = g.Key, Avg = g.Average(x => x.Rating), Cnt = g.Count() })
                .OrderByDescending(x => x.Avg)
                .ThenByDescending(x => x.Cnt)
                .Take(missing * 2)
                .ToListAsync(ct);

            var topIds = topRated.Select(x => x.MenuItemId).ToHashSet();

            var topRatedItems = await _db.Set<MenuItem>()
                .Where(m => m.IsAvailable && topIds.Contains(m.Id))
                .OrderBy(m => m.Name)
                .Take(missing)
                .ToListAsync(ct);

            var result = specials.Concat(topRatedItems).ToList();
            if (result.Count >= take) return result;

            var fill = await _db.Set<MenuItem>()
                .Where(m => m.IsAvailable)
                .OrderBy(m => m.Name)
                .Take(take - result.Count)
                .ToListAsync(ct);

            result.AddRange(fill);
            return result;
        }

        private static float[] WeightedAverage(Dictionary<int, float> weights)
        {
            var firstId = weights.Keys.First();
            if (!_itemVectors.TryGetValue(firstId, out var first)) return Array.Empty<float>();

            var sum = new float[first.Length];
            float wsum = 0;

            foreach (var (id, w) in weights)
            {
                if (!_itemVectors.TryGetValue(id, out var v)) continue;
                for (int i = 0; i < v.Length; i++) sum[i] += v[i] * w;
                wsum += w;
            }

            if (wsum > 1e-6f)
                for (int i = 0; i < sum.Length; i++) sum[i] /= wsum;

            return sum;
        }

        private static float Cosine(float[] a, float[] b)
        {
            if (a == null || b == null || a.Length == 0 || b.Length == 0) return 0f;

            float dot = 0, ma = 0, mb = 0;
            var n = Math.Min(a.Length, b.Length);
            for (int i = 0; i < n; i++)
            {
                dot += a[i] * b[i];
                ma += a[i] * a[i];
                mb += b[i] * b[i];
            }

            const float eps = 1e-6f;
            return dot / (MathF.Sqrt(ma) * MathF.Sqrt(mb) + eps);
        }

        // --- ML.NET row types ---
        private class ItemRow
        {
            public int MenuItemId { get; set; }
            public string Name { get; set; }
            public string Category { get; set; }
            public string Description { get; set; }
        }

        private class VectorRow
        {
            public int MenuItemId { get; set; }

            [VectorType]
            public float[] Features { get; set; }
        }
    }
}
