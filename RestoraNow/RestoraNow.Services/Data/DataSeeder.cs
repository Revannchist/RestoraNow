using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Services.Entities;

namespace RestoraNow.Services.Data
{
    public class DataSeeder
    {
        private readonly RoleManager<IdentityRole<int>> _roleManager;
        private readonly UserManager<User> _userManager;
        private readonly ApplicationDbContext _context;

        public DataSeeder(RoleManager<IdentityRole<int>> roleManager, UserManager<User> userManager, ApplicationDbContext context)
        {
            _roleManager = roleManager;
            _userManager = userManager;
            _context = context;
        }

        public async Task SeedRolesAsync()
        {
            string[] roles = { "Admin", "Manager", "Staff", "Customer" };

            foreach (var role in roles)
            {
                if (!await _roleManager.RoleExistsAsync(role))
                {
                    var identityRole = new IdentityRole<int> { Name = role };
                    var result = await _roleManager.CreateAsync(identityRole);
                    if (!result.Succeeded)
                    {
                        throw new Exception($"Failed to create role {role}: {string.Join(", ", result.Errors.Select(e => e.Description))}");
                    }
                }
            }

            // Seed admin user
            var adminUser = await _userManager.FindByEmailAsync("admin@restoranow.com");
            if (adminUser == null)
            {
                adminUser = new User
                {
                    FirstName = "Admin",
                    LastName = "User",
                    Email = "admin@restoranow.com",
                    UserName = "admin@restoranow.com",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };
                var result = await _userManager.CreateAsync(adminUser, "Admin123!");
                if (result.Succeeded)
                {
                    await _userManager.AddToRoleAsync(adminUser, "Admin");
                }
                else
                {
                    throw new Exception($"Failed to create admin user: {string.Join(", ", result.Errors.Select(e => e.Description))}");
                }
            }
        }

        public async Task SeedMenuCategoriesAsync()
        {
            var defaultCategories = new[]
            {
                new MenuCategory { Name = "Appetizers", Description = "Start your meal with a light bite." },
                new MenuCategory { Name = "Main Courses", Description = "Hearty and satisfying meals." },
                new MenuCategory { Name = "Desserts", Description = "Sweet treats to finish your meal." },
                new MenuCategory { Name = "Drinks", Description = "Beverages to complement your dish." }
            };

            foreach (var category in defaultCategories)
            {
                bool exists = await _context.Categories
                    .AnyAsync(mc => mc.Name == category.Name);

                if (!exists)
                {
                    _context.Categories.Add(category);
                }
            }

            await _context.SaveChangesAsync();
        }

    }
}
