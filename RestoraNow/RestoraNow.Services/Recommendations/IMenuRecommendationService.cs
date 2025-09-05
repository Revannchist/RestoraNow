using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using RestoraNow.Services.Entities;

namespace RestoraNow.Services.Recommendations
{
    public interface IMenuRecommendationService
    {
        /// <summary>
        /// Returns recommended MenuItems for a user.
        /// If userId == 0 or has no interactions, returns a cold-start list.
        /// </summary>
        Task<IReadOnlyList<MenuItem>> RecommendAsync(
            int userId,
            int take = 10,
            CancellationToken ct = default);
    }
}
