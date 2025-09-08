using MapsterMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Base;
using RestoraNow.Model.Requests.Mobile.User;
using RestoraNow.Model.Requests.User;
using RestoraNow.Model.Responses;
using RestoraNow.Model.Responses.Mobile.User;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using System.ComponentModel.DataAnnotations;

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
            return query.Include(x => x.Image);
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchModel search)
        {
            // Active flag
            if (search.IsActive.HasValue)
                query = query.Where(u => u.IsActive == search.IsActive.Value);

            var hasName = !string.IsNullOrWhiteSpace(search.Name);
            var hasUser = !string.IsNullOrWhiteSpace(search.Username);

            if (hasName || hasUser)
            {
                var name = search.Name?.Trim();
                var user = search.Username?.Trim();

                // Pre-split name into parts for "first last"
                string? p1 = null, p2 = null;
                if (!string.IsNullOrEmpty(name))
                {
                    var parts = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length >= 2) { p1 = parts[0]; p2 = parts[1]; }
                }

                query = query.Where(u =>
                    // ---- NAME branch (First / Last / "First Last" either order) ----
                    (hasName && (
                        EF.Functions.Like(u.FirstName, $"%{name}%") ||
                        EF.Functions.Like(u.LastName, $"%{name}%") ||
                        (u.FirstName != null && u.LastName != null &&
                         EF.Functions.Like(u.FirstName + " " + u.LastName, $"%{name}%")) ||
                        (p1 != null && p2 != null && (
                            (EF.Functions.Like(u.FirstName, $"%{p1}%") && EF.Functions.Like(u.LastName, $"%{p2}%")) ||
                            (EF.Functions.Like(u.FirstName, $"%{p2}%") && EF.Functions.Like(u.LastName, $"%{p1}%"))
                        ))
                    ))
                    ||
                    // ---- USER branch (username OR email) ----
                    (hasUser && (
                        (u.UserName != null && EF.Functions.Like(u.UserName, $"%{user}%")) ||
                        (u.Email != null && EF.Functions.Like(u.Email, $"%{user}%"))
                    ))
                );
            }

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
            // Normalize: empty/whitespace -> null
            var phone = string.IsNullOrWhiteSpace(request.PhoneNumber)
                ? null
                : request.PhoneNumber.Trim();

            // Email duplicate check
            var existingByEmail = await _userManager.FindByEmailAsync(request.Email);
            if (existingByEmail != null)
                throw new ValidationException("A user with the given email already exists.");

            // Phone duplicate check ONLY if provided
            if (phone != null)
            {
                var phoneExists = await _context.Users
                    .AsNoTracking()
                    .AnyAsync(u => u.PhoneNumber == phone);

                if (phoneExists)
                    throw new ValidationException("A user with the given phone number already exists.");
            }

            // Validate roles exist (unchanged)
            if (request.Roles != null && request.Roles.Any())
            {
                var roleErrors = new List<string>();
                foreach (var role in request.Roles)
                    if (!await _context.Roles.AnyAsync(r => r.Name == role))
                        roleErrors.Add($"Role '{role}' does not exist.");

                if (roleErrors.Any())
                    throw new ValidationException($"Invalid roles: {string.Join(", ", roleErrors)}");
            }

            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Email = request.Email,
                UserName = request.Email, // keep in sync
                PhoneNumber = phone,      // <= store null if empty
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            var result = await _userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                _context.ChangeTracker.Clear();
                throw new ValidationException($"User creation failed: {string.Join(", ", result.Errors.Select(e => e.Description))}");
            }

            // Assign roles (unchanged)
            IdentityResult roleResult = (request.Roles != null && request.Roles.Any())
                ? await _userManager.AddToRolesAsync(user, request.Roles)
                : await _userManager.AddToRoleAsync(user, "Customer");

            if (!roleResult.Succeeded)
            {
                _context.ChangeTracker.Clear();
                throw new ValidationException($"Failed to assign roles: {string.Join(", ", roleResult.Errors.Select(e => e.Description))}");
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

            // Email change: check duplicates first
            if (request.Email != null && !string.Equals(request.Email, user.Email, StringComparison.OrdinalIgnoreCase))
            {
                var existingByEmail = await _userManager.FindByEmailAsync(request.Email);
                if (existingByEmail != null && existingByEmail.Id != user.Id)
                    throw new ValidationException("A user with the given email already exists.");

                user.Email = request.Email;
                user.UserName = request.Email; // keep in sync
            }

            // Phone change: normalize & check only if provided
            if (request.PhoneNumber != null) // caller intends to modify phone (can be set to empty to clear)
            {
                var phone = string.IsNullOrWhiteSpace(request.PhoneNumber)
                    ? null
                    : request.PhoneNumber.Trim();

                if (phone != null && !string.Equals(phone, user.PhoneNumber, StringComparison.Ordinal))
                {
                    var phoneExists = await _context.Users
                        .AsNoTracking()
                        .AnyAsync(u => u.PhoneNumber == phone && u.Id != user.Id);

                    if (phoneExists)
                        throw new ValidationException("A user with the given phone number already exists.");
                }

                user.PhoneNumber = phone; // set (or clear) after checks
            }

            if (request.FirstName != null) user.FirstName = request.FirstName;
            if (request.LastName != null) user.LastName = request.LastName;
            if (request.IsActive.HasValue) user.IsActive = request.IsActive.Value;

            // Password update if provided
            if (!string.IsNullOrEmpty(request.Password))
            {
                var token = await _userManager.GeneratePasswordResetTokenAsync(user);
                var pwdResult = await _userManager.ResetPasswordAsync(user, token, request.Password);
                if (!pwdResult.Succeeded)
                    throw new ValidationException($"Password update failed: {string.Join(", ", pwdResult.Errors.Select(e => e.Description))}");
            }

            // Roles update if provided (unchanged)
            if (request.Roles != null)
            {
                var currentRoles = await _userManager.GetRolesAsync(user);
                var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
                if (!removeResult.Succeeded)
                    throw new ValidationException($"Failed to remove existing roles: {string.Join(", ", removeResult.Errors.Select(e => e.Description))}");

                if (request.Roles.Any())
                {
                    var addResult = await _userManager.AddToRolesAsync(user, request.Roles);
                    if (!addResult.Succeeded)
                        throw new ValidationException($"Failed to assign new roles: {string.Join(", ", addResult.Errors.Select(e => e.Description))}");
                }
            }

            var updateResult = await _userManager.UpdateAsync(user);
            if (!updateResult.Succeeded)
                throw new ValidationException($"User update failed: {string.Join(", ", updateResult.Errors.Select(e => e.Description))}");

            await _context.Entry(user).Reference(u => u.Image).LoadAsync();

            var resp = _mapper.Map<UserResponse>(user);
            var rolesFinal = await _userManager.GetRolesAsync(user);
            resp.Roles = rolesFinal.ToList();
            return resp;
        }

        public override async Task<UserResponse?> GetByIdAsync(int id)
        {
            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user == null) return null;

            // Include Images if needed
            await _context.Entry(user)
                .Reference(u => u.Image)
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

            if (!string.IsNullOrWhiteSpace(search.SortBy))
            {
                var ascending = search.Ascending;
                query = search.SortBy.ToLower() switch
                {
                    "email" or "username" => ascending
                        ? query.OrderBy(u => u.UserName)
                        : query.OrderByDescending(u => u.UserName),

                    "firstname" => ascending
                        ? query.OrderBy(u => u.FirstName)
                        : query.OrderByDescending(u => u.FirstName),

                    "lastname" => ascending
                        ? query.OrderBy(u => u.LastName)
                        : query.OrderByDescending(u => u.LastName),

                    "createdat" => ascending
                        ? query.OrderBy(u => u.CreatedAt)
                        : query.OrderByDescending(u => u.CreatedAt),
                    _ => query.OrderBy(u => u.Id)
                };
            }

            else
            {
                query = query.OrderBy(u => u.Id); // default sort
            }

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                int page = search.Page;
                int pageSize = search.PageSize;

                var skip = (page - 1) * pageSize;
                query = query.Skip(skip).Take(pageSize);
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


        //Mobile user profile 
        public async Task<MeResponse> GetMeAsync(int userId)
        {
            var userResp = await GetByIdAsync(userId)
                          ?? throw new KeyNotFoundException("User not found.");
            return _mapper.Map<MeResponse>(userResp);
        }

        public async Task<MeResponse> UpdateMeAsync(int userId, MeUpdateRequest request)
        {
            var update = _mapper.Map<UserUpdateRequest>(request);
            update.Roles = null;
            update.IsActive = null;
            update.Password = null;
            update.Email = null;

            var updated = await UpdateAsync(userId, update)
                        ?? throw new KeyNotFoundException("User not found.");
            return _mapper.Map<MeResponse>(updated);
        }

        public async Task ChangePasswordAsync(int userId, string currentPassword, string newPassword)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString())
                       ?? throw new KeyNotFoundException("User not found.");

            var result = await _userManager.ChangePasswordAsync(user, currentPassword, newPassword);
            if (!result.Succeeded)
                throw new ValidationException(string.Join("; ", result.Errors.Select(e => e.Description)));
        }

        public async Task BeginChangeEmailAsync(int userId, string newEmail, string? currentPassword)
        {
            var user = await _userManager.FindByIdAsync(userId.ToString())
                       ?? throw new KeyNotFoundException("User not found.");

            if (!string.IsNullOrEmpty(currentPassword))
            {
                var ok = await _userManager.CheckPasswordAsync(user, currentPassword);
                if (!ok) throw new UnauthorizedAccessException("Invalid password.");
            }

            var token = await _userManager.GenerateChangeEmailTokenAsync(user, newEmail);
            var changed = await _userManager.ChangeEmailAsync(user, newEmail, token);
            if (!changed.Succeeded)
                throw new ValidationException(string.Join("; ", changed.Errors.Select(e => e.Description)));

            await _userManager.SetUserNameAsync(user, newEmail); // if email == username
        }

    }
}