using System.Security.Claims;
using System.Text;
using System.Text.Json.Serialization;
using DotNetEnv;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using QuestPDF.Infrastructure;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Implementations;
using RestoraNow.Services.Interfaces;
using RestoraNow.Services.Payments;
using RestoraNow.Services.Recommendations;
using RestoraNow.WebAPI.Helpers;
using RestoraNow.WebAPI.Middleware;
using EasyNetQ;
using EasyNetQ.Serialization.SystemTextJson;

namespace RestoraNow.WebAPI
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // ---- Logging ----
            builder.Logging.ClearProviders();
            builder.Logging.AddConsole();

            // ---- .env + env vars ----
            var envPath = Path.Combine(builder.Environment.ContentRootPath, "..", ".env");
            try { Env.Load(envPath); } catch { /* ignore if missing */ }
            builder.Configuration.AddEnvironmentVariables();

            // Boot diagnostics
            Console.WriteLine("---- BOOT DIAG ----");
            Console.WriteLine($"ENV path: {Path.GetFullPath(envPath)} | exists: {File.Exists(envPath)}");
            Console.WriteLine("Jwt present: " + !string.IsNullOrWhiteSpace(builder.Configuration["Jwt:Key"]));
            Console.WriteLine("Conn empty: " + string.IsNullOrWhiteSpace(builder.Configuration.GetConnectionString("DefaultConnection")));
            Console.WriteLine("Environment: " + builder.Environment.EnvironmentName);

            // ---- Core services ----
            builder.Services.AddHttpContextAccessor();

            // PayPal gateway
            builder.Services.AddHttpClient<PayPalGateway>(c => c.Timeout = TimeSpan.FromSeconds(30));

            // ---- RabbitMQ (EasyNetQ) ----
            string BuildRabbitConn(IConfiguration cfg)
            {
                var fromSingle = cfg["RabbitMQ:ConnectionString"];
                if (!string.IsNullOrWhiteSpace(fromSingle)) return fromSingle;

                var host = cfg["Rabbit:Host"] ?? "localhost";
                var user = cfg["Rabbit:User"] ?? "guest";
                var pass = cfg["Rabbit:Pass"] ?? "guest";
                var port = cfg["Rabbit:Port"];
                var vhost = cfg["Rabbit:VirtualHost"];
                var product = cfg["Rabbit:Product"]; // optional label
                var name = cfg["Rabbit:Name"];    // optional label

                var parts = new List<string>
                {
                    $"host={host}",
                    $"username={user}",
                    $"password={pass}",
                    "publisherConfirms=true",
                    "timeout=10"
                };
                if (!string.IsNullOrWhiteSpace(port)) parts.Add($"port={port}");
                if (!string.IsNullOrWhiteSpace(vhost)) parts.Add($"virtualHost={vhost}");
                if (!string.IsNullOrWhiteSpace(product)) parts.Add($"product={product}");
                if (!string.IsNullOrWhiteSpace(name)) parts.Add($"name={name}");

                return string.Join(";", parts);
            }

            var rabbitConn = BuildRabbitConn(builder.Configuration);

            builder.Services.AddSingleton<IBus>(_ =>
                RabbitHutch.CreateBus(rabbitConn, cfg => cfg.EnableSystemTextJson())
            );

            // ---- App services ----
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

            builder.Services.AddHostedService<RestoraNow.WebAPI.Background.EmailSentLoggingSubscriber>(); //API message

            builder.Services.AddScoped<DataSeeder>();


            // Mapster
            builder.Services.AddMapster();
            RestoraNow.Services.Mappings.MappingConfig.RegisterMappings();

            // QuestPDF
            QuestPDF.Settings.License = LicenseType.Community;

            // Controllers + JSON
            builder.Services.AddControllers()
                .AddJsonOptions(options =>
                {
                    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
                    options.JsonSerializerOptions.Converters.Add(new TimeSpanConverter());
                });

            // Swagger + JWT support
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "RestoraNow API", Version = "v1" });
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
                {
                    In = ParameterLocation.Header,
                    Description = "Enter: Bearer {your JWT}",
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
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                });
            });

            // Database
            builder.Services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            // Identity
            builder.Services.AddIdentity<User, IdentityRole<int>>(options =>
            {
                options.Password.RequireDigit = true;
                options.Password.RequiredLength = 6;
                options.Password.RequireNonAlphanumeric = false;
                options.User.RequireUniqueEmail = true;
                // options.SignIn.RequireConfirmedEmail = true; // enable if you want to block login until confirmed
            })
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

            // JWT
            var jwtKey = builder.Configuration["Jwt:Key"];
            if (string.IsNullOrWhiteSpace(jwtKey) || Encoding.UTF8.GetBytes(jwtKey).Length < 32)
                throw new InvalidOperationException("Jwt__Key is missing or too short in .env (≥ 32 bytes).");

            var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "RestoraNow";
            var jwtAudience = builder.Configuration["Jwt:Audience"] ?? jwtIssuer;

            builder.Services.AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
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
                    RoleClaimType = ClaimTypes.Role,
                    NameClaimType = ClaimTypes.NameIdentifier
                };
            });


            builder.Services.AddAuthorization(options =>
            {
                // StaffOnly => Admin OR Staff
                options.AddPolicy("StaffOnly", p => p.RequireRole("Admin", "Staff"));

                // AdminOnly => Admin only
                options.AddPolicy("AdminOnly", p => p.RequireRole("Admin"));
            });
            // [Authorize] //any logged-in user
            // [Authorize(Policy = "StaffOnly")] // only Admin/Manager


            // ---- Build app ----
            var app = builder.Build();

            app.UseSwagger();
            app.UseSwaggerUI();

            app.UseAuthentication();
            app.UseAuthorization();

            app.UseMiddleware<GlobalExceptionMiddleware>();
            app.MapControllers();

            // ---- Migrate + seed ----
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var db = services.GetRequiredService<ApplicationDbContext>();
                await db.Database.MigrateAsync();

                if (app.Environment.IsDevelopment())
                {
                    var seeder = services.GetRequiredService<DataSeeder>();

                    // Core + catalog
                    await seeder.SeedRolesAsync();
                    await seeder.SeedCoreUsersAsync();
                    await seeder.SeedMenuCategoriesAsync();
                    var restaurantId = await seeder.SeedRestaurantAsync();
                    await seeder.SeedMenuItemsAsync(itemsPerCategory: 6);
                    await seeder.SeedSampleUsersAsync(targetCount: 20);
                    await seeder.SeedTablesAsync(tableCount: 15, restaurantId);

                    // New: seed addresses & menu-item reviews regardless of business data presence
                    await seeder.SeedAddressesAsync(minPerUser: 1, maxPerUser: 3);
                    await seeder.SeedMenuItemReviewsAsync(reviewsPerUser: 3);

                    // Business data (guard to avoid re-creating lots of rows every run)
                    var hasOrders = await db.Orders.AsNoTracking().AnyAsync();
                    var hasReservations = await db.Reservations.AsNoTracking().AnyAsync();
                    var hasReviews = await db.Reviews.AsNoTracking().AnyAsync();

                    if (!hasOrders && !hasReservations && !hasReviews)
                    {
                        await seeder.SeedReservationsAsync(days: 30, count: 80); // ← before orders
                        await seeder.SeedOrdersAndItemsAsync(days: 30, orders: 120);
                        await seeder.SeedReviewsAsync(days: 30, reviews: 60, restaurantId);
                    }
                }
            }


            await app.RunAsync();
        }
    }
}
