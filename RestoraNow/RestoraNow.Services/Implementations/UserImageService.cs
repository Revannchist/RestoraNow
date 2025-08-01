using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.Services.Implementations
{
    public class UserImageService : BaseCRUDService<UserImageResponse, UserImageSearchModel, UserImage, UserImageRequest, UserImageRequest>, IUserImageService
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

        public override async Task<UserImageResponse> InsertAsync(UserImageRequest request)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            return await base.InsertAsync(request);
        }

        public override async Task<UserImageResponse?> UpdateAsync(int id, UserImageRequest request)
        {
            var entity = await _context.UserImages.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"User image with ID {id} was not found.");

            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<UserImageResponse>(entity);
        }

        public override async Task<UserImageResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.UserImages.Include(x => x.User).FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null)
                throw new KeyNotFoundException($"User image with ID {id} was not found.");

            return _mapper.Map<UserImageResponse>(entity);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.UserImages.FindAsync(id);
            if (entity == null)
                throw new KeyNotFoundException($"User image with ID {id} was not found.");

            _context.UserImages.Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
