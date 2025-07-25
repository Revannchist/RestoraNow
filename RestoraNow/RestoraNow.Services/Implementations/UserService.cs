using MapsterMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Base;
using RestoraNow.Model.Requests.User;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;

namespace RestoraNow.Services.Implementations
{
    public class UserService : BaseCRUDService<UserResponse, UserSearchModel, User, UserCreateRequest, UserUpdateRequest>, IUserService
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

        // Helper method to add roles to UserResponse after mapping
        private async Task<UserResponse> AddRolesToUserResponse(User user)
        {
            var userResponse = _mapper.Map<UserResponse>(user);
            var roles = await _userManager.GetRolesAsync(user);
            userResponse.Roles = roles.ToList();
            return userResponse;
        }

        public override async Task<UserResponse> InsertAsync(UserCreateRequest request)
        {
            // Validate: Email already in use
            var existingByEmail = await _userManager.FindByEmailAsync(request.Email);
            if (existingByEmail != null)
                throw new Exception("A user with the given email already exists."); //This response message is not triggering

            // Validate: Phone number already in use
            var existingByPhone = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.PhoneNumber == request.PhoneNumber);
            if (existingByPhone != null)
                throw new Exception("A user with the given phone number already exists.");  //same thing with phone number
                                                                                           // it seems to crash with error 500, 
            // (Optional) Validate: roles exist
            if (request.Roles != null && request.Roles.Any())
            {
                var roleErrors = new List<string>();
                foreach (var role in request.Roles)
                {
                    if (!await _context.Roles.AnyAsync(r => r.Name == role))
                    {
                        roleErrors.Add($"Role '{role}' does not exist.");
                    }
                }

                if (roleErrors.Any())
                    throw new Exception($"Invalid roles: {string.Join(", ", roleErrors)}");
            }

            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                UserName = request.Email, // Required by Identity
                PhoneNumber = request.PhoneNumber,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                throw new Exception($"User creation failed: {string.Join(", ", result.Errors.Select(e => e.Description))}"); //same here?
            }

            // Assign roles from request if specified
            if (request.Roles != null && request.Roles.Any())
            {
                var roleResult = await _userManager.AddToRolesAsync(user, request.Roles);
                if (!roleResult.Succeeded)
                {
                    throw new Exception($"Failed to assign roles: {string.Join(", ", roleResult.Errors.Select(e => e.Description))}");
                }
            }
            else
            {
                var defaultRoleResult = await _userManager.AddToRoleAsync(user, "Customer");
                if (!defaultRoleResult.Succeeded)
                {
                    throw new Exception($"Failed to assign default role 'Customer': {string.Join(", ", defaultRoleResult.Errors.Select(e => e.Description))}");
                }
            }


            var userResponse = _mapper.Map<UserResponse>(user);
            var roles = await _userManager.GetRolesAsync(user);
            userResponse.Roles = roles.ToList();

            return userResponse;
        }

        public override async Task<UserResponse?> UpdateAsync(int id, UserUpdateRequest request)
        {
            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user == null)
                return null;

            // Only update fields that are provided (not null)
            if (request.FirstName != null)
                user.FirstName = request.FirstName;

            if (request.LastName != null)
                user.LastName = request.LastName;

            if (request.Email != null && request.Email != user.Email)
            {
                user.Email = request.Email;
                user.UserName = request.Email; // Keep UserName in sync with Email
            }

            if (request.PhoneNumber != null)
                user.PhoneNumber = request.PhoneNumber;

            if (request.IsActive.HasValue)
                user.IsActive = request.IsActive.Value;

            // Handle password update if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                var token = await _userManager.GeneratePasswordResetTokenAsync(user);
                var passwordResult = await _userManager.ResetPasswordAsync(user, token, request.Password);
                if (!passwordResult.Succeeded)
                {
                    throw new Exception($"Password update failed: {string.Join(", ", passwordResult.Errors.Select(e => e.Description))}");
                }
            }

            // Handle roles update if provided
            if (request.Roles != null)
            {
                var currentRoles = await _userManager.GetRolesAsync(user);
                var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
                if (!removeResult.Succeeded)
                {
                    throw new Exception($"Failed to remove existing roles: {string.Join(", ", removeResult.Errors.Select(e => e.Description))}");
                }

                if (request.Roles.Any())
                {
                    var addResult = await _userManager.AddToRolesAsync(user, request.Roles);
                    if (!addResult.Succeeded)
                    {
                        throw new Exception($"Failed to assign new roles: {string.Join(", ", addResult.Errors.Select(e => e.Description))}");
                    }
                }
            }

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
            {
                throw new Exception($"User update failed: {string.Join(", ", updateResult.Errors.Select(e => e.Description))}");
            }

            var userResponse = _mapper.Map<UserResponse>(user);
            // Include updated roles in the response
            var roles = await _userManager.GetRolesAsync(user);
            userResponse.Roles = roles.ToList();

            return userResponse;
        }

        public override async Task<UserResponse?> GetByIdAsync(int id)
        {
            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user == null) return null;

            // Include Images if needed
            await _context.Entry(user)
                .Collection(u => u.Images)
                .LoadAsync();

            var userResponse = _mapper.Map<UserResponse>(user);
            // Get roles using UserManager and convert to List<string>
            var roles = await _userManager.GetRolesAsync(user);
            userResponse.Roles = roles.ToList();

            return userResponse;
        }

        public override async Task<PagedResult<UserResponse>> GetAsync(UserSearchModel search)
        {
            IQueryable<User> query = _context.Set<User>().AsNoTracking();
            query = AddInclude(query);
            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                    query = query.Skip(search.Page.Value * search.PageSize ?? 10);
                if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }

            var users = await query.ToListAsync();

            // Map users and add roles
            var userResponses = new List<UserResponse>();
            foreach (var user in users)
            {
                var userResponse = await AddRolesToUserResponse(user);
                userResponses.Add(userResponse);
            }

            return new PagedResult<UserResponse>
            {
                Items = userResponses,
                TotalCount = totalCount
            };
        }
    }
}