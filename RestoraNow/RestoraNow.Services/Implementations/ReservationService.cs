using Microsoft.EntityFrameworkCore;
using MapsterMapper;
using RestoraNow.Services.BaseServices;
using RestoraNow.Services.Data;
using RestoraNow.Services.Entities;
using RestoraNow.Services.Interfaces;
using RestoraNow.Model.SearchModels;
using RestoraNow.Model.Requests;
using RestoraNow.Model.Responses;

namespace RestoraNow.Services.Implementations
{
    public class ReservationService
        : BaseCRUDService<ReservationResponse, ReservationSearchModel, Reservation, ReservationRequest, ReservationRequest>,
          IReservationService
    {
        public ReservationService(ApplicationDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchModel search)
        {
            if (search.UserId.HasValue)
                query = query.Where(r => r.UserId == search.UserId.Value);

            if (search.TableId.HasValue)
                query = query.Where(r => r.TableId == search.TableId.Value);

            if (search.Status.HasValue)
                query = query.Where(r => r.Status == search.Status.Value);

            if (search.FromDate.HasValue)
                query = query.Where(r => r.ReservationDate >= search.FromDate.Value);

            if (search.ToDate.HasValue)
                query = query.Where(r => r.ReservationDate <= search.ToDate.Value);

            return query;
        }

        protected override IQueryable<Reservation> AddInclude(IQueryable<Reservation> query)
        {
            return query
                .Include(r => r.User)
                .Include(r => r.Table);

        }

        public override async Task<ReservationResponse> InsertAsync(ReservationRequest request)
        {
            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            var tableExists = await _context.Tables.AnyAsync(t => t.Id == request.TableId);
            if (!tableExists)
                throw new KeyNotFoundException($"Table with ID {request.TableId} not found.");

            var entity = _mapper.Map<Reservation>(request);
            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();

            // Return enriched response
            return (await GetByIdAsync(entity.Id))!;
        }

        public override async Task<ReservationResponse?> UpdateAsync(int id, ReservationRequest request)
        {
            var reservation = await _context.Reservations.FindAsync(id);
            if (reservation == null)
                throw new KeyNotFoundException($"Reservation with ID {id} not found.");

            var userExists = await _context.Users.AnyAsync(u => u.Id == request.UserId);
            if (!userExists)
                throw new KeyNotFoundException($"User with ID {request.UserId} not found.");

            var tableExists = await _context.Tables.AnyAsync(t => t.Id == request.TableId);
            if (!tableExists)
                throw new KeyNotFoundException($"Table with ID {request.TableId} not found.");

            _mapper.Map(request, reservation);
            await _context.SaveChangesAsync();

            // Return enriched response with User/Table included
            return await GetByIdAsync(reservation.Id);
        }

        public override async Task<ReservationResponse?> GetByIdAsync(int id)
        {
            var reservation = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (reservation == null)
                throw new KeyNotFoundException($"Reservation with ID {id} not found.");

            return _mapper.Map<ReservationResponse>(reservation);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var reservation = await _context.Reservations.FindAsync(id);
            if (reservation == null)
                throw new KeyNotFoundException($"Reservation with ID {id} not found.");

            _context.Reservations.Remove(reservation);
            await _context.SaveChangesAsync();
            return true;
        }

    }
}
