using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Services.Entities;

namespace RestoraNow.Services.Data
{
    public class ApplicationDbContext : IdentityDbContext<User, IdentityRole<int>, int>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Table> Tables { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<Restaurant> Restaurants { get; set; }
        public DbSet<MenuItem> MenuItem { get; set; }
        public DbSet<MenuItemReview> MenuItemReview { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<MenuCategory> Categories { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Address> Address { get; set; }
        public DbSet<Favorite> Favorite { get; set; }
        public DbSet<MenuItemImage> MenuItemImages { get; set; }
        public DbSet<UserImage> UserImages { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Identity tables
            modelBuilder.Entity<User>().ToTable("AppUsers");
            modelBuilder.Entity<IdentityRole<int>>().ToTable("AppRoles");
            modelBuilder.Entity<IdentityUserRole<int>>().ToTable("AppUserRoles");

            // Address: user can have many addresses, only one default
            modelBuilder.Entity<Address>()
                .HasOne(a => a.User)
                .WithMany(u => u.Addresses)
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Address>()
                .HasIndex(a => new { a.UserId, a.IsDefault })
                .HasFilter("[IsDefault] = 1")
                .IsUnique();

            // Orders / Payments
            modelBuilder.Entity<Order>()
                .HasOne(o => o.Payment)
                .WithOne(p => p.Order)
                .HasForeignKey<Payment>(p => p.OrderId);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.User)
                .WithMany(u => u.Orders)
                .HasForeignKey(o => o.UserId);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.Order)
                .WithMany(o => o.OrderItems)
                .HasForeignKey(oi => oi.OrderId);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.MenuItem)
                .WithMany(mi => mi.OrderItems)
                .HasForeignKey(oi => oi.MenuItemId);

            // ===== MenuItemReview (one review per user per menu item) =====
            modelBuilder.Entity<MenuItemReview>()
                .HasIndex(x => new { x.UserId, x.MenuItemId })
                .IsUnique();

            modelBuilder.Entity<MenuItemReview>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<MenuItemReview>()
                .HasOne(r => r.MenuItem)
                .WithMany(mi => mi.Reviews)
                .HasForeignKey(r => r.MenuItemId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== MenuItemImage (one image per MenuItem) =====
            modelBuilder.Entity<MenuItemImage>()
                .HasIndex(i => i.MenuItemId)
                .IsUnique();

            modelBuilder.Entity<MenuItem>()
                .HasOne(m => m.Image)
                .WithOne(i => i.MenuItem)
                .HasForeignKey<MenuItemImage>(i => i.MenuItemId)
                .OnDelete(DeleteBehavior.Cascade);


            // ===== (Optional) Restaurant Review uniqueness =====
            // modelBuilder.Entity<Review>()
            //     .HasIndex(x => new { x.UserId, x.RestaurantId })
            //     .IsUnique();
        }


    }
}