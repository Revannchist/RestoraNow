using MapsterMapper;
using Microsoft.AspNetCore.Identity;
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
using System.Threading.Tasks;

namespace RestoraNow.Services.Implementations
{
    public class UserService : BaseCRUDService<UserResponse, UserSearchModel, User, UserRequest>, IUserService
    {
        private readonly UserManager<User> _userManager;
        private readonly ApplicationDbContext _context;
        private readonly IMapper _mapper;

        public UserService(
            ApplicationDbContext context,
            IMapper mapper,
            UserManager<User> userManager)
            : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _userManager = userManager;
        }

        protected override IQueryable<User> AddInclude(IQueryable<User> query)
        {
            return query.Include(x => x.Images);
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchModel search)
        {
            if (!string.IsNullOrWhiteSpace(search.Name))
                query = query.Where(u => u.FirstName.Contains(search.Name) || u.LastName.Contains(search.Name));

            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            return query;
        }

        public override async Task<UserResponse> InsertAsync(UserRequest request)
        {
            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                UserName = request.Email, // Required by Identity; can be same as Email
                PhoneNumber = request.PhoneNumber,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                throw new Exception($"User creation failed: {string.Join(", ", result.Errors.Select(e => e.Description))}");
            }

            // Optionally assign roles from request (if UserRequest includes roles)
            if (request.Roles != null && request.Roles.Any())
            {
                var roleResult = await _userManager.AddToRolesAsync(user, request.Roles);
                if (!roleResult.Succeeded)
                {
                    throw new Exception($"Failed to assign roles: {string.Join(", ", roleResult.Errors.Select(e => e.Description))}");
                }
            }

            return _mapper.Map<UserResponse>(user);
        }
    }
}