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
    public class UserImageService
        : BaseCRUDService<UserImageResponse, UserImageSearchModel, UserImage, UserImageRequest, UserImageRequest>,
          IUserImageService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public UserImageService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
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
            var user = await _context.Users.Include(u => u.Image).FirstOrDefaultAsync(u => u.Id == request.UserId);
            if (user == null)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            // Remove old image if it exists
            if (user.Image != null)
            {
                _context.UserImages.Remove(user.Image);
            }

            // Create and assign new image
            var entity = _mapper.Map<UserImage>(request);
            _context.UserImages.Add(entity);

            user.Image = entity;

            await _context.SaveChangesAsync();
            return _mapper.Map<UserImageResponse>(entity);
        }

        public override async Task<UserImageResponse?> UpdateAsync(int id, UserImageRequest request)
        {
            var image = await _context.UserImages.Include(i => i.User).FirstOrDefaultAsync(i => i.Id == id);
            if (image == null)
                throw new KeyNotFoundException($"User image with ID {id} was not found.");

            if (image.UserId != request.UserId)
                throw new InvalidOperationException("Cannot reassign image to a different user.");

            _mapper.Map(request, image);
            await _context.SaveChangesAsync();

            return _mapper.Map<UserImageResponse>(image);
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
            var image = await _context.UserImages.Include(i => i.User).FirstOrDefaultAsync(i => i.Id == id);
            if (image == null)
                throw new KeyNotFoundException($"User image with ID {id} was not found.");

            if (image.User != null)
            {
                image.User.Image = null; // Unlink from user
            }

            _context.UserImages.Remove(image);
            await _context.SaveChangesAsync();
            return true;
        }

        //Mobile

        public async Task<UserImageResponse> UpsertByUserIdAsync(int userId, string url)
        {
            return await InsertAsync(new UserImageRequest { UserId = userId, Url = url });
        }

        public async Task<bool> DeleteByUserIdAsync(int userId)
        {
            var existing = await _context.UserImages
                .Include(i => i.User)
                .Where(i => i.UserId == userId)
                .ToListAsync();

            if (existing.Count == 0) return false;

            foreach (var img in existing)
            {
                if (img.User != null) img.User.Image = null;
                _context.UserImages.Remove(img);
            }
            await _context.SaveChangesAsync();
            return true;
        }

    }
}
