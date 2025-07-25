using Microsoft.AspNetCore.Mvc;
using RestoraNow.Model.Base;
using RestoraNow.Services.Interfaces.Base;

namespace RestoraNow.WebAPI.Controllers.Base
{
    public class BaseCRUDController<TModel, TSearch, TInsert, TUpdate> : BaseController<TModel, TSearch>
        where TSearch : BaseSearchObject, new()
    {
        private readonly ICRUDService<TModel, TSearch, TInsert, TUpdate> _crudService;

        public BaseCRUDController(ICRUDService<TModel, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _crudService = service;
        }

        [HttpPost]
        public async Task<ActionResult<TModel>> Create([FromBody] TInsert request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var created = await _crudService.InsertAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = GetId(created) }, created);
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<TModel>> Update(int id, [FromBody] TUpdate request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var updated = await _crudService.UpdateAsync(id, request);
            if (updated == null)
                return NotFound();

            return Ok(updated);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _crudService.DeleteAsync(id);
            return deleted ? NoContent() : NotFound();
        }

        protected virtual int GetId(TModel model)
        {
            var prop = typeof(TModel).GetProperty("Id");
            return prop != null ? (int)(prop.GetValue(model) ?? 0) : 0;
        }
    }

}