using RestoraNow.Model.Base;
using RestoraNow.Model.Enums;
using System;

namespace RestoraNow.Model.SearchModels
{
    public class ReservationSearchModel : BaseSearchObject
    {
        public int? UserId { get; set; }

        //public string? UserName { get; set; } 
        //Searching only by Id and the frontend searches by username and sends the ID as a filter parameter

        public int? TableId { get; set; }
        public ReservationStatus? Status { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }

    }
}