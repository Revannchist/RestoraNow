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
        : BaseCRUDService<ReservationResponse, ReservationSearchModel, Reservation, ReservationRequest>,
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
    }
}
