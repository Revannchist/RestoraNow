using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Mapster;
using RestoraNow.Model.Responses;
using RestoraNow.Services.Entities;

namespace RestoraNow.Services.Mappings
{
    public class MappingConfig
    {
        public static void RegisterMappings()
        {

            // MenuItem -> MenuItemResponse
            TypeAdapterConfig<MenuItem, MenuItemResponse>.NewConfig()
                .Map(dest => dest.CategoryName, src => src.Category.Name)
                .Map(dest => dest.ImageUrls, src => src.Images.Select(img => img.Url).ToList());


            TypeAdapterConfig<Review, ReviewResponse>.NewConfig()
                .Map(dest => dest.RestaurantName, src => src.Restaurant.Name);


            TypeAdapterConfig<Table, TableResponse>.NewConfig()
                .Map(dest => dest.RestaurantName, src => src.Restaurant.Name);




            TypeAdapterConfig<UserImage, UserImageResponse>.NewConfig();



            //Reservation
            TypeAdapterConfig<Reservation, ReservationResponse>.NewConfig()
                .Map<string,string>(dest => dest.UserName, src => src.User != null ? src.User.FirstName + " " + src.User.LastName : "Unknown User")
                .Map<string, string>(dest => dest.TableNumber, src => src.Table != null ? src.Table.TableNumber.ToString() : "Unknown Table")
                .Map(dest => dest.ReservationTime, src => src.ReservationTime.ToString(@"hh\:mm")); // Format TimeSpan as HH:mm



            //Favorites
            TypeAdapterConfig<Favorite, FavoriteResponse>.NewConfig()
                .Map(dest => dest.MenuItemName, src => src.MenuItem.Name);


            // User -> UserResponse
            TypeAdapterConfig<User, UserResponse>.NewConfig()
                .Map(dest => dest.Username, src => src.UserName)
                .Map(dest => dest.ImageUrls, src => src.Images.Select(img => img.Url).ToList())
                .Map(dest => dest.Roles, src => new List<string>()); // Initialize empty, will be populated in service



            // Other mappings incoming...
        }


    }
}
