using EasyNetQ;
using RestoraNow.Model.Messages;

namespace RestoraNow.Subscriber
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello, World!");

            var bus = RabbitHutch.CreateBus("host=localhost");

            //await bus.PubSub.PublishAsync(message);
        }
    }
}
