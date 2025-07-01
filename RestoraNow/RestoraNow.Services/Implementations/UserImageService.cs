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
    public class UserImageService : BaseCRUDService<UserImageResponse, UserImageSearchModel, UserImage, UserImageRequest>, IUserImageService
    {
        public UserImageService(ApplicationDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<UserImage> ApplyFilter(IQueryable<UserImage> query, UserImageSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(x => x.UserId == search.UserId.Value);

            return query;
        }

        protected override IQueryable<UserImage> AddInclude(IQueryable<UserImage> query)
        {
            return query.Include(x => x.User);
        }
    }
}
