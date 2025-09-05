using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Implementations;
using RestoraNow.Services.Interfaces;
using RestoraNow.Services.Interfaces.Base;
using RestoraNow.Services.Recommendations;
using RestoraNow.WebAPI.Helpers;
using RestoraNow.WebAPI.Middleware;
using System.Security.Claims;
using System.Text;
using System.Text.Json.Serialization;

namespace RestoraNow.WebAPI
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Services
            builder.Services.AddTransient<IAddressService, AddressService>();
            builder.Services.AddTransient<IFavoriteService, FavoriteService>();
            builder.Services.AddTransient<IMenuCategoryService, MenuCategoryService>();
            builder.Services.AddTransient<IMenuItemService, MenuItemService>();
            builder.Services.AddScoped<IMenuItemImageService, MenuItemImageService>();
            builder.Services.AddTransient<IOrderService, OrderService>();
            builder.Services.AddTransient<IOrderItemService, OrderItemService>();
            builder.Services.AddScoped<IPaymentService, PaymentService>();
            builder.Services.AddScoped<IReservationService, ReservationService>();
            builder.Services.AddScoped<IRestaurantService, RestaurantService>();
            builder.Services.AddScoped<IReviewService, ReviewService>();
            builder.Services.AddScoped<IMenuItemReviewService, MenuItemReviewService>();
            builder.Services.AddScoped<ITableService, TableService>();
            builder.Services.AddScoped<IUserService, UserService>();
            builder.Services.AddScoped<IUserImageService, UserImageService>();
            builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
            builder.Services.AddScoped<IMenuRecommendationService, MenuRecommendationService>();

            builder.Services.AddScoped<DataSeeder>(); //Data Seeder
            builder.Services.AddHttpContextAccessor();

            // Mapster
            builder.Services.AddMapster();
            RestoraNow.Services.Mappings.MappingConfig.RegisterMappings();

            builder.Services.AddControllers()
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
                    options.JsonSerializerOptions.Converters.Add(new TimeSpanConverter());
                });

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "RestoraNow API", Version = "v1" });
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    In = ParameterLocation.Header,
                    Description = "Please enter JWT with Bearer into field",
                    Name = "Authorization",
                    Type = SecuritySchemeType.Http,
                    Scheme = "Bearer",
                    BearerFormat = "JWT"
                });
                c.AddSecurityRequirement(new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
                        },
                        new string[] {}
                    }
                });
            });

            var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
                Console.WriteLine("CONNECTION STRING: " + connectionString);

            if (connectionString.Contains("restoranow-sql"))
            {
                Console.WriteLine("Using Docker connection string");
            }


            builder.Services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            builder.Services.AddIdentity<User, IdentityRole<int>>(options =>
            {
                options.Password.RequireDigit = true;
                options.Password.RequiredLength = 6;
                options.Password.RequireNonAlphanumeric = false;
                options.User.RequireUniqueEmail = true;

            })
                .AddEntityFrameworkStores<ApplicationDbContext>()
                .AddDefaultTokenProviders();

            var jwtKey = builder.Configuration["Jwt:Key"];
            var jwtIssuer = builder.Configuration["Jwt:Issuer"];
            var jwtAudience = builder.Configuration["Jwt:Audience"] ?? jwtIssuer;


            builder.Services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.RequireHttpsMetadata = true;
                options.SaveToken = true;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidIssuer = jwtIssuer,
                    ValidAudience = jwtAudience,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero,
                    RoleClaimType = ClaimTypes.Role, // Map role claim
                    NameClaimType = ClaimTypes.NameIdentifier // Map name claim
                };
            });

            var app = builder.Build();

            //Docker is treated as Production, so for the swagger to show up I disabled the IsDevelopment line.
            //Later when I make the frontend I'll enable it



            //if (app.Environment.IsDevelopment())
            //{
                app.UseSwagger();
                app.UseSwaggerUI();
            //}

            app.UseAuthentication();
            app.UseAuthorization();

            app.UseMiddleware<GlobalExceptionMiddleware>(); //Maybe it can stay here we'll see if it makes problems

            //app.UseHttpsRedirection();
            app.MapControllers();

            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var env = services.GetRequiredService<IHostEnvironment>();
                var dbContext = services.GetRequiredService<ApplicationDbContext>();

                await dbContext.Database.MigrateAsync();

                var seeder = services.GetRequiredService<DataSeeder>();

                // Idempotent catalog/users
                await seeder.SeedRolesAsync();
                await seeder.SeedAdminAsync();
                await seeder.SeedMenuCategoriesAsync();
                var restaurantId = await seeder.SeedRestaurantAsync();
                await seeder.SeedMenuItemsAsync(itemsPerCategory: 6);
                await seeder.SeedSampleUsersAsync(targetCount: 20);
                await seeder.SeedTablesAsync(tableCount: 15, restaurantId: restaurantId);

                // --- Seed business data ONCE ---
                // If ANY of these already exist, skip creating more
                var hasOrders = await dbContext.Orders.AsNoTracking().AnyAsync();
                var hasReservations = await dbContext.Reservations.AsNoTracking().AnyAsync();
                var hasReviews = await dbContext.Reviews.AsNoTracking().AnyAsync();

                if (!hasOrders && !hasReservations && !hasReviews)
                {
                    await seeder.SeedReservationsAsync(days: 30, count: 80);
                    await seeder.SeedOrdersAndItemsAsync(days: 30, orders: 120);
                    await seeder.SeedReviewsAsync(days: 30, reviews: 60, restaurantId: restaurantId);
                }
            }

            await app.RunAsync();
        }
    }
}