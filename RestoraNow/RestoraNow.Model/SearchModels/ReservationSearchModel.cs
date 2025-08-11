using RestoraNow.Model.Base;
using RestoraNow.Model.Enums;
using System;

namespace RestoraNow.Model.SearchModels
{
    public class ReservationSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? TableId { get; set; }
        public ReservationStatus? Status { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}