using System.ComponentModel.DataAnnotations;
using RestoraNow.Model.Enums;

namespace RestoraNow.Services.Entities
{
    public class Order
    {
        public int Id { get; set; }

        [Required]
        public int UserId { get; set; }
        public User User { get; set; }

        public int? ReservationId { get; set; }
        public Reservation Reservation { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        public OrderStatus Status { get; set; } = OrderStatus.Pending;

        public ICollection<OrderItem> OrderItems { get; set; }

        public Payment Payment { get; set; }
    }
}