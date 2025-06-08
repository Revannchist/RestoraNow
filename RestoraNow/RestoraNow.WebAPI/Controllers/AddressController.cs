namespace RestoraNow.WebAPI.Controllers
{
    using Microsoft.AspNetCore.Mvc;
    using RestoraNow.Model.Requests;
    using RestoraNow.Model.SearchModels;
    using RestoraNow.Services.Interfaces;

    [ApiController]
    [Route("api/[controller]")]
    public class AddressController : ControllerBase
    {
        private readonly IAddressService _addressService;

        public AddressController(IAddressService addressService)
        {
            _addressService = addressService;
        }

        // GET: api/address
        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] AddressSearchModel search)
        {
            var addresses = await _addressService.GetAsync(search);
            return Ok(addresses);
        }

        // GET: api/address/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var address = await _addressService.GetByIdAsync(id);

            if (address == null)
                return NotFound();

            return Ok(address);
        }

        // POST: api/address
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AddressRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var createdAddress = await _addressService.InsertAsync(request);

            // Return 201 Created with location header
            return CreatedAtAction(nameof(GetById), new { id = createdAddress.Id }, createdAddress);
        }

        // PUT: api/address/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] AddressRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var updatedAddress = await _addressService.UpdateAsync(id, request);

            if (updatedAddress == null)
                return NotFound();

            return Ok(updatedAddress);
        }

        // DELETE: api/address/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var deleted = await _addressService.DeleteAsync(id);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }

}
