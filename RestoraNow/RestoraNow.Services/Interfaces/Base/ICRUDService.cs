using RestoraNow.Model.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace RestoraNow.Services.Interfaces.Base
{
    public interface ICRUDService<TModel, TSearch, TInsert, TUpdate>
        : IService<TModel, TSearch>
        where TSearch : BaseSearchObject
    {
        Task<TModel> InsertAsync(TInsert request);
        Task<TModel?> UpdateAsync(int id, TUpdate request);
        Task<bool> DeleteAsync(int id);
    }
}