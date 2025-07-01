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
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Implementations
{
    public class UserService
        : BaseCRUDService<UserResponse, UserSearchModel, User, UserRequest>, IUserService
    {
        public UserService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<User> AddInclude(IQueryable<User> query)
        {
            return query
                .Include(x => x.UserRoles).ThenInclude(ur => ur.Role)
                .Include(x => x.Images);
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchModel search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(u => u.FirstName.Contains(search.Name) || u.LastName.Contains(search.Name));

            if (!string.IsNullOrWhiteSpace(search.Username))
                query = query.Where(u => u.Username.Contains(search.Username));

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            return query;
        }

        public override async Task<UserResponse> InsertAsync(UserRequest request)
        {
            var salt = GenerateSalt();
            var hash = HashPassword(request.Password, salt);

            var entity = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                Username = request.Username,
                PasswordHash = hash,
                PasswordSalt = salt,
                PhoneNumber = request.PhoneNumber,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<UserResponse>(entity);
        }

        private string GenerateSalt()
        {
            byte[] saltBytes = new byte[16];
            using var provider = RandomNumberGenerator.Create();
            provider.GetBytes(saltBytes);
            return Convert.ToBase64String(saltBytes);
        }

        private string HashPassword(string password, string salt)
        {
            var combined = Encoding.UTF8.GetBytes(password + salt);
            using var sha256 = SHA256.Create();
            var hashBytes = sha256.ComputeHash(combined);
            return Convert.ToBase64String(hashBytes);
        }
    }
}
