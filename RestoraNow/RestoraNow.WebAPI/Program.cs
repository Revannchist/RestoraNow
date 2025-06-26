using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RestoraNow.Services.Data;
using RestoraNow.Services.Implementations;
using RestoraNow.Services.Interfaces;
using RestoraNow.Services.Interfaces.RestoraNow.Services.Interfaces;
using System.Reflection;

namespace RestoraNow.WebAPI
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            //Services
            builder.Services.AddTransient<IAddressService, AddressService>();
            builder.Services.AddTransient<IFavoriteService, FavoriteService>();
            builder.Services.AddTransient<IMenuCategoryService, MenuCategoryService>();
            builder.Services.AddTransient<IMenuItemService, MenuItemService>();
            builder.Services.AddTransient<IOrderService, OrderService>();
            builder.Services.AddTransient<IOrderItemService, OrderItemService>();
            builder.Services.AddScoped<IPaymentService, PaymentService>();
            builder.Services.AddScoped<IReservationService, ReservationService>();
            builder.Services.AddScoped<IRestaurantService, RestaurantService>();

            //Mapster
            builder.Services.AddMapster();
            RestoraNow.Services.Mappings.MappingConfig.RegisterMappings();

            //TypeAdapterConfig.GlobalSettings.Scan(Assembly.GetExecutingAssembly());

            builder.Services.AddControllers();
            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            //builder.Services.AddAutoMapper(typeof(AutoMapperProfile)); //Auto Mapper 

            builder.Services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseHttpsRedirection();

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
