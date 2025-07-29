using RestoraNow.Model.Base;
namespace RestoraNow.Services.Interfaces.Base
{
    public interface IService<TModel, in TSearch>
        where TSearch : BaseSearchObject
    {
        Task<PagedResult<TModel>> GetAsync(TSearch search);
        Task<TModel?> GetByIdAsync(int id);
    }
}