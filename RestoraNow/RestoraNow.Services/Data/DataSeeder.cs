using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Model.Enums;
using RestoraNow.Services.Entities;

namespace RestoraNow.Services.Data
{
    public class DataSeeder
    {
        private readonly RoleManager<IdentityRole<int>> _roleManager;
        private readonly UserManager<User> _userManager;
        private readonly ApplicationDbContext _context;
        private readonly Random _rnd = new();

        public DataSeeder(
            RoleManager<IdentityRole<int>> roleManager,
            UserManager<User> userManager,
            ApplicationDbContext context)
        {
            _roleManager = roleManager;
            _userManager = userManager;
            _context = context;
        }

        // -------------------- Orchestrator --------------------

        public async Task SeedAllAsync(
            int itemsPerCategory = 6,
            int sampleUsers = 20,
            int days = 30,
            int orders = 120,
            int reservations = 80,
            int reviews = 60,
            int tableCount = 15,
            int restaurantIdIfKnown = 0)
        {
            await SeedRolesAsync();
            await SeedAdminAsync();
            await SeedMenuCategoriesAsync();

            var restaurantId = restaurantIdIfKnown != 0
                ? restaurantIdIfKnown
                : await SeedRestaurantAsync();

            await SeedMenuItemsAsync(itemsPerCategory);
            await SeedSampleUsersAsync(sampleUsers);
            await SeedTablesAsync(tableCount, restaurantId);

            await SeedOrdersAndItemsAsync(days, orders /*, restaurantId*/);
            await SeedReservationsAsync(days, reservations /*, restaurantId*/);
            await SeedReviewsAsync(days, reviews, restaurantId);
        }

        // -------------------- Roles + Admin --------------------

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
                        throw new Exception($"Failed to create role {role}: {string.Join(", ", result.Errors.Select(e => e.Description))}");
                }
            }
        }

        public async Task SeedAdminAsync()
        {
            var adminUser = await _userManager.FindByEmailAsync("admin@restoranow.com");
            if (adminUser != null) return;

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
            if (!result.Succeeded)
                throw new Exception($"Failed to create admin user: {string.Join(", ", result.Errors.Select(e => e.Description))}");

            await _userManager.AddToRoleAsync(adminUser, "Admin");
        }

        // -------------------- Catalog --------------------

        public async Task SeedMenuCategoriesAsync()
        {
            var defaultCategories = new[]
            {
                new MenuCategory { Name = "Appetizers",   Description = "Start your meal with a light bite." },
                new MenuCategory { Name = "Main Courses", Description = "Hearty and satisfying meals." },
                new MenuCategory { Name = "Desserts",     Description = "Sweet treats to finish your meal." },
                new MenuCategory { Name = "Drinks",       Description = "Beverages to complement your dish." }
            };

            foreach (var category in defaultCategories)
            {
                bool exists = await _context.Categories.AnyAsync(mc => mc.Name == category.Name);
                if (!exists) _context.Categories.Add(category);
            }

            await _context.SaveChangesAsync();
        }

        public async Task<int> SeedRestaurantAsync()
        {
            // Adjust fields/properties to match your Restaurant entity
            var existingId = await _context.Restaurants.Select(r => r.Id).FirstOrDefaultAsync();
            if (existingId != 0) return existingId;

            var r = new Restaurant
            {
                Name = "Konak kod Hilmije",
                Address = "Adress 1b",
                PhoneNumber = "061553101",
                Email = "hilmija@mail.com",
                Description = "Najbolji restoran u Mostaru",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Restaurants.Add(r);
            await _context.SaveChangesAsync();
            return r.Id;
        }

        public async Task SeedMenuItemsAsync(int itemsPerCategory = 6)
        {
            var categories = await _context.Categories.AsNoTracking().ToListAsync();
            if (categories.Count == 0) return;

            foreach (var c in categories)
            {
                var count = await _context.MenuItem.CountAsync(mi => mi.CategoryId == c.Id);
                var needed = Math.Max(0, itemsPerCategory - count);
                if (needed == 0) continue;

                var list = new List<MenuItem>();
                var startIdx = count + 1;
                for (int i = 0; i < needed; i++)
                {
                    var price = _rnd.Next(5, 35) + (decimal)_rnd.NextDouble(); // decimal
                    list.Add(new MenuItem
                    {
                        Name = $"{c.Name} Item {startIdx + i}",
                        Description = "Sample item",
                        CategoryId = c.Id,
                        Price = Math.Round(price, 2, MidpointRounding.AwayFromZero),
                        IsAvailable = true,
                        IsSpecialOfTheDay = _rnd.NextDouble() < 0.2
                    });
                }

                _context.MenuItem.AddRange(list);
            }

            await _context.SaveChangesAsync();
        }

        // -------------------- Users + Tables --------------------

        public async Task SeedSampleUsersAsync(int targetCount = 20)
        {
            var existing = await _context.Users.CountAsync();
            var toAdd = Math.Max(0, targetCount - existing);
            if (toAdd == 0) return;

            for (int i = 1; i <= toAdd; i++)
            {
                var email = $"user{i}@example.com";
                if (await _userManager.FindByEmailAsync(email) != null) continue;

                var u = new User
                {
                    FirstName = $"User{i}",
                    LastName = "Test",
                    Email = email,
                    UserName = email,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-_rnd.Next(0, 30))
                };

                var res = await _userManager.CreateAsync(u, "User123!");
                if (res.Succeeded)
                    await _userManager.AddToRoleAsync(u, "Customer");
            }
        }

        public async Task SeedTablesAsync(int tableCount = 15, int restaurantId = 1)
        {
            // Existing table numbers for this restaurant
            var existingNumbers = (await _context.Tables
                .Where(t => t.RestaurantId == restaurantId)
                .Select(t => t.TableNumber)
                .ToListAsync())
                .ToHashSet(); // in-memory

            var list = new List<Table>();

            for (int num = 1; num <= tableCount; num++)
            {
                if (existingNumbers.Contains(num)) continue;

                list.Add(new Table
                {
                    RestaurantId = restaurantId,
                    TableNumber = num,
                    Capacity = _rnd.Next(2, 6),
                    IsAvailable = true,
                    Location = "Main floor",
                    Notes = string.Empty
                });
            }

            if (list.Count > 0)
            {
                _context.Tables.AddRange(list);
                await _context.SaveChangesAsync();
            }
        }

        // -------------------- Business Data --------------------
        public async Task SeedOrdersAndItemsAsync(int days, int orders)
        {
            // 1) UserId is REQUIRED on Order
            var userIds = await _context.Users
                .AsNoTracking()
                .Select(u => u.Id)
                .ToListAsync();

            if (userIds.Count == 0)
            {
                await SeedSampleUsersAsync(10);
                userIds = await _context.Users.AsNoTracking().Select(u => u.Id).ToListAsync();
                if (userIds.Count == 0)
                    throw new InvalidOperationException("No users available to assign to Orders.");
            }

            // 2) Make sure we have menu items for OrderItems
            var menuItems = await _context.MenuItem
                .AsNoTracking()
                .Select(mi => new { mi.Id, mi.Price })
                .ToListAsync();

            if (menuItems.Count == 0)
            {
                await SeedMenuItemsAsync(itemsPerCategory: 6);
                menuItems = await _context.MenuItem.AsNoTracking().Select(mi => new { mi.Id, mi.Price }).ToListAsync();
                if (menuItems.Count == 0)
                    throw new InvalidOperationException("No menu items available to add to OrderItems.");
            }

            // 3) Reservations are optional – link some orders to existing reservations if present
            var reservationIds = await _context.Reservations
                .AsNoTracking()
                .Select(r => r.Id)
                .ToListAsync();

            // 4) Create orders + items
            var ordersList = new List<Order>();
            var itemsList = new List<OrderItem>();

            for (int i = 0; i < orders; i++)
            {
                var createdAt = RandomDateUtc(days);
                var isCompleted = _rnd.NextDouble() < 0.8;

                var order = new Order
                {
                    UserId = userIds[_rnd.Next(userIds.Count)],
                    CreatedAt = createdAt,
                    Status = isCompleted ? OrderStatus.Completed : OrderStatus.Preparing
                };

                // Link a reservation in ~35% of cases (only if any exist)
                if (reservationIds.Count > 0 && _rnd.NextDouble() < 0.35)
                {
                    order.ReservationId = reservationIds[_rnd.Next(reservationIds.Count)];
                }

                ordersList.Add(order);

                var itemsInOrder = _rnd.Next(1, 4);
                for (int k = 0; k < itemsInOrder; k++)
                {
                    var pick = menuItems[_rnd.Next(menuItems.Count)];
                    var qty = _rnd.Next(1, 4);

                    itemsList.Add(new OrderItem
                    {
                        Order = order,          // attach to the new order
                        MenuItemId = pick.Id,
                        Quantity = qty,
                        UnitPrice = pick.Price      // decimal -> fine
                    });
                }
            }

            _context.Orders.AddRange(ordersList);
            _context.OrderItems.AddRange(itemsList);
            await _context.SaveChangesAsync();

            // Uncomment once I make the Payment system
            /*
            var payments = new List<Payment>();
            foreach (var o in ordersList.Where(o => o.Status == OrderStatus.Completed))
            {
                var amount = itemsList.Where(oi => oi.Order == o).Sum(oi => oi.UnitPrice * oi.Quantity);
                payments.Add(new Payment
                {
                    Order = o,
                    Amount = amount,
                    PaidAt = o.CreatedAt,
                    Method = PaymentMethod.Cash, // example
                    Status = PaymentStatus.Settled
                });
            }
            _context.Payments.AddRange(payments);
            await _context.SaveChangesAsync();
            */
        }

        public async Task SeedReservationsAsync(int days, int count)
        {
            // ensure users exist
            var userIds = await _context.Users.AsNoTracking().Select(u => u.Id).ToListAsync();
            if (userIds.Count == 0)
            {
                await SeedSampleUsersAsync(10);
                userIds = await _context.Users.AsNoTracking().Select(u => u.Id).ToListAsync();
            }

            // ensure tables exist
            var tables = await _context.Tables
                .AsNoTracking()
                .Select(t => new { t.Id, t.Capacity })
                .ToListAsync();
            if (tables.Count == 0)
            {
                // pick a restaurant id if you have one handy; else default to 1
                var restaurantId = await _context.Restaurants.AsNoTracking()
                    .Select(r => r.Id)
                    .FirstOrDefaultAsync();
                if (restaurantId == 0) restaurantId = await SeedRestaurantAsync();

                await SeedTablesAsync(tableCount: 15, restaurantId: restaurantId);
                tables = await _context.Tables.AsNoTracking().Select(t => new { t.Id, t.Capacity }).ToListAsync();
            }

            var list = new List<Reservation>();
            for (int i = 0; i < count; i++)
            {
                var dt = RandomDateUtc(days).AddMinutes(_rnd.Next(0, 24 * 60));
                var table = tables[_rnd.Next(tables.Count)];
                var guestCount = _rnd.Next(1, Math.Max(2, table.Capacity + 1)); // 1..Capacity

                var status = _rnd.NextDouble() < 0.7
                    ? ReservationStatus.Confirmed
                    : ReservationStatus.Pending;

                list.Add(new Reservation
                {
                    UserId = userIds[_rnd.Next(userIds.Count)],
                    TableId = table.Id,
                    ReservationDate = dt.Date,
                    ReservationTime = dt.TimeOfDay,
                    GuestCount = guestCount,
                    Status = status,
                    SpecialRequests = string.Empty,
                    ConfirmedAt = status == ReservationStatus.Confirmed
                        ? dt.AddMinutes(-_rnd.Next(30, 360))
                        : (DateTime?)null
                });
            }

            _context.Reservations.AddRange(list);
            await _context.SaveChangesAsync();
        }

        public async Task SeedReviewsAsync(int days, int reviews, int restaurantId)
        {
            var userIds = await _context.Users.AsNoTracking().Select(u => u.Id).ToListAsync();
            if (userIds.Count == 0) return;

            var list = new List<Review>();
            for (int i = 0; i < reviews; i++)
            {
                var rating = _rnd.Next(1, 6);
                list.Add(new Review
                {
                    RestaurantId = restaurantId,
                    UserId = userIds[_rnd.Next(userIds.Count)],
                    Rating = rating,
                    Comment = rating >= 4 ? "Great!" : rating == 3 ? "Okay" : "Needs improvement",
                    CreatedAt = RandomDateUtc(days),
                });
            }

            _context.Reviews.AddRange(list);
            await _context.SaveChangesAsync();
        }

        // -------------------- Helpers --------------------

        private DateTime RandomDateUtc(int lastNDays)
        {
            var now = DateTime.UtcNow;
            var start = now.AddDays(-Math.Max(1, lastNDays));
            var minutes = (int)(now - start).TotalMinutes;
            return start.AddMinutes(_rnd.Next(0, minutes));
        }
    }
}