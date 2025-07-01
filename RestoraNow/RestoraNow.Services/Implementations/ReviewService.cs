using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Implementations
{
    public class ReviewService
        : BaseCRUDService<ReviewResponse, ReviewSearchModel, Review, ReviewRequest>,
          IReviewService
    {
        public ReviewService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);
            if (search.RestaurantId.HasValue)
                query = query.Where(r => r.RestaurantId == search.RestaurantId.Value);
            if (search.MinRating.HasValue)
                query = query.Where(r => r.Rating >= search.MinRating.Value);
            if (search.MaxRating.HasValue)
                query = query.Where(r => r.Rating <= search.MaxRating.Value);

            return query;
        }

        protected override IQueryable<Review> AddInclude(IQueryable<Review> query)
        {
            return query.Include(r => r.User)
                        .Include(r => r.Restaurant);
        }
    }
}
