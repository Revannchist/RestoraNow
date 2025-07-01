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
                .Map(dest => dest.UserName, src => src.User.Username)
                .Map(dest => dest.RestaurantName, src => src.Restaurant.Name);


            TypeAdapterConfig<Role, RoleResponse>.NewConfig();


            TypeAdapterConfig<Table, TableResponse>.NewConfig()
                .Map(dest => dest.RestaurantName, src => src.Restaurant.Name);

            TypeAdapterConfig<UserImage, UserImageResponse>.NewConfig()
                .Map(dest => dest.Username, src => src.User.Username);

            TypeAdapterConfig<UserRole, UserRoleResponse>.NewConfig()
                .Map(dest => dest.Username, src => src.User.Username)
                .Map(dest => dest.RoleName, src => src.Role.Name);


            TypeAdapterConfig<Reservation, ReservationResponse>.NewConfig()
                .Map(dest => dest.UserName, src => src.User.FirstName + " " + src.User.LastName)
                .Map(dest => dest.TableNumber, src => src.Table.TableNumber.ToString())
                .Map(dest => dest.ReservationTime, src => src.ReservationTime.ToString(@"hh\:mm"));  // Format TimeSpan as HH:mm





            // Other mappings incoming...
        }


    }
}
