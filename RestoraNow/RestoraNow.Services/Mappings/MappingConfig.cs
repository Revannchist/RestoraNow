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


            // Other mappings incoming...
        }


    }
}
