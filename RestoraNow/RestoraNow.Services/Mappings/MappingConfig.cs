using System.Linq;
using Mapster;
using RestoraNow.Model.Responses;
using RestoraNow.Model.Responses.Mobile.User;
using RestoraNow.Model.Responses.Order;
using RestoraNow.Services.Entities;

namespace RestoraNow.Services.Mappings
{
    public class MappingConfig
    {
        public static void RegisterMappings()
        {
            // MenuItem -> MenuItemResponse
            TypeAdapterConfig<MenuItem, MenuItemResponse>.NewConfig()
                .Map(d => d.CategoryName, s => s.Category != null ? s.Category.Name : null)
                .Map(d => d.ImageUrls, s => s.Images != null ? s.Images.Select(img => img.Url).ToList() : new());

            // Review -> ReviewResponse
            TypeAdapterConfig<Review, ReviewResponse>.NewConfig()
                .Map(d => d.UserName, s => s.User != null ? (s.User.FirstName + " " + s.User.LastName).Trim() : "Unknown User")
                .Map(d => d.UserEmail, s => s.User != null ? s.User.Email : null)
                .IgnoreNullValues(true);

            // Table -> TableResponse
            TypeAdapterConfig<Table, TableResponse>.NewConfig()
                .Map(d => d.RestaurantName, s => s.Restaurant != null ? s.Restaurant.Name : null);

            // UserImage -> UserImageResponse
            TypeAdapterConfig<UserImage, UserImageResponse>.NewConfig();

            // Reservation -> ReservationResponse
            TypeAdapterConfig<Reservation, ReservationResponse>.NewConfig()
                .Map(d => d.UserName, s => s.User != null ? (s.User.FirstName + " " + s.User.LastName).Trim() : "Unknown User")
                .Map(d => d.TableNumber, s => s.Table != null ? s.Table.TableNumber.ToString() : "Unknown Table")
                .Map(d => d.ReservationTime, s => s.ReservationTime.ToString(@"hh\:mm"));

            // Favorite -> FavoriteResponse
            TypeAdapterConfig<Favorite, FavoriteResponse>.NewConfig()
                .Map(d => d.MenuItemName, s => s.MenuItem != null ? s.MenuItem.Name : null);

            // User -> UserResponse
            TypeAdapterConfig<User, UserResponse>.NewConfig()
                .Map(d => d.Username, s => s.UserName)
                .Map(d => d.ImageUrl, s => s.Image != null ? s.Image.Url : null)
                .Map(d => d.Roles, s => new List<string>()); // filled in service

            // ---------- Orders ----------
            // OrderItem -> OrderItemResponse
            TypeAdapterConfig<OrderItem, OrderItemResponse>.NewConfig()
                .Map(d => d.TotalPrice, s => s.UnitPrice * s.Quantity)
                .Map(d => d.MenuItemName, s => s.MenuItem != null ? s.MenuItem.Name : null);

            // Order -> OrderResponse
            TypeAdapterConfig<Order, OrderResponse>.NewConfig()
                .Map(d => d.UserName,
                     s => s.User != null
                        ? (s.User.FirstName + " " + s.User.LastName).Trim()
                        : null)
                .Map(d => d.Status, s => s.Status.ToString()) // enum -> string
                .Map(d => d.Total, s => s.OrderItems != null
                                            ? s.OrderItems.Sum(i => i.UnitPrice * i.Quantity)
                                            : 0m);

            // ---------- Mobile ----------
            // User -> MeResponse
            TypeAdapterConfig<User, MeResponse>.NewConfig()
                .Map(d => d.ImageUrl, s => s.Image != null ? s.Image.Url : null)
                .Map(d => d.Username, s => s.UserName);
        }
    }
}
