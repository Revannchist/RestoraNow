﻿using RestoraNow.Model.Requests.User;
using RestoraNow.Model.Responses;
using RestoraNow.Model.SearchModels;
using RestoraNow.Services.Interfaces.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Interfaces
{
    public interface IUserService : ICRUDService<UserResponse, UserSearchModel, UserCreateRequest, UserUpdateRequest>
    {
    }
}
