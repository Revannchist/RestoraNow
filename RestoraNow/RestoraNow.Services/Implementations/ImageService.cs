using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using MapsterMapper;

namespace RestoraNow.Services.Implementations
{
    public class ImageService : IImageService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public ImageService(ApplicationDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<IEnumerable<ImageResponse>> GetAsync(ImageSearchModel search, CancellationToken cancellationToken = default)
        {
            var query = _context.Images
                .AsNoTracking()
                .Include(i => i.User)
                .Include(i => i.MenuItem)
                .AsQueryable();

            if (search.MenuItemId.HasValue)
                query = query.Where(i => i.MenuItemId == search.MenuItemId);

            if (search.UserId.HasValue)
                query = query.Where(i => i.UserId == search.UserId);

            var result = await query.ToListAsync(cancellationToken);

            return result.Select(i => new ImageResponse
            {
                Id = i.Id,
                Url = i.Url,
                Description = i.Description,
                MenuItemId = i.MenuItemId,
                MenuItemName = i.MenuItem?.Name,
                UserId = i.UserId,
                Username = i.User?.Username
            });
        }

        public async Task<ImageResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var image = await _context.Images
                .Include(i => i.User)
                .Include(i => i.MenuItem)
                .AsNoTracking()
                .FirstOrDefaultAsync(i => i.Id == id, cancellationToken);

            return image == null ? null : _mapper.Map<ImageResponse>(image);
        }

        public async Task<ImageResponse> InsertAsync(ImageRequest request, CancellationToken cancellationToken = default)
        {
            var image = _mapper.Map<Image>(request);
            _context.Images.Add(image);
            await _context.SaveChangesAsync(cancellationToken);

            image = await _context.Images
                .Include(i => i.User)
                .Include(i => i.MenuItem)
                .FirstOrDefaultAsync(i => i.Id == image.Id, cancellationToken);

            return _mapper.Map<ImageResponse>(image!);
        }

        public async Task<ImageResponse?> UpdateAsync(int id, ImageRequest request, CancellationToken cancellationToken = default)
        {
            var image = await _context.Images.FindAsync(new object[] { id }, cancellationToken);
            if (image == null)
                return null;

            _mapper.Map(request, image);
            await _context.SaveChangesAsync(cancellationToken);

            image = await _context.Images
                .Include(i => i.User)
                .Include(i => i.MenuItem)
                .FirstOrDefaultAsync(i => i.Id == id, cancellationToken);

            return _mapper.Map<ImageResponse>(image!);
        }

        public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
        {
            var image = await _context.Images.FindAsync(new object[] { id }, cancellationToken);
            if (image == null)
                return false;

            _context.Images.Remove(image);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}
