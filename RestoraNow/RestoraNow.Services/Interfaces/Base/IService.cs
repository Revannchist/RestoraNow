using RestoraNow.Model.Base;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
namespace RestoraNow.Services.Interfaces.Base
{
    public interface IService<TModel, in TSearch>
        where TSearch : BaseSearchObject
    {
        Task<PagedResult<TModel>> GetAsync(TSearch search);
        Task<TModel?> GetByIdAsync(int id);
    }
}