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
            try { Env.Load(envPath); } catch { /* ignore */ }
            builder.Configuration.AddEnvironmentVariables();

            // Boot diagnostics
            Console.WriteLine("---- BOOT DIAG ----");
            Console.WriteLine($"ENV path: {Path.GetFullPath(envPath)} | exists: {File.Exists(envPath)}");
            Console.WriteLine("Jwt present: " + !string.IsNullOrWhiteSpace(builder.Configuration["Jwt:Key"]));
            Console.WriteLine("Conn empty: " + string.IsNullOrWhiteSpace(builder.Configuration.GetConnectionString("DefaultConnection")));
            Console.WriteLine("Environment: " + builder.Environment.EnvironmentName);

            // ---- Core services ----
            builder.Services.AddHttpContextAccessor();

            // PayPal gateway: typed HttpClient (gateway reads .env internally)
            builder.Services.AddHttpClient<PayPalGateway>(c =>
            {
                c.Timeout = TimeSpan.FromSeconds(30);
                // No BaseAddress here on purpose — the gateway will read PayPal__BaseUrl from .env
            });

            // App services
            builder.Services.AddTransient<IAddressService, AddressService>();
            builder.Services.AddTransient<IFavoriteService, FavoriteService>();
            builder.Services.AddTransient<IMenuCategoryService, MenuCategoryService>();
            builder.Services.AddTransient<IMenuItemService, MenuItemService>();
            builder.Services.AddScoped<IMenuItemImageService, MenuItemImageService>();
            builder.Services.AddTransient<IOrderService, OrderService>();
            builder.Services.AddTransient<IOrderItemService, OrderItemService>();
            builder.Services.AddScoped<IPaymentService, PaymentService>(); // CRUD + PayPal
            builder.Services.AddScoped<IReservationService, ReservationService>();
            builder.Services.AddScoped<IRestaurantService, RestaurantService>();
            builder.Services.AddScoped<IReviewService, ReviewService>();
            builder.Services.AddScoped<IMenuItemReviewService, MenuItemReviewService>();
            builder.Services.AddScoped<ITableService, TableService>();
            builder.Services.AddScoped<IUserService, UserService>();
            builder.Services.AddScoped<IUserImageService, UserImageService>();
            builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
            builder.Services.AddScoped<IMenuRecommendationService, MenuRecommendationService>();
            builder.Services.AddHttpClient<PayPalGateway>();

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
            })
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddDefaultTokenProviders();

            // JWT
            var jwtKey = builder.Configuration["Jwt:Key"];
            if (string.IsNullOrWhiteSpace(jwtKey) || Encoding.UTF8.GetBytes(jwtKey).Length < 32)
                throw new InvalidOperationException("Jwt__Key is missing or too short in .env (≥ 32 bytes).");

            // Give safe defaults to avoid null warnings / runtime errors
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

            // (Optional) CORS for local dev / Flutter web
            // builder.Services.AddCors(p => p.AddPolicy("AllowAll",
            //     b => b.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

            // ---- Build app ----
            Console.WriteLine("---- BUILDING APP ----");
            var app = builder.Build();
            Console.WriteLine("---- APP BUILT, CONFIGURING PIPELINE ----");

            app.UseSwagger();
            app.UseSwaggerUI();

            // app.UseCors("AllowAll"); // if enabled above

            app.UseAuthentication();
            app.UseAuthorization();

            app.UseMiddleware<GlobalExceptionMiddleware>();
            app.MapControllers();

            // ---- Migrate + seed ----
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var dbContext = services.GetRequiredService<ApplicationDbContext>();

                try
                {
                    await dbContext.Database.MigrateAsync();

                    var seeder = services.GetRequiredService<DataSeeder>();
                    await seeder.SeedRolesAsync();
                    await seeder.SeedAdminAsync();
                    await seeder.SeedMenuCategoriesAsync();
                    var restaurantId = await seeder.SeedRestaurantAsync();
                    await seeder.SeedMenuItemsAsync(itemsPerCategory: 6);
                    await seeder.SeedSampleUsersAsync(targetCount: 20);
                    await seeder.SeedTablesAsync(tableCount: 15, restaurantId);

                    var hasOrders = await dbContext.Orders.AsNoTracking().AnyAsync();
                    var hasReservations = await dbContext.Reservations.AsNoTracking().AnyAsync();
                    var hasReviews = await dbContext.Reviews.AsNoTracking().AnyAsync();

                    if (!hasOrders && !hasReservations && !hasReviews)
                    {
                        await seeder.SeedReservationsAsync(days: 30, count: 80);
                        await seeder.SeedOrdersAndItemsAsync(days: 30, orders: 120);
                        await seeder.SeedReviewsAsync(days: 30, reviews: 60, restaurantId);
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Startup migration/seed failed: " + ex.Message);
                    Console.WriteLine(ex.StackTrace);
                }
            }

            Console.WriteLine("---- STARTING WEB HOST ----");
            await app.RunAsync();
        }
    }
}
